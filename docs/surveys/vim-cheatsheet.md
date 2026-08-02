# How vim cheatsheets are laid out

Prior art read before rewriting `keys/Nvim.qml`, which rendered 402 keymaps as
one alphabetical list under a heading that said `Everything else 132`.

The question was not "how do I draw a list" — the page already drew one. It was
**how do people who do this for a living decide what a section is, how wide a
column is, and what to leave out.** Ten sources, in three families: vim's own
documentation, the printable reference cards, and the live discovery UIs.

## The finding, in one line

**Vim ships two documents about its own keys and they disagree, and the one that
disagrees with the page as it was is vim's own cheat sheet.**

| | `:help index` | `:help quickref` |
|---|---|---|
| Groups by | **mode** | **task** |
| Sections | 6 top level, 6 sub-sections under Normal | **41** |
| Biggest section | 553 (Ex commands), undifferentiated | **32** |
| Median section | — | **≈13–14** |
| Section order | Insert, Normal, Visual, Command-line, Terminal, Ex | move → insert → change → compose → repeat/map → options → undo → external → Ex → files → windows → syntax/GUI/folding |
| Total tagged entries | ≈1264 | ≈600 across 41 sections |

Read locally on this machine, not from the web:

- `/nix/store/cyqhaxxc2ygqvvvdm8ybcx4im4qn0asf-neovim-unwrapped-0.11.6/share/nvim/runtime/doc/index.txt` (1722 lines, `grep -c '^|'` → 1264)
- `…/doc/quickref.txt` (1408 lines; the 41-section table of contents is lines 9–31)
- `…/doc/motion.txt` (1403 lines)

`index.txt` says so itself: *"The lists are sorted on ASCII value… Tip: When
looking for certain functionality, use a search command."* It is a lookup index
and it knows it. `quickref.txt` is what vim hands you when you want to *read*,
and the first thing it does is throw the mode grouping away and prefix its
sections with `motion:`, `insert:`, `change:` and `Ex:` instead.

