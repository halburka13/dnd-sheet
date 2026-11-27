# CLAUDE.md

## What this is
Two offline-first PWAs for a D&D 5e (2014 rules) campaign, hosted on GitHub Pages from this repo (`halburka13/dnd-sheet`, branch `main`, site root = repo root):

- **Character app**: https://halburka13.github.io/dnd-sheet/ (`index.html`). Multiple characters, plus a Town tab.
- **Town app**: https://halburka13.github.io/dnd-sheet/town/ (`town/index.html`). Town management only, shareable with the GM.

Sync backend: Supabase project **`jxhmfqjrlcwkvunzyuwl`** (Postgres + Auth, email/password, sign-ups disabled; users are created in the dashboard).

## About the user
- The owner is a mechanical engineering undergrad, not a web developer. Explain changes in plain language, give exact commands, and say which device steps (tablet, browser) are needed after a deploy.
- The main device is a Samsung Galaxy Tab S10 FE (Android, Chrome).
- The GM is a CENG grad student and may read `DEVELOPER.md` or contribute. **The GM may also use Claude on this repo:** the "Campaign" and "Character data" sections below are written for that too.
- Character data lives in Supabase, not in code. `DEFAULT` in `index.html` is only the v1 seed and is used for legacy migration.

## Campaign (what the player has, as of 2026-11-27)
- **Party:** Galesh (player), a Chronurgy wizard, a dragon-themed circle druid, a shadow monk. Galesh and the kineticist are the same player and are **not played at the same time**.
- **Town:** one shared town, **Evermore** (towns table, owner = the player). The GM can be given access with Town → Share.
- **Galesh Nesta:** Changeling, Warlock 3 (Hexblade, Pact of the Blade) / Wizard 6 (**Bladesinging**), plus spells from a lost Magic Initiate (Sorcerer) item. Proficiency +4. Weapons: **hand crossbow** (Hex Warrior, Cha) and a **one-handed warhammer** as pact weapon (Cha). Features include Bladesong (4/long rest), Extra Attack, Training in War and Song. Plans to take **Crossbow Expert** at the next level (Warlock 4) for a bonus-action hand crossbow shot.
- **“Unnamed kineticist”** (name still to be chosen): Custom Lineage (darkvision), Folk Hero, **Kineticist 9** from the homebrew below, **Weaver** subclass, **Fire main / Air second**. Str 12, Dex 20, Con 20, Int 14, Wis 16, Cha 16. HP 101 (rolled), AC 17 (studded leather). Feats: **Slasher** (level 1, +1 Dex), **Lucky** (level 8); +2 Dex at level 4. Impulse DC 17, impulse attack +9, blasts +9 / 1d8+5, 2 per action.
- **Kineticist homebrew:** class https://homebrewery.naturalcrit.com/share/3F3ghSEF-m5j , impulse list https://homebrewery.naturalcrit.com/share/67acIrX07oMQ (use `/source/` instead of `/share/` to read the raw markdown).
- **GM rulings so far:**
  - A Weaver can learn **any impulse from any of their elements** whenever they gain a new impulse (not only the two level-1 impulses from Second Gate).
  - Impulses **don’t count as spells** for feats and their prerequisites (Elemental Adept, Spell Sniper, War Caster…). They still count as spells for Counterspell, Dispel Magic and Detect Magic, as the homebrew says.
  - Bladesinger Extra Attack: **only one** of the two attacks can be replaced by a cantrip (RAW). The app enforces this.
  - 2014 rules otherwise; all official books allowed, flying races allowed.
- **Open questions for the GM:** does Ash Strider get the +5 fire Impulse Junction damage; can the Loxodon-style “trunk as free hand” idea be ignored (it was dropped); gold and magic items for the kineticist.

