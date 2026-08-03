# Change the desktop's theme from a terminal.
#
# This is the command for the case the picker cannot serve: an SSH session.
# A terminal's colours belong to the shell that is running in it, so the palette
# his laptop's terminal wears while he is SSH'd into this machine is this
# machine's palette — his fish sources ~/.cache/wal/sequences on startup, and
# over SSH that fish is running here. The laptop's own theme never gets a say.
# So the only thing that can fix the colours in that window is something that
# changes the theme on this end, over the one channel SSH gives him.
#
# It talks to the shell through two files and nothing else — no Wayland socket,
# no D-Bus, no `qs ipc call`, no running instance required. `qs` finds an
# instance by config path *and* display connection, so it is unreachable from a
# session that has no WAYLAND_DISPLAY, which is exactly what an SSH session is.
#
#   themes.json   written by the shell: every palette the picker offers,
#                 keyed by slug. Read-only here.
#   theme.json    the shell's state file. Writing it is what changes the theme;
#                 the shell watches it, recolours itself and republishes
#                 ~/.cache/wal/*, which is what repaints the terminals.
#
# Setting a theme with the shell stopped works too — it is picked up on start.

state="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/by-shell/erikshell"
book=$state/themes.json
live=$state/theme.json

if [ ! -r "$book" ]; then
    echo "erikshell-theme: no theme list at $book" >&2
    echo "  the shell writes it at startup — has it ever run on this machine?" >&2
    exit 1
fi

now=$(jq -r '.name // empty' "$live" 2>/dev/null || true)

case "${1-}" in
    --slugs)
        # One slug per line, for the fish completion. Nothing else.
        jq -r 'keys[]' "$book"
        exit 0
        ;;
    -h | --help)
        cat <<EOF
usage: erikshell-theme [name]

  erikshell-theme                 list every theme, current one marked
  erikshell-theme gruvbox         switch to it
  erikshell-theme "Tokyo Night"   the display name works too
  erikshell-theme pine            any unambiguous fragment works

Recolours the shell, every open terminal, kitty, waybar and neovim.
EOF
        exit 0
        ;;
    "")
        jq -r --arg now "$now" '
            to_entries | sort_by(.key)[]
            | (if .value.name == $now then "*" else " " end)
              + " " + .key + "  " + .value.name + " (" + .value.variant + ")"
        ' "$book"
        exit 0
        ;;
esac

want=$(printf %s "$1" | tr '[:upper:]' '[:lower:]')

# Slug first, then display name, then any unambiguous fragment of either —
# so `gruvbox`, `Gruvbox`, and `pine` all land somewhere, and `gruv` says
# which twenty it could have meant instead of guessing.
key=$(jq -r --arg w "$want" '
    [ to_entries[] | select(.key == $w or (.value.name | ascii_downcase) == $w) ]
    | .[0].key // empty
' "$book")

if [ -z "$key" ]; then
    hits=$(jq -r --arg w "$want" '
        to_entries[]
        | select((.key | contains($w)) or (.value.name | ascii_downcase | contains($w)))
        | .key
    ' "$book" | sort)
    count=$(printf %s "$hits" | grep -c . || true)

    if [ "$count" = 1 ]; then
        key=$hits
    elif [ "$count" = 0 ]; then
        echo "erikshell-theme: no theme called '$1'" >&2
        exit 1
    else
        echo "erikshell-theme: '$1' matches $count themes:" >&2
        echo "$hits" | while IFS= read -r h; do echo "  $h"; done >&2
        exit 1
    fi
fi

# Written beside the file and renamed, so the shell's watch never sees half a
# palette. jq -S sorts the keys, which is also what makes the write different
# from the shell's own and so worth republishing.
tmp=$(mktemp "$state/.theme.XXXXXX")
trap 'rm -f "$tmp"' EXIT
jq -S --arg k "$key" '.[$k]' "$book" >"$tmp"
chmod 644 "$tmp"
mv -f "$tmp" "$live"

jq -r --arg k "$key" '"\(.[$k].name) (\(.[$k].variant))"' "$book"