The page as it stood was `index.txt`: one wall, sorted by ASCII, grouped by the
one axis (which-key's prefix groups) that only covered 8% of the data.

## quickref's 41 sections, with entry counts

Because the chunk size is the actual number worth stealing:

| Section | n | Section | n | Section | n |
|---|--:|---|--:|---|--:|
| motion: Left-right | 17 | change: Changing text | 32 | Ex: Ranges | 12 |
| motion: Up-down | 10 | change: Complex | 11 | Ex: Special characters | 11 |
| motion: Text object | 28 | Visual mode | 9 | Starting Vim | 29 |
| motion: Pattern searches | 14 | Text objects | 22 | Editing a file | 12 |
| motion: Marks | 16 | Repeating commands | 15 | Argument list | 11 |
| motion: Various | 6 | Key mapping | 22 | Writing and quitting | 21 |
| motion: Using tags | 19 | Abbreviations | 10 | Automatic commands | 17 |
| Scrolling | 13 | Options | 13 | Multi-window | 30 |
| insert: Inserting text | 11 | Undo/Redo | 3 | Buffer list | 13 |
| insert: Keys | 9 | External commands | 2 | Syntax highlighting | 12 |
| insert: Special keys | 18 | Quickfix | 15 | GUI | 7 |
| insert: Digraphs | 4 | Various commands | 14 | Folding | 16 |
| insert: Special inserts | 2 | Ex: Command-line editing | 23 | | |
| change: Deleting text | 12 | | | | |
| change: Copying and moving | 13 | | | | |

Two to thirty-two, clustered 10–20. Not one section is allowed to become the
Ex-commands wall.

## The printable cards

| Source | Groups by | Sections | Entries | Columns | Key notation | Modes shown as |
|---|---|--:|--:|--:|---|---|
| [vim.rtorr.com](https://vim.rtorr.com/) | task | 17 | ~100–120 | responsive card grid; **key left in code style, description right** | `Ctrl+e`, `:h[elp]` | two of the section names ("Insert mode", "Marking text (visual mode)") |
| [devhints.io/vim](https://devhints.io/vim) | task, two tiers | 7 H2 / **32 H3** | — | **3** (`{: .-three-column}`, chosen for vim specifically) | monospace, `Ctrl+` spelled | only where a sub-table is about a mode |
| [Goerz, Vim Quick Reference Card](https://michaelgoerz.net/refcards/vimqrc.pdf) ([source](https://github.com/goerz/Refcards/blob/master/vim/vimqrc.tex)) | task | 20 | ~220–250 | **4 per page × 2 pages** | caret: `^V`, `^X^E`; `⟨esc⟩` `⟨cr⟩` | an arrow in the heading |
| [ViEmu graphical sheet](http://www.viemu.com/a_vi_vim_graphical_cheat_sheet_tutorial.html) (site down; verified via [archive](https://bamanzi.github.io/scrapbook/data/20110925162521/) and a [faithful vector reproduction](https://hamwaves.com/vim.tutorial/en/vim.tutorial.letter.pdf), pp. 3–5) | **spatial** — drawn on a QWERTY keyboard | none; a 5-colour legend instead | ~90 keys + ~20 in side boxes | keyboard-shaped | the key itself | **colour**: a red label means the key enters insert mode |

Three of the four group by task. The fourth abandons categories entirely for
keyboard geography, and still does not group by mode — it uses colour for the
one mode fact a reader needs.

**Chunk size: 3–8 items per named group**, everywhere. rtorr ~3–8 per section;
devhints 2–6 per sub-table; Goerz 4–20 but broken by dot leaders into
one-glance lines. Nobody asks the eye to scan more than about half a dozen
related rows before a heading resets it.

**Total budget** splits by purpose, and it splits cleanly: **~100–120 entries**
for something you glance at (ViEmu, rtorr), **~250** for a printed desk
reference read serially (Goerz). Not 402.

**Every one of them sets the key in a different typeface from the description.**
Goerz uses typewriter + dot leaders, rtorr a code-styled cell, devhints
monospace, ViEmu a keycap. That is the single most-copied decision in the whole
survey, and it was the one the page was missing: it drew key and description in
the same 11px in the same colour, 128px apart, and the eye had no edge to run
down.

## The live UIs

| Source | Layout | Search | Key notation |
|---|---|---|---|
| [which-key.nvim](https://github.com/folke/which-key.nvim) | multi-column grid, `key ➜ description`, `layout.width.min = 20`, `spacing = 3` | none — you *type the prefix* and the list narrows | **resolves to glyphs**: `C = 󰘴`, `S = 󰘶`, `CR = 󰌑`, `Tab = 󰌒`. Groups render as `+file` (`icons.group = "+"`) |
| [LazyVim keymaps](https://www.lazyvim.org/keymaps) | markdown table, **Key \| Description \| Mode** | page search | literal `<leader>`, `<C-x>` — the docs page stays textual where the popup uses glyphs |
| VS Code keyboard shortcuts editor ([docs](https://code.visualstudio.com/docs/configure/keybindings)) | Command \| Keybinding \| When \| Source | **one box matching command name AND key-chord text**: *"enter a command or shortcut to filter the list"* | `Ctrl+K Ctrl+S` — `+` joins modifiers, space joins chord steps |
| VS Code command palette | list | matches **command title only**; shows the key as a hint | — |
| [Spacemacs](https://www.spacemacs.org/doc/CONVENTIONS.html) | minibuffer list | type the prefix | `SPC f f` — space-separated tokens, never resolved to a glyph |
| [GitHub `?`](https://docs.github.com/en/get-started/accessibility/keyboard-shortcuts) | sections by area | **none** — it is context-aware instead, showing only what applies to the page | — |
| [Gmail `?`](https://support.google.com/mail/answer/6594) | sections by category | none | — |

Notes on what could **not** be verified: Slack's panel is widely described as
having a search box but its own help article documents only the static list, so
that is a secondary source; and no evidence was found that Notion has a
searchable *keybinding reference* overlay at all — `Cmd+K` is a command
launcher, which is a different thing.

The consensus for something with both a box and a browsable body:

1. One free-text box at the top that **filters an already-grouped list in
   place** — headings stay, they just empty out — rather than replacing the
   grouping with a flat ranked list.
2. **Match both the description and the literal key text.** VS Code's editor is
   explicit about this and it is the right call: people remember one or the
   other, rarely both.
3. Grouping stays visible under the filter, because spatial memory is what
   makes the *second* lookup fast.

## The grammar, which is the thing you do not enumerate

`motion.txt` §1 lists **14 operators** (`c d y ~ g~ gu gU ! = gq gw g? > < zf
g@`) and then states composition as a *rule* — "the motion commands can be used
after an operator command… to have the command operate on the text moved over".
§6 does the same for text objects: `a` takes the whitespace, `i` does not, and
then lists ~11 object kinds. Nowhere does vim's own documentation enumerate the
cross product. `d` × `iw` is not an entry; it is two entries that combine.

Community writeups converge on the same three lists —
[Learn-Vim ch04](https://github.com/iggredible/Learn-Vim/blob/master/ch04_vim_grammar.md),
[RC3](https://rc3.org/2012/05/12/the-grammar-of-vim/),
[riptutorial](https://riptutorial.com/vim/example/27570/using--verbs--and--nouns--for-text-editing) —
verbs `y d c`, nouns `h j k l w b e 0 ^ $ f t } { gg G / ?`, modifiers `i` and
`a` over `w s p` and the bracket/quote pairs.

The practical rule that falls out: **if a family is `{verb} × {noun}`, factor
it; if it is a fixed set of standalone keys, list it flat in a 10-to-20-row
named section.** This page is entirely the second kind — a dump of `lhs → desc`
has no grammar in it to factor — which is why it gets quickref's treatment and
not motion.txt's. Worth knowing for the day the sheet grows a panel that teaches
composition rather than listing maps.

## What was done with all this

- **Sections are tasks**, derived from the key prefix, because every family in
  his config was designed as one. Twelve rules, first match wins, and the
  declaration order is both the match order and the draw order
  (`keys/NvimMaps.qml`). `Everything else` went from **132 rows of 145** to
  **2 of 139**.
- **Section order is not quickref's.** quickref leads with movement because it
  documents the whole editor; this page documents *his additions*, so it leads
  with Finding, Diagnostics and Language server — the leader keys he chose
  himself and cannot remember — and puts the 26 mechanically-generated
  unimpaired `[`/`]` pairs last, for the same reason quickref puts folding and
  the GUI at the bottom.
- **Three columns of section cards** (`keys/Sheet.qml`), which is devhints'
  number for vim specifically, laid out newspaper-style so reading order is
  down-then-right and a section never straddles a column.
- **The key gets a monospace cap on `base02`** and a fixed column to start in —
  the one decision all four printable sheets share.
- **Notation stays literal vim** — `<leader>sf`, `<C-W>d` — not which-key's
  glyphs and not Spacemacs' `SPC s f`, because this page documents a config he
  writes in that notation and searches for in that notation. The search box
  closes the gap the other way: it folds `<`, `>`, `+`, `-`, `_` and which-key's
  `[S]earch [F]iles` mnemonic brackets away, so `leadersf` and `search files`
  both find `<leader>sf`.
- **Modes are a badge, not a section** — one row per key with the modes merged
  into it, as LazyVim's table does, rather than three near-identical rows.
- **Chunk sizes now**: Finding 15, Diagnostics 9, Language server 6, Editing &
  files 10, Moving 8, Completion 8, Windows 4, Commenting 8, Surrounding 29,
  Text objects 7, Debugging 7, Previous / next 26, Everything else 2. Ten of
  thirteen are inside quickref's 2–32 band and near its 13 median; the two
  outliers are single uniform families (mini.surround, vim-unimpaired) that
  would only be split arbitrarily.
- **What was left out**: nothing, but the default view is still *his own* 139
  and not vim's 182 builtins, which the survey's ruthlessness argument supports
  — the builtins he either knows or can reach with `:help`, and they are one
  Ctrl+Down away.

## Sources

Local: the three `.txt` files above, from
`/nix/store/cyqhaxxc2ygqvvvdm8ybcx4im4qn0asf-neovim-unwrapped-0.11.6/share/nvim/runtime/doc/`.
Web: every URL is linked inline. Two are recorded as unverified —
`yanpritzker.com/learn-to-speak-vim-verbs-nouns-and-modifiers` (title confirmed
by search, direct fetch returned nothing) and `ThePrimeagen/vim-fundamentals`
(exists, not fetched) — and the ViEmu original is dead, so the archive mirror
and the vector reproduction are what the claims above actually rest on.
