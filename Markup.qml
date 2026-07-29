pragma Singleton

import Quickshell
import QtQuick

// Notification bodies arrive as loose HTML — KDE Connect relays Android text
// verbatim, so <br/>, <p>, entities and unclosed tags are all normal. QML's
// rich text is more forgiving than Pango, but it still needs the block tags
// turned into breaks and stray markup cleaned up.
Singleton {
    readonly property var entities: ({
        amp: "&", lt: "<", gt: ">", quot: "\"", apos: "'", nbsp: " ",
        hellip: "…", mdash: "—", ndash: "–", bull: "•", middot: "·",
        lsquo: "‘", rsquo: "’", ldquo: "“", rdquo: "”", deg: "°", eacute: "é"
    })

    function decode(s) {
        return s.replace(/&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);/g, (m, r) => {
            if (r[0] === "#")
                return String.fromCodePoint(parseInt(r.slice(r[1] === "x" ? 2 : 1), r[1] === "x" ? 16 : 10));
            return entities[r] ?? m;
        });
    }

    // Rich text for display.
    function rich(body) {
        if (!body)
            return "";
        return decode(body
            .replace(/<\s*br\s*\/?\s*>/gi, "<br/>")
            .replace(/<\s*\/?\s*(p|div|li|ul|ol|tr|table|blockquote|h[1-6])[^>]*>/gi, "<br/>")
            .replace(/<\s*img[^>]*>/gi, "")
            .replace(/(<br\/>\s*){2,}/g, "<br/>"))
            .replace(/^(<br\/>)+|(<br\/>)+$/g, "")
            .trim();
    }

    // Same content with all tags gone, for one-line previews.
    function plain(body) {
        return decode(String(body ?? "")
            .replace(/<[^>]*>/g, " "))
            .replace(/\s+/g, " ")
            .trim();
    }
}
