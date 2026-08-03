pragma Singleton

import Quickshell
import QtQuick
import "schemes.js" as Schemes

// Every theme the picker offers, as JSON, so a command line can pick one too.
//
// No palette is copied into this file. The 335 upstream schemes come from
// schemes.js, and the nine curated ones are a property of Themes.qml — of the
// picker component itself — so the only way to read them without keeping a
// second copy in step is to build one picker and ask it. It is never parented
// and never shown, its ListView therefore has no size and creates no
// delegates, and it is destroyed as soon as the list has been read.
//
// Keyed by slug, not by display name, because the slug is one word: it is what
// `erikshell-theme` takes as an argument and what fish completes, and neither
// wants to be quoting "Rosé Pine Dawn". Where a curated palette shares a slug
// with an upstream one — Nord, Kanagawa, Catppuccin Mocha and both Rosé Pines
// are in both lists — the curated one wins, because it is the one with the
// `line` and `accent` slots filled in and the one the picker shows.
Singleton {
    id: root

    // é is the only letter outside ASCII in either list, and QJSEngine has no
    // String.normalize to strip accents generically.
    function slug(name) {
        return name.toLowerCase().replace(/é/g, "e").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    }

    readonly property string json: {
        const picker = maker.createObject(null);
        const rows = Schemes.all.concat(picker.curated);
        picker.destroy();

        const out = {};
        for (let i = 0; i < rows.length; i++)
            out[rows[i].slug ?? root.slug(rows[i].name)] = rows[i].p;
        return JSON.stringify(out);
    }

    Component {
        id: maker
        Themes {}
    }
}