## Character data (fields beyond the basics)
- `kin` (kineticist only): `{abil, blastAbil, ilvl, aura, stance, gather, blast:{dice,count,range}, auraNote, impulses:[{name, el, lvl, type: Stance|Basic|Surge|Complex, act, range, dmg, text, c}]}`. Shows the Impulses tab and the Aura button. Surge/Complex = overflow (aura off; locked for the rest of the round in combat).
- Spells may carry damage: `dmg` (at the spell’s own level, e.g. `8d6 fire`, `1d10+5 force ×2 beams`, `+1d8 thunder`), `up` (per slot level above), `hit` (`attack` | `save` | `weapon` | `auto`), `save`, `note`. Spells named “…Smite” become a pending rider (`S.riders`) added to the next melee weapon hit instead of rolling on cast.
- A feature named `Bladesong` enables the Bladesong toggle (`S.bladesong`: AC + Int, speed +10).
- `S.combat` = current turn tracker state `{on, round, action, bonus, reaction, move, atk, atkKind, cantripSwap, gather, auraLock, init}`. Past combats are **not** kept (`combats` is set to `null`). `S.rollMode` = `normal|adv|dis`.
- Attack lines (`attacks`) are weapons/blasts only; cantrips are cast from the Spells list. Attack rolls are two-phase: roll to hit, then the player taps Hit or Miss before damage is rolled.
- **Sync caveat:** `merge3` treats a key missing on one side as “keep the other side”, so **deleting a key never syncs**. To clear a field, set it to `null` (or an empty array). Arrays are merged as whole values.
- Editing a character directly in the database is fine (the app merges it), but bump `rev` by 1 and set `data.updatedAt` to the current epoch ms so devices pick it up.

## Architecture (no build step, no framework)
- `index.html` holds all CSS and JS for the character app: render functions per tab return HTML strings, plus one delegated `click` / `input` / `change` handler using `data-a` (action), `data-k`, `data-i` and `data-b` (bind path, e.g. `hp.cur`, `town.treasury`).
- **`town/index.html` is generated.** Never edit it by hand. Edit `index.html`, then run `python build-town.py`, which sets `window.APP_MODE="town"` and rewrites paths to `../`. In code, `TOWN_ONLY` gates town-mode behavior.
- State: `S` = active character doc, `T` = active town doc. `S.town` is a non-enumerable getter returning `T`, so `town.*` bind paths work and town data is never serialized into the character.
- `supabase.js` is a vendored UMD build of supabase-js **2.118.0** (kept local for offline). Don't swap it for a CDN import.
- `sw.js` / `town/sw.js`: app shell is stale-while-revalidate, so devices get a deploy on their **second** launch. The main SW must ignore `/town` paths and only answer navigations for `""` or `index.html` relative to its scope. That was a real bug (v4).

## Local storage and sync
- Keys use namespace `NS` = `dnd2` (character app) or `dndtown` (town app) for app-specific state (`-ids`, `-active`, `-account`, `-sync-time`). **Towns are shared:** both apps store them under `TNS` = `dnd2` (`dnd2-t:<id>`, `dnd2-meta-t:<id>`, id list in `dnd2-town-ids`), and a `storage` event listener reloads a town when the other app changes it, so edits show instantly on the same device. `moveOldTownCopies()` migrates the town app's old `dndtown-t:*` copies once (newer `updatedAt` wins).
- **One sign-in:** both apps use auth storageKey `dnd-sync-auth` (the old `dndtown-auth` is moved over once). supabase-js coordinates pages sharing a storageKey with navigator locks + BroadcastChannel, so refresh tokens don't clash.
- Per doc: `${NS}-c:<id>` / `dnd2-t:<id>` plus the matching `-meta-` key = `{rev, base, pending, owner}`. `${NS}-account` holds the last signed-in uid. If a different user signs in, local docs are wiped.
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
- **Test:** there is no automated test suite in the repo yet. Serve the folder locally (`python -m http.server 8765` in the repo) and check both `/` and `/town/` in a browser, with a test character loaded through Sync → Load backup. Unregister the service worker between test runs, or you get the cached old page.
- **Deploy:** commit and push to `main`. GitHub Pages publishes in about 1 minute.
- **When to bump caches:** bump `CACHE` in `sw.js` (and `town/sw.js`) whenever the service worker logic changes or you need devices to drop stale files.
- **After a deploy, tell the user:** open the app twice on each device.
- **Pushing:** the user wants finished, tested changes committed and pushed to `main` without asking first. Summarize what was pushed afterwards.

## Conventions
- Keep everything in single files with no bundler. External scripts are only allowed if vendored.
- **Accessibility:** tap targets at least 36–44px, `aria-label` on icon buttons, and a working light/dark theme via CSS variables.
- **Text:** use typographic apostrophes and quotes in UI text (’ “ ”) and plain ASCII in code.
- **Destructive actions** (remove, archive, reset) go through a confirm modal. Nothing is hard-deleted on the server; characters are archived.
- **Content:** don't reproduce copyrighted rulebook text. Feature descriptions are short paraphrases.
