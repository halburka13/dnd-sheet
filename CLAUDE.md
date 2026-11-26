# CLAUDE.md

## What this is
Two offline-first PWAs for a D&D 5e (2014 rules) campaign, hosted on GitHub Pages from this repo (`halburka13/dnd-sheet`, branch `main`, site root = repo root):

- **Character app**: https://halburka13.github.io/dnd-sheet/ (`index.html`). Multiple characters, plus a Town tab.
- **Town app**: https://halburka13.github.io/dnd-sheet/town/ (`town/index.html`). Town management only, shareable with the GM.

Sync backend: Supabase project **`jxhmfqjrlcwkvunzyuwl`** (Postgres + Auth, email/password, sign-ups disabled; users are created in the dashboard).

## About the user
- The owner is a mechanical engineering undergrad, not a web developer. Explain changes in plain language, give exact commands, and say which device steps (tablet, browser) are needed after a deploy.
- The main device is a Samsung Galaxy Tab S10 FE (Android, Chrome).
- The GM is a CENG grad student and may read `DEVELOPER.md` or contribute.
- The main character is **Galesh Nesta**: Changeling, Warlock 3 (Hexblade, Pact of the Blade) / Wizard 6, plus spells from a lost Magic Initiate (Sorcerer) item. Data lives in Supabase, not in code. `DEFAULT` in `index.html` is only the v1 seed and is used for legacy migration.

## Architecture (no build step, no framework)
- `index.html` holds all CSS and JS for the character app: render functions per tab return HTML strings, plus one delegated `click` / `input` / `change` handler using `data-a` (action), `data-k`, `data-i` and `data-b` (bind path, e.g. `hp.cur`, `town.treasury`).
- **`town/index.html` is generated.** Never edit it by hand. Edit `index.html`, then run `python build-town.py`, which sets `window.APP_MODE="town"` and rewrites paths to `../`. In code, `TOWN_ONLY` gates town-mode behavior.
- State: `S` = active character doc, `T` = active town doc. `S.town` is a non-enumerable getter returning `T`, so `town.*` bind paths work and town data is never serialized into the character.
- `supabase.js` is a vendored UMD build of supabase-js **2.118.0** (kept local for offline). Don't swap it for a CDN import.
- `sw.js` / `town/sw.js`: app shell is stale-while-revalidate, so devices get a deploy on their **second** launch. The main SW must ignore `/town` paths and only answer navigations for `""` or `index.html` relative to its scope. That was a real bug (v4).

## Local storage and sync
- Keys use namespace `NS` = `dnd2` (character app) or `dndtown` (town app). They're separate on purpose, and so are the auth storage keys (`dnd-sync-auth` / `dndtown-auth`), so the two apps don't fight over refresh tokens.
- Per doc: `${NS}-c:<id>` / `${NS}-t:<id>` plus `${NS}-meta-{c|t}:<id>` = `{rev, base, pending, owner}`. `${NS}-account` holds the last signed-in uid. If a different user signs in, local docs are wiped.
- Legacy v1 (`dnd-sheet-v1` single sheet) is migrated in `bootLocal()` to character id = user id and town id = user id. The server side was migrated the same way.
- Sync = per-doc **three-way merge** (`merge3(base, local, remote)`). Leaf conflicts resolve to the newer client `updatedAt`. `town.treasury` and `coins.*` add both sides' deltas. `town.log` takes the union.
- Writes are optimistic: `update … eq(id) eq(rev, seen)` writing `rev+1`. 0 rows means a concurrent write (retry) or a viewer without rights (adopt the remote copy).
- `migrate()` upgrades doc schema (`v`). Bump `v` and add a block when the data shape changes, and keep old blocks. Remote docs pass through `migrate()` too.

## Database (see `supabase-setup.sql`, keep it in sync with any migration)
- `characters`: owner-only RLS.
- `towns`: readable by owner and members, updatable by owner and editors. A trigger keeps `owner` immutable.
- `town_members (town_id, user_id, role editor|viewer)`.
- `private.town_access(uuid)`: security definer in a **non-exposed** schema, used by policies to avoid RLS recursion.
- `character_sheets`: legacy v1 table, read-only backup. Don't write to it or drop it without asking.
- Use the Supabase MCP for schema changes (`apply_migration`), then run security advisors. Never put the service-role key in client code. The publishable key in `config.js` is meant to be public.

## Workflow
- **Test:** `npm install` once, then `npm test`. This runs jsdom smoke tests for both apps and the merge rules. Run it after every change, and after `python build-town.py`.
- **Deploy:** commit and push to `main`. GitHub Pages publishes in about 1 minute.
- **When to bump caches:** bump `CACHE` in `sw.js` (and `town/sw.js`) whenever the service worker logic changes or you need devices to drop stale files.
- **After a deploy, tell the user:** open the app twice on each device.
- **Before pushing,** show the user the diff summary and get a yes.

## Conventions
- Keep everything in single files with no bundler. External scripts are only allowed if vendored.
- **Accessibility:** tap targets at least 36–44px, `aria-label` on icon buttons, and a working light/dark theme via CSS variables.
- **Text:** use typographic apostrophes and quotes in UI text (’ “ ”) and plain ASCII in code.
- **Destructive actions** (remove, archive, reset) go through a confirm modal. Nothing is hard-deleted on the server; characters are archived.
- **Content:** don't reproduce copyrighted rulebook text. Feature descriptions are short paraphrases.
