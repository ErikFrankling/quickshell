pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

// Which way this machine reaches the internet, worked out once here so the rail
// glyph and the panel agree.
//
// Quickshell.Networking knows the *devices* — which are wireless, which are
// wired, what a radio can see, how fast a cable negotiated — and nothing about
// layer 3. Two traps in it, both measured rather than assumed:
// `NetworkDevice.address` is the MAC and not the IP, and the model holds only
// Wifi and Wired devices, so a tunnel is not in it at all. On this machine
// CloudflareWARP is simply absent from `Networking.devices`.
//
// So addresses, the default route and the tunnel come from `ip`, and the
// topology — wired or wireless, link speed, signal — comes from Quickshell.
Singleton {
    id: root

    // The interface carrying the default route: the one you are actually on,
    // rather than whichever card this machine happens to have.
    property string link: ""
    property string gateway: ""
    property string lanIp: ""
    property string dns: ""

    // Every tunnel that is up, each `{ name, ip }`, named by its interface.
    // That is the only name a tunnel reliably has: NetworkManager types
    // CloudflareWARP as `tun` and not as `vpn`, so filtering its connection
    // list by type — which is what the other shells read for this do — misses
    // it entirely.
    //
    // A list and not one tunnel, because this machine runs two: OpenVPN's
    // `tun0` and Cloudflare's `CloudflareWARP`, both up at once. Taking the
    // first match showed whichever came up first, and the unit ordering in the
    // dotfiles starts WARP before OpenVPN — so the one he set up by hand was
    // the one that never appeared.
    property var tunnels: []

    readonly property bool online: root.link !== ""
    readonly property bool vpn: root.tunnels.length > 0

    // Quickshell's view of that same interface — and, when the default route
    // leaves by a tunnel rather than by a card, whichever card is actually up
    // underneath it. Without that second clause a full tunnel is the one
    // moment the rail cannot tell wifi from ethernet, which is the moment it
    // most obviously should. `connected` is also what keeps `vmnet1` and
    // `vmnet8` out: they report as Wired but never as connected.
    readonly property var device:
        Networking.devices.values.find(d => d.name === root.link)
        ?? Networking.devices.values.find(d => d.connected) ?? null
    readonly property bool wired: root.device?.type === DeviceType.Wired
    readonly property bool wifi: root.device?.type === DeviceType.Wifi

    // A radio in the machine, which is not the same question as a radio
    // switched on: `Networking.wifiEnabled` is the switch, this is the card.
    // Nothing wifi renders anywhere unless this is true.
    readonly property var wifiDevice:
        Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool hasWifi: root.wifiDevice !== null
    readonly property var wifiNetwork:
        root.wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property real strength: root.wifiNetwork?.signalStrength ?? 0

    // Ethernet, wifi at three strengths, a struck-through radio when there is
    // no way out at all, and a globe for the machine that is online through
    // something NetworkManager does not have a card for. The tunnel is not in
    // here: it is drawn as a mark under this glyph, so that the rail can say
    // which link *and* whether it is tunnelled in one slot.
    readonly property string glyph:
          !root.online ? "󰤮"
        : root.wired ? "󰈀"
        : root.wifi ? (root.strength > 0.66 ? "󰤨" : root.strength > 0.33 ? "󰤥" : "󰤟")
        : "󰖟"

    // How fast the link is, in its own terms: a cable negotiates a speed and
    // reports it, a radio does not, so it reports what it can hear.
    readonly property string rate:
          root.wired ? (root.device.linkSpeed > 0 ? root.device.linkSpeed + " Mbit/s" : "")
        : root.wifi ? Math.round(root.strength * 100) + "%" : ""

    // --- the kernel's half ------------------------------------------------

    // Addresses, the default route and the resolver, in one fork, one line each.
    Process {
        id: probe
        command: ["sh", "-c", "ip -j -d addr; ip -j route; "
            + "awk '/^nameserver/ { printf \"%s \", $2 }' /etc/resolv.conf"]
        stdout: StdioCollector { onStreamFinished: root.apply(text) }
    }

    function apply(out) {
        const l = out.split("\n");
        let addrs = [], routes = [];
        try {
            addrs = JSON.parse(l[0]);
            routes = JSON.parse(l[1]);
        } catch (e) {
            return;
        }
        root.dns = (l[2] ?? "").trim().split(" ").filter(s => s).join(", ");

        // The default route names the interface you leave by; its prefsrc is
        // the address you leave from.
        const def = routes.find(r => r.dst === "default") ?? null;
        root.link = def?.dev ?? "";
        root.gateway = def?.gateway ?? "";
        root.lanIp = root.addressOf(addrs.find(a => a.ifname === root.link));

        // A tunnel is a link with no hardware under it. Matching on the kind
        // rather than on a name catches WireGuard, OpenVPN's tun0 and
        // Cloudflare's WARP with one expression; matching on `tun0`, which the
        // rail did, catches exactly one of the three.
        //
        // The operstate test is what separates a tunnel that is carrying
        // something from a persistent `tun` device nobody is attached to: the
        // kernel holds a tun's carrier off until a process opens it, so an
        // abandoned one reads DOWN and a live one reads UNKNOWN. Measured both
        // ways — see docs/surveys/network-glyph.md.
        const tuns = addrs.filter(a => /^(tun|wireguard|ppp|vti|xfrm|ipip|gre)/
            .test(a.linkinfo?.info_kind ?? "") && a.operstate !== "DOWN");
        const next = tuns.map(a => ({
            name: a.ifname,
            ip: root.addressOf(a).split("/")[0]
        }));

        // Assigned only when the set actually moves. `ip` is re-read on every
        // netlink event and once a minute, and a fresh array every time would
        // fire tunnelsChanged every time — which throws the public address
        // away and buys it again from a stranger.
        if (JSON.stringify(next) !== JSON.stringify(root.tunnels))
            root.tunnels = next;
    }

    // The first global IPv4 on an interface, with its prefix. IPv6 is left out:
    // three times the width for the same fact, and nothing here routes over it.
    function addressOf(a) {
        const i = a?.addr_info.find(x => x.family === "inet" && x.scope === "global");
        return i ? i.local + "/" + i.prefixlen : "";
    }

    // Nothing above is polled. `ip monitor` is a netlink listener that prints a
    // line whenever a link, an address or a route changes, so a cable pulled or
    // a tunnel coming up is read within the debounce and nothing runs between
    // events. The minute timer is the backstop, and the first read.
    Process {
        running: true
        command: ["ip", "monitor", "link", "addr", "route"]
        stdout: SplitParser { onRead: settle.restart() }
    }
    Timer { id: settle; interval: 250; onTriggered: probe.running = true }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    // --- the one answer that has to be asked for --------------------------

    // The public address is the only fact the machine cannot work out about
    // itself, and the one that says whether the tunnel is carrying anything.
    // It costs a round trip to a stranger, so it is never polled: the panel
    // asks when it opens, and it is cleared here the moment the route or the
    // tunnel moves, which is exactly when the answer can have changed.
    property string publicIp: ""
    readonly property bool publicIpBusy: publicIpProc.running

    function refreshPublicIp() {
        publicIpProc.running = true;
    }

    onLinkChanged: root.publicIp = ""
    onTunnelsChanged: root.publicIp = ""

    Process {
        id: publicIpProc
        command: ["curl", "-sf", "--max-time", "4", "https://ifconfig.me/ip"]
        stdout: StdioCollector { onStreamFinished: root.publicIp = text.trim() }
    }
}
