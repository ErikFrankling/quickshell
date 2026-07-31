# Notification history on disk

**Question.** Of the shells that keep a notification list, which of them write
it to disk, where do they put it, what stops it growing forever, how often do
they write, and what do they do about an image path that will not exist next
boot?

Twelve of the projects read for this register a `NotificationServer`. Seven of
them keep only the popups and forget a notification the moment it leaves the
screen. Five keep a list that outlives the popup, and of those five, three write
it to disk. The other two — and this shell, until now — lose the lot when the
process exits.

## Who persists, and how

| Project | File | Where | Cap | Write |
|---|---|---|---|---|
| noctalia v4 | `Services/System/NotificationService.qml:617-655` | `FileView` + `JsonAdapter`, `Settings.cacheDir + "notifications.json"` (`:23`) | 100 entries (`:22`, enforced `:603-612`) | debounced 200 ms (`Timer :633-637`) |
| vast-shell | `Qml/Services/Notifs.qml:161-241` | `FileView`, `Paths.cacheDir + "/mushell/notifications.json"` (`:164`) | 100 entries **and** 7 days (`:22-23`, applied on load `:189-190`, `:219-220`) | debounced 2 s (`Timer :76-81`) |
| skwd | `skwd-notification/qml/NotificationShell.qml:19-29` | `FileView`, `Config.historyPath` | `Config.historyMax`, applied twice — on insert (`:42`) and again on write (`:27`) | every notification, no debounce (`:44`) |
| tripathiji1312 | `services/Notifs.qml:56-61` | `PersistentProperties` | 100 in memory (`:16`, `:102-106`) | n/a — survives a *reload*, not a restart |
| Ricelin | `pill/Singletons/Notifs.qml:212` | not persisted | 50 in memory | — |

Two conclusions the table makes for you: **100 is the number** (three of the
four picked it independently) and **everyone who persists also debounces or
caps the write**, because the write happens on the notification path. This
shell writes at most once a second, which is between noctalia's 200 ms and
vast-shell's 2 s, and the write is one `JSON.stringify` of at most 100 entries
— about 20 KB measured, so a burst of a hundred notifications costs one 20 KB
atomic write rather than a hundred of them.

The odd one out is tripathiji1312's `PersistentProperties`, which is worth
naming so nobody reaches for it here: it survives a config reload inside the
same process and nothing more. It is the right tool for `dnd`, which is what he
uses it for alongside `lastReadAt` (`:56-61`), and the wrong tool for history.

## Cache or state?

noctalia and vast-shell both write history to the **cache** directory and both
treat it as regenerable. This shell writes to `Quickshell.statePath()` instead,
next to `saved.json`, `pins.json` and `theme.json`. A cache directory is a
directory anything is allowed to delete; the whole point of the feature is that
the list is still there after a reboot, so it belongs in state. It is also the
idiom already in the file, and one mechanism beats two.

## Unread across a restart

Two designs exist in the wild and they are the same design:

- noctalia keeps a single `lastSeenTs` (`NotificationService.qml:26`, saved to
  `ShellState` at `:703-712`, set to now when you open the list at `:714-717`),
  and the bar widget counts entries newer than it
  (`Modules/Bar/Widgets/NotificationHistory.qml:43-55`).
- tripathiji1312 keeps the same timestamp as `lastReadAt` (`:54`) and stamps a
  per-entry `read` from it at construction (`:262`).

Both mean the same thing: unread is a fact about the entry, it is derived from
persisted state, and it survives a restart. This shell already had the per-entry
form (`seen`), so persisting history persisted unread for free. Nobody in the
survey marks everything read at startup, and nobody counts everything unread
either.

## Dead image paths

This is the part worth reading twice, because it is where a reloaded entry gets
ugly.

`NotificationServer` hands you `image` and `appIcon` as strings
(`quickshell-service-notifications.qmltypes:66`, `:155`). The value is often
`image://...` — a QML image-provider URL backed by pixel data the *server*
holds. It is meaningless in the next process, and a file path handed over by an
app can be a temp file that is gone by then.

- vast-shell copies provider images into its own cache directory as it receives
  them (`Qml/Services/Notifs.qml:389-397`, `ImageCache.saveProviderImageQml`),
  persists the copy, and on load discards anything still starting with
  `image://`: *"image:// URLs are provider-ephemeral and cannot survive a
  reload"* (`:193-196`).
- noctalia does the same on the way in and, when an entry falls off the end of
  the cap, deletes the cached file with it — but only if the path is inside its
  own cache directory (`NotificationService.qml:603-611`). On load it falls back
  from `cachedImage` to `originalImage` and tolerates both being empty
  (`:659-673`).

Neither of them can render a broken image, and neither can this shell, for a
simpler reason: `snapshot()` never stored an icon or an image in the first
place, and no card draws one. A notification sent with `-i /path/that/is/deleted`
round-trips through `history.json` with no image key at all. The cheapest way to
handle a dead path is not to keep it.

What did have to go on reload is **actions**. `invoke()` looks the notification
up in `root.live`, which is populated by the server and is empty for anything
read off disk, so a reloaded card would have offered buttons that silently did
nothing. `load()` strips them. Same principle as vast-shell's `image://` line,
applied to the other thing that dies with the process.
