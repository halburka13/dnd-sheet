# D&D Character Sheet & Town Manager

Two offline-friendly web apps for a D&D 5e (2014) campaign. They install on a tablet, phone or computer, keep working without internet, and sync through one shared online database.

| App | Address | What it's for |
|---|---|---|
| **Character app** | https://halburka13.github.io/dnd-sheet/ | Character sheets (several characters), plus a Town tab |
| **Town app** | https://halburka13.github.io/dnd-sheet/town/ | Only the town: treasury, income, projects, chronicle. Made for sharing with the GM |

Both apps use the same towns, so a change in one shows up in the other after it syncs.

---

## Installing on a device

Do this once per device, for each app you want.

1. Open the address in **Chrome** (Android, Windows or Mac) or **Edge**.
2. Install it:
   - **Android:** ⋮ menu → **Add to home screen** → **Install**
   - **Computer:** the install icon at the right end of the address bar, or ⋮ → **Cast, save, and share** → **Install page as app**
3. Open the app from its new icon, go to the **Sync** tab, and sign in.

Each app has its own sign-in, so sign in to both. The first time, open the app while online so it can save a copy for offline use.

## Using the character app

- **Combat:** HP (damage uses temp HP first), AC with a Shield toggle, concentration, conditions, exhaustion, death saves, attacks, and features with charges.
- **Spells:** spell slots, pact slots, Cast buttons, prepared spells, rituals, and Cantrip Formulas. Under **Spellcasting classes** you can add a class for a new character (for example Cleric, WIS, prepares spells).
- **Character / Inventory / Notes:** abilities, saves, skills, coins, items, attunement, and session notes.
- **Short rest / Long rest:** buttons at the top that refill slots, HP, hit dice and features.
- **Characters:** tap the name at the top to switch characters, start a **New character** (blank sheet), or **Archive** one. Archived characters are never deleted, and you can restore them from the same list.

## Using the town app (or the Town tab)

- **End turn** adds income, subtracts expenses, and writes the result in the chronicle.
- **Add transaction** puts money into the treasury or takes it out, with a note.
- **Town stats** are anything the GM tracks, such as population, morale or defense.
- **Buildings & projects:** if a planned project has a cost, a button pays it from the treasury.
- **New town** and the town picker let you run more than one town.

## Offline and syncing

- Every change is saved on the device first, so the apps never wait for the internet.
- When you're offline, a gold **"Offline"** label appears at the top. Keep playing as normal.
- When the device is back online, it syncs by itself: on opening, about every 20 seconds while open, and right after reconnecting. Tap the gold label to sync immediately.
- If two devices changed **different** things, both changes are kept. If they changed the **same** thing, the newer edit wins. The exceptions are gold and the town treasury, where both devices' changes are added together, and the chronicle, where entries from both are combined.
- **Backups:** on the **Sync** tab, **Save backup file** saves a copy to Downloads. **Load backup** adds it as a new character or town, so nothing gets overwritten.

## Sharing a town with the GM

1. **Make the GM an account:** on supabase.com, open the project, then **Authentication → Users → Add user → Create new user**. Enter his email and a temporary password, and tick **Auto Confirm User**.
2. **The GM signs in** to the town app, changes his password (**Sync → Change password**), and copies his **user code** from the Sync tab.
3. **Share the town:** in the Town tab, tap **Share**, paste his code, and choose **Can edit** or **View only**.

The GM only sees towns that were shared with him, never anyone's characters.

## Updating the apps

When Claude provides new files:

```powershell
Copy-Item -Path "D:\Downloads\<unzipped folder>\*" -Destination "D:\dnd-sheet\dnd-sheet" -Recurse -Force
cd D:\dnd-sheet\dnd-sheet
git add -A
git commit -m "Describe the update"
git push
```

GitHub Pages updates about a minute later. Each device picks up the new version the **second** time the app is opened.

If you change `index.html` yourself, run `python build-town.py` before committing. It rebuilds the town app from the same file.

## Troubleshooting

- **The town address shows the character sheet:** use the address with a slash at the end (`/dnd-sheet/town/`) and refresh once. This was fixed in v4. Open the character app twice after updating so the fix takes over.
- **An update doesn't appear:** close the app completely and open it again. Still nothing? Open the address in a Chrome tab and refresh twice.
- **Sync stopped working after a break:** free Supabase projects pause after about a week without use. Sign in at supabase.com and press **Restore project**. The apps keep working offline in the meantime and catch up afterwards.
- **"Sync isn't set up":** `config.js` is missing its project URL or key. It's already filled in for this project, so re-upload it if it was replaced.
- **Last resort reset:** first check the Sync tab says **Synced**. Then in Chrome go to ⋮ → **Settings** → **Site settings** → **All sites** → **halburka13.github.io** → **Delete data**, and sign in again. Everything downloads from your account.

## Accounts and passwords

- **supabase.com dashboard:** you sign in with GitHub. This is only for managing the database.
- **App login:** the email and password created under **Authentication → Users**. This is what you type in the apps.
- **Database password:** not used by the apps. You can reset it any time in **Project Settings → Database**.

Keep the app login in a password manager such as Samsung Pass or Google Password Manager.

## Files

| File | Purpose |
|---|---|
| `index.html` | The character app (everything in one file) |
| `town/` | The town app. `town/index.html` is generated by `build-town.py` |
| `sw.js`, `town/sw.js` | Offline support for each app |
| `config.js` | Supabase project address and public key (safe to publish) |
| `supabase.js` | Sync library, stored locally so it works offline |
| `manifest.webmanifest`, `icon-*.png` | App name and icons for installing |
| `supabase-setup.sql` | Database tables and access rules (already applied) |
| `DEVELOPER.md` | Technical notes on how the apps and sync work, for the GM |
