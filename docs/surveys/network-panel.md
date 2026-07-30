# Network panels, and where the connection details come from

Read while rewriting `panels/Network.qml`, which showed a wifi scan list and
nothing else on a desktop whose only link is gigabit ethernet. Six shells read,
plus the Quickshell 0.3 type metadata itself. Everything below is quoted from a
file on this machine.

## What `Quickshell.Networking` actually exposes

Checked against
`/nix/store/…-quickshell-0.3.0/lib/qt-6/qml/Quickshell/Networking/quickshell-network.qmltypes`,
then confirmed by logging the live objects on this machine.

| Type | Gives you |
| --- | --- |
| `Networking` | `devices`, `backend`, `wifiEnabled` (rw), `wifiHardwareEnabled`, `connectivity`, `canCheckConnectivity`, `connectivityCheckEnabled`, `checkConnectivity()` |
| `NetworkDevice` | `type` (`None`/`Wifi`/`Wired`), `name`, `networks`, `address`, `connected`, `state`, `nmManaged`, `autoconnect`, `disconnect()` |
| `WiredDevice` | `network`, `linkSpeed`, `hasLink` |
| `WifiDevice` | `scannerEnabled` (rw), `mode` |
| `WifiNetwork` | `signalStrength` (0–1 double), `security` |
| `Network` | `name`, `connected`, `known`, `state`, `stateChanging`, `connect()`, `disconnect()`, `forget()` |

Three traps, all measured rather than assumed:

* **`NetworkDevice.address` is the MAC, not the IP.** Logged on this machine:
  `eno1 addr= E8:9C:25:46:5C:84`. There is no IP address anywhere in the module.
* **The device model holds only Wifi and Wired devices.** The full list here is
  `eno1`, `wlp11s0`, `vmnet1`, `vmnet8`. `CloudflareWARP` — the tunnel that is
  actually up — is absent, as are the bridges and the veths. A VPN cannot be
  detected through this API at all.
* **`vmnet1` and `vmnet8` are reported as `DeviceType.Wired`** with
  `nmManaged=false`, `connected=false`, `hasLink=true`, `linkSpeed=0`. Anything
  that picks "the wired device" out of the model without filtering picks one of
  those about a third of the time.

An earlier version of this panel bound to `Networking.accessPoints` with
`.ssid` / `.strength` / `.active`. None of those four names exist. The list was
permanently empty and nobody noticed for a day. Check the qmltypes.

## The six shells

### noctalia (`noct4/`) — the only one that does the whole job

One process, `------`-delimited, for device details and the scan table together
— `Services/Networking/NetworkService.qml:499`:

```
["sh", "-c", "nmcli -t -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,IP6.GATEWAY,IP6.DNS,CAPABILITIES.SPEED device show; echo \"------\"; nmcli -t -f IN-USE,SIGNAL,RATE,CHAN,FREQ,BANDWIDTH device wifi list"]
```

Parsed at `:357-422` into interface, IPv4, gateway, DNS, IPv6, MAC and speed;
rendered as a six-item grid with click-to-copy at `Modules/Panels/Network/
NetworkPanel.qml:661` (interface), `:709` (MAC), `:755` (speed), `:785` (IP),
`:836` (DNS), `:887` (gateway). Locale-pinned with
`environment: ({LANG:"C.UTF-8", LC_ALL:"C.UTF-8"})` at `:500`, which matters:
nmcli's field labels are translated.

Ethernet is a peer view, not a subsection — `NetworkPanel.qml:26` keeps a
persisted `panelViewMode: "wifi" | "ethernet"` and the toggle at `:170` hides
itself on a single-NIC machine. Details are fetched on panel open behind a 10s
TTL (`NetworkService.qml:61`, `:275`, `:287`), never polled. Nothing is
`scannerEnabled`; scans are driven manually with `--rescan yes`.

VPN detection at `Services/Networking/VPNService.qml:162`:

```js
if (type !== "vpn" && type !== "wireguard") { continue; }
```

**This misses CloudflareWARP.** `nmcli -t con show --active` on this machine
returns `CloudflareWARP:55ba27c5-…:tun:CloudflareWARP` — NetworkManager types it
`tun`, not `vpn` and not `wireguard`. The single best idea in that file is
unrelated: connection names may contain colons, so it parses with
`lastIndexOf(":")` walked backwards (`:151-171`) rather than `split(":")`.

### myamusashi `vast-shell` — the only one with real link speed

`Qml/Services/SystemUsage.qml:308-335` reads
`/sys/class/net/$if/speed` for wired and `iw dev $if link | grep 'tx bitrate:'`
for wireless. VPN detection at `:264` is a hardcoded interface allowlist —
`/^(wg0|CloudflareWARP):/` — which catches this machine by luck and nothing
else; their own README still lists WARP detection as an open TODO.

