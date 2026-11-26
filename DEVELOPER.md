# Developer notes (for the GM)

A static PWA hosted on GitHub Pages, with Supabase (Postgres + Auth) as the sync backend. There's no build step: plain HTML/JS in `index.html`, a vendored `supabase.js` UMD bundle (supabase-js 2.118.0), and a service worker.

## Files
- `index.html`: the whole app (UI, local store, sync engine).
- `town/`: the standalone Town manager, a second installable PWA at `/dnd-sheet/town/`. `town/index.html` is **generated** from `index.html` by `build-town.py` (it sets `window.APP_MODE="town"`, which hides the character tabs and syncs only towns). Edit `index.html`, then run `python3 build-town.py`.
- `sw.js`: offline cache. App shell is stale-while-revalidate, so a deploy reaches devices on their second launch. Bump `CACHE` to force-clean old caches.
- `config.js`: Supabase URL and publishable key (public by design, RLS does the protecting).
- `supabase-setup.sql`: full schema, policies and triggers (already applied to the project).

## Data model
| table | purpose | access |
|---|---|---|
| `characters` | one row per character, `data` jsonb = full sheet | owner only |
| `towns` | one row per town, `data` jsonb = treasury, income, expenses, stats, projects, chronicle | owner + `town_members` |
| `town_members` | `(town_id, user_id, role)`, role = `editor` or `viewer` | owner manages; member can see and delete their own row |
| `character_sheets` | legacy single-sheet table from v1, kept as a backup and no longer written by v2 clients | owner only |

`private.town_access(town_id)` (security definer, in a non-exposed schema) returns `owner` / `editor` / `viewer` / null for the caller. It's used by the town policies to avoid RLS recursion between `towns` and `town_members`. A trigger keeps `owner` immutable and touches `updated_at`.

## Sync
- Offline-first: every document lives in `localStorage` (`dnd2-c:<id>`, `dnd2-t:<id>`) with metadata `{rev, base, pending, owner}`.
- On sync, each doc is reconciled with a **three-way merge** (`base` = last synced copy, `local`, `remote`). Leaf conflicts resolve to the doc with the newer client `updatedAt`. Exceptions: `town.treasury` and `coins.*` add both sides' deltas, and `town.log` takes the union.
- Writes are optimistic: `update ... where id = $1 and rev = $seen`, writing `rev + 1`. 0 rows updated means a concurrent write (re-sync) or a viewer without rights (adopt the remote copy).
- The two apps share one sign-in (auth storageKey `dnd-sync-auth`) and one local copy of each town (`dnd2-t:*`). A `storage` event listener picks up the other app's town edits instantly on the same device. Characters stay character-app only.
- Polls `rev` every 20 s while visible, plus on `online` and `visibilitychange`. Realtime isn't used.

## Sharing a town with someone
1. In Supabase, go to Authentication → Users → Add user (signups are off). Give them a temporary password, which they can change in the app (Sync → Change password).
2. They sign in at the app URL and copy their user code (Sync tab).
3. The town owner opens Town → Share, pastes the code, and picks Can edit or View only.

Ideas welcome. The town rules are all plain data in `towns.data`, so the GM can add fields (e.g. buildings with effects, events tables) without schema changes.
