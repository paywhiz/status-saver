# Roadmap — proposed features

A living, prioritized list of features that have been considered but are not
yet implemented. Sorted by **impact × ease**. Each entry includes a one-line
problem framing, a sketch of the approach, and a rough effort estimate
(**S** ≈ a day, **M** ≈ a few days, **L** ≈ a week+).

Pick one up, link the PR back to its bullet here, and remove the entry once
shipped.

---

## Top quick wins (high impact, low effort)

### 1. Multi-select / batch actions — **S**

Long-press on a tile enters selection mode; tap to toggle more. Floating
action bar exposes batch **Save**, **Share**, **Delete**.

- Add `selectionMode` and `selected: Set<String>` to `RecentController` /
  `SavedController` (or a small mixin).
- `StatusTile.onTap` becomes "toggle selection" while selection is active.
- `saveStatusItem` already takes one item; loop over the set.

### 2. Favorites on saved items — **S**

A small star button on saved tiles toggles a favorite flag. New "Favorites"
filter chip on the Saved tab.

- Persist a `Set<String>` of saved filenames in `SharedPreferences`
  (key: `saved.favorites`). No DB needed.
- Filter the `SavedController.items` getter by membership.

### 3. Date grouping headers — **S**

Group the grid by **Today / Yesterday / This week / Older**. Pure UI on data
already in memory — bucket the list by `modified`, render section headers
between sliver groups.

### 4. Direct share back to WhatsApp — **S**

The OS share sheet already lists WhatsApp. Add a direct shortcut button that
prefilters to the WhatsApp packages.

- `share_plus` `Share.shareXFiles(..., subject: ..., text: ...)` plus an
  Android-only intent component override targeting `com.whatsapp` /
  `com.whatsapp.w4b` (already in `<queries>` in the manifest).

---

## Mid-effort enhancements

### 5. Search saved by filename / date — **M**

A search field in the Saved app bar; substring match on `displayName` and a
date-range chip ("Last 7 days", "This month").

### 6. Auto-cleanup of in-app saved items — **M**

Settings toggle: "Delete in-app saves older than N days". Background pass on
app start that scans `<appDocs>/saved/` and deletes by mtime. Surface
last-cleanup time in Settings for transparency.

### 7. Statistics screen — **M**

Tiny "Stats" page: counts of saved images / videos, total disk used, most
active day of week, most-saved origin. Pure derivation from
`SavedController.items` + `dart:io` `stat()` calls. No tracking, no network.

### 8. App lock (biometric / PIN) — **M**

For users who choose **In-App** save destination specifically because they
don't want statuses in Photos. Use `local_auth`; gate the entire Navigator
behind a `BiometricGate` widget. PIN fallback via a 4-digit code in
encrypted storage.

---

## Larger investments (defer until justified by demand)

### 9. Repost-detection — **L**

Track sha256 hashes of every saved status; the Recent tab marks items
already in your library with a small badge. Hash on background isolate so
the grid stays fluid. Storage: side-table in SQLite via `sqflite` (~1KB per
50 items).

### 10. Export saved as ZIP — **M**

"Export all" button in Settings → bundles `<appDocs>/saved/` into a ZIP and
hands it to the OS share / save-to-Files sheet. Use `archive` package.

### 11. Cloud backup (Google Drive / iCloud) — **L**

Optional, off by default. Sign-in with the platform's native flow, sync
saved items both ways. Conflict policy: newest-mtime-wins. The complexity
is in re-auth handling, partial uploads, and quota errors — write a small
spec before starting.

### 12. Localization (i18n) — **M**

Wire `flutter_localizations` and ARB files. Start with English + 2-3 widely
used languages (Hindi, Portuguese-BR, Indonesian have a strong WhatsApp
audience). Worth doing once the UI surface stops moving.

### 13. Accessibility pass — **M**

Audit:

- Semantics labels on every actionable widget (tile = "<image|video>,
  saved <when>, double-tap to open, long-press to select").
- Dynamic type sizing — verify the layout at 200% text scale.
- Color contrast — both themes against WCAG AA.
- TalkBack / VoiceOver: navigation order, no traps.
