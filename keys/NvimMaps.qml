import QtQuick
import Quickshell
import Quickshell.Io

// Neovim's keymaps, from a dump his config writes on rebuild, sorted into the
// sections the sheet draws.
//
// They cannot be read live from here: the maps only exist inside a Neovim that
// has finished starting, and lazy.nvim does not register a plugin's `desc`
// until `VimEnter` has fired. So a headless run does it once — driven by an
// activation script in his dotfiles, writing the JSON below — and this reads
// the file. If the file is not there, the page says so; a keymap list that is
// quietly incomplete is worse than no list at all.
QtObject {
    id: root

    property bool have: false
    property var dump: ({})
    property bool builtins: false

    readonly property var maps: root.dump.maps ?? []
    readonly property int count: root.dump.count ?? 0

    readonly property string file: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/erikshell/nvim-keymaps.json"

    property FileView reader: FileView {
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: {
            root.have = false;
            root.dump = ({});
        }
        onLoaded: {
            try {
                root.dump = JSON.parse(text());
                root.have = true;
            } catch (e) {
                root.have = false;
            }
        }
    }

    // which-key writes its group headings with the leader spelled `<Space>`
    // and the maps themselves with `<leader>`. One of them has to give.
    //
    // A space that is left *in* a key is worse than either: `<leader><space>`
    // arrives as the four characters `<leader>` followed by a space and draws
    // as plain `<leader>`, so the row for "[ ] Find existing buffers" claimed
    // the leader key on its own did it. Every remaining literal space is spelt.
    function norm(lhs) {
        return (lhs ?? "").replace("<Space>", "<leader>").replace(/ /g, "<Space>");
    }

    // What the eight which-key groups in the dump can actually carry is two
    // sections — `<leader>s` and `<leader>t` — and 92% of his maps fall through
    // both into one bucket called "Everything else". `:help quickref` is the
    // answer: a section is a task, and the task is legible from the key itself,
    // because every one of these families was designed as a prefix. First rule
    // wins, and the order below is both the matching order and the order the
    // sections are drawn in.
    //
    // quickref orders its 41 sections move-first, because it is documenting the
    // whole editor and moving is what you do most. This sheet is documenting
    // *his additions*, and the thing he cannot remember is the leader key he
    // chose himself last month — so finding, diagnostics and the language
    // server lead, and the twenty-six unimpaired `[`/`]` pairs go last for the
    // same reason quickref puts folding and the GUI at the bottom: a long,
    // uniform, mechanically-generated block is the one thing on a sheet that
    // nobody scans and everybody has to scroll past.
    readonly property var rules: [[/^<leader>(s|\/|<Space>)|^[*#&]$/, "Finding"], [/^[[\]][dD]$|^<leader>[deq]$|^<C-W>(<C-D>|d)$/, "Diagnostics"], [/^(gr|gO$)/, "Language server"], [/^(<C-S>|<leader>f|<leader>tr|p|Y|gx|<Esc>|<Esc><Esc>|[[\]]<Space>)$/, "Editing & files"], [/^([jk]|g?%|[[\]]%|g[[\]])$/, "Moving"], [/^(<C-[AUW]>|<C-[äö]>|<S-Tab>|<Tab>|<M-CR>)$/, "Completion"], [/^<C-[HJKL]>$/, "Windows"], [/^g[bc]/, "Commenting"], [/^([sS]|ys|yS|cs|cS|ds|gS|<C-G>[sS])/, "Surrounding"], [/^[ai]([ln]|%)?$/, "Text objects"], [/^(<F[0-9]+>|<leader>[bB])$/, "Debugging"], [/^[[\]]/, "Previous / next"]]

    readonly property string other: "Everything else"

    function section(lhs) {
        const hit = root.rules.find(r => r[0].test(lhs));
        return hit ? hit[1] : root.other;
    }

    // The modes in the order a vim user says them, and only when there is
    // something to say: a mapping that is normal-mode only is most of the sheet
    // and does not need a badge to prove it.
    function tidyModes(m) {
        if (m === "n")
            return "";
        return "nvxsoitc".split("").filter(c => m.indexOf(c) >= 0).join("");
    }

    // `:cnext`, `vim.lsp.buf.code_action()` and `:help Y-default` are not
    // labels anybody wrote for a cheatsheet — they are what the map does,
    // standing in. They are marked as standing in, so a described map still
    // reads as the better-documented thing it is.
    function derived(d) {
        return d === "" || d.charAt(0) === ":" || d.startsWith("vim.");
    }

    // A trailing "(insert mode)" or "(visual)" is the modes badge written out
    // again three words later, and on a three-column sheet it is the fourteen
    // characters that push the rest of the sentence off the end of the row.
    function label(d) {
        return d.replace(/^vim\.lsp\.buf\./, "").replace(/^vim\./, "").replace(/\(\)$/, "").replace(/ \((insert|normal|visual|select)( mode)?\)$/, "");
    }

    // `[q` and `]q` are one idea and belong next to each other, so the bracket
    // moves to the back of the sort key and the pair closes up. Alphabetical on
    // the raw key put six `[`s in one place and their six `]`s forty rows away.
    function sortKey(k) {
        const c = k.charAt(0);
        return (c === "[" || c === "]") ? k.slice(1) + c : k;
    }

    // One row per key and description, not one per mode: the same `[%` is bound
    // in visual, operator-pending and select, and three near-identical lines say
    // nothing the modes badge does not already say in one.
    //
    // `nvim_get_keymap` also hands back the *same* key twice when only some of
    // its modes carry the description — `%` is "Matching (){}[]" in normal but
    // blank in visual — and a blank row under a filled one looks like a second
    // mapping nobody bothered to name. So a key's descriptionless rows are
    // folded into its first described one, which is what they always were.
    function unblank(rows) {
        const named = {};
        for (const r of rows)
            if (r.desc !== "" && named[r.key] === undefined)
                named[r.key] = r;
        return rows.filter(r => {
            const host = r.desc === "" ? named[r.key] : undefined;
            if (host === undefined)
                return true;
            for (const c of r.modes)
                if (host.modes.indexOf(c) < 0)
                    host.modes += c;
            return false;
        });
    }

    readonly property var sections: {
        const by = {}, seen = {};
        for (const m of root.maps) {
            if (m.group === true || (m.builtin === true) !== root.builtins)
                continue;
            const key = root.norm(m.lhs), desc = root.label(m.desc ?? ""), id = key + "\t" + desc;
            if (seen[id] !== undefined) {
                if (seen[id].modes.indexOf(m.mode) < 0)
                    seen[id].modes += m.mode;
                continue;
            }
            const row = {
                key: key,
                desc: desc,
                derived: root.derived(desc),
                modes: m.mode,
                sort: root.sortKey(key),
                hay: (key + "\t" + desc).toLowerCase(),
                fold: ""
            };
            seen[id] = row;
            const name = root.section(key);
            if (by[name] === undefined)
                by[name] = [];
            by[name].push(row);
        }
        const names = root.rules.map(r => r[1]).concat([root.other]);
        return names.filter(n => by[n] !== undefined).map(n => ({
                    name: n,
                    items: root.unblank(by[n]).map(r => {
                        r.modes = root.tidyModes(r.modes);
                        r.fold = r.hay.replace(/[\[\]<>+_\s-]/g, "");
                        return r;
                    }).sort((a, b) => a.sort.localeCompare(b.sort))
                }));
    }
}