The one thing to copy is the scanner gate,
`Qml/Modules/Drawers/QuickSettings/Settings/WifiList.qml:141-147`: the scanner
follows whether the list is open. No IP, gateway or DNS anywhere.

### Brainitech `Brain_Shell` — best VPN tab, no connection details

Finds the outbound interface from the routing table rather than from
NetworkManager, `src/services/system/NetService.qml:29-31`:

```sh
ip route get 1.1.1.1 2>/dev/null | awk '/dev/{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'
```

and re-detects it every tick, with the comment at `:24-27` explaining why:
running once at startup missed VPN, cable and network changes. VPN is
`nmcli … con show | awk -F: '$2=="wireguard"'` (`src/popups/VPNTab.qml:47-49`) —
again blind to a `tun`. No IP, gateway, DNS, MAC or speed.

Rail glyphs, `src/modules/Right/Network.qml:21-30`: ethernet ``, wifi off
`󰤭`, and the strength ramp `󰤨` `󰤥` `󰤢` `󰤟`. VPN shield `󰦝` at `:113`.

### josecriane — the only external-IP fetch in the corpus

`services/OpenVPN.qml:133`:

```qml
command: ["curl", "-s", "--max-time", "3", "https://ifconfig.me"]
```

Fired once on the connected edge (`:59-62`), never polled, cleared to `""` on
every disconnect path, and rendered with an explicit pending state at
`modules/popups/VPN.qml:69-70` (`value: OpenVPN.ipAddress || "Fetching..."`).
The `--max-time` cap is the part that matters — without it a dead tunnel hangs
the process. VPN state comes from `systemctl status`, not NetworkManager
(`:45`, `:54`).

### corecathx `whisker` — purest `Quickshell.Networking`, and what that costs

`services/Network.qml:30-35` is the idiomatic device pick, worth copying:

```qml
readonly property WifiDevice wifiDevice: {
    wifiDevices.find(d => d.connected) ?? wifiDevices[0] ?? null
}
```

It shows no IP, gateway, DNS, MAC or speed — because the module has none of
them. Its `scannerEnabled` is a user-facing "Scanning" switch
(`modules/bar/NetworkTray.qml:96-102`), which leaves the radio sweeping with
the panel shut unless somebody remembers.

### Gakuseei `Ricelin` — the cleanest scanner gate

`configs/quickshell/pill/WifiSurface.qml:275-280`:

```qml
Binding {
    target: root.wifiDev
    property: "scannerEnabled"
    value: root.active && root.wifiOn
    when: root.wifiDev !== null
}
```

Copied here, with one addition measured on this machine: the default
`restoreMode` puts the *old* value back when the Binding is destroyed, so a
close hook that sets `false` is immediately undone by the dying Binding and the
radio keeps sweeping. `restoreMode: Binding.RestoreNone` is required.

## What this shell does instead

`Net.qml` splits it the way the survey suggests and nobody quite does: topology
from `Quickshell.Networking` (wired vs wireless, link speed, signal), layer 3
from `ip`. One fork emits three lines — `ip -j -d addr`, `ip -j route`, and the
nameservers out of `/etc/resolv.conf`.

Two departures from every shell above:

* **`ip monitor link addr route` instead of a timer.** Nobody in the corpus
  uses it; noctalia comes closest with `nmcli -t monitor`
  (`NetworkService.qml:1130`). It is a netlink listener, so a cable pulled or a
  tunnel coming up is read within a 250ms debounce and nothing runs between
  events. Measured: creating and deleting a throwaway interface produced three
  re-reads in eight seconds, with the one-minute backstop timer not due.
* **A tunnel is matched by link kind, not by name or by NetworkManager type.**
  `ip -j -d addr` reports `linkinfo.info_kind` — `tun` for CloudflareWARP and
  for OpenVPN, `wireguard` for WireGuard — and one regex catches all of them.
  Name matching (`tun0`, or vast-shell's `wg0|CloudflareWARP`) catches one
  configuration each; NetworkManager's connection type misses WARP entirely.

Fields shown: interface, LAN address, gateway, DNS, public address, plus the
tunnel and its address on a row of its own. Rejected: MAC (never changes, never
needed at a glance), IPv6 (three times the width for the same fact, and nothing
here routes over it), netmask spelled out separately, and throughput — the
system panel already graphs it.

The public address is the only field that costs a round trip, so it is fetched
when the panel appears and cleared whenever the route or the tunnel moves,
which is exactly when it can have changed. Never polled.

## Screenshots

`network-panel-ethernet.png` — the panel on the desktop, 348px tall on a 1080px
screen. `network-panel-wifi.png` — the same panel with the wifi section
deliberately opened, which is the only way to make it full height.
