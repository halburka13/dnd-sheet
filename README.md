# Galesh Nesta – offline character sheet

This is your character sheet and town manager as an app that installs on your Galaxy Tab. It opens and works with no internet. When a device gets a connection, it syncs with your other devices.

Setup takes about 30 minutes, once. A computer makes the upload steps easier, but everything also works in Chrome on the tablet.

## 1. Make the sync database (Supabase, free)

1. Go to **supabase.com**, sign up, and create a **New project**. Choose any name, set a database password (save it somewhere), and pick a region near you, such as Frankfurt.
2. When the project is ready, open **SQL Editor** in the left menu, then **New query**. Paste everything from `supabase-setup.sql`, then press **Run**. You should see "Success. No rows returned."
3. Open **Authentication > Users > Add user > Create new user**. Enter your email and a password, and tick **Auto Confirm User**. This is the login you'll use in the app.
4. Optional, but recommended so nobody else can make accounts: **Authentication > Sign In / Providers**, then turn off **Allow new users to sign up**.
5. Copy two values for step 2 below:
   - **Project URL**: from **Project Settings > Data API**. It looks like `https://abcdefgh.supabase.co`.
   - **Publishable key**: from **Project Settings > API Keys**. It starts with `sb_publishable_`. If you only see "anon public", use that one.

## 2. `config.js`

Already filled in with your project details. Nothing to do here.

## 3. Put the app online (GitHub Pages, free)

1. Sign up at **github.com**.
2. Click **+ > New repository**. Name it `dnd-sheet`, keep it **Public**, and click **Create repository**.
3. Click **uploading an existing file**. Drag in **all the files from this folder** (not the folder itself), then click **Commit changes**.
4. Go to **Settings > Pages**. Under **Build and deployment**, pick **Deploy from a branch**, then **main** and **/ (root)**, and click **Save**.
5. After a minute or two, your app is at `https://YOUR-GITHUB-NAME.github.io/dnd-sheet/`.

## 4. Install it on the Galaxy Tab

1. Open that link in **Chrome** on the tablet.
2. Tap the **⋮** menu, then **Add to home screen**, then **Install**. If the app shows an **Install as an app** button on its Sync tab, that works too.
3. Open the app from the new icon, go to the **Sync** tab, and sign in with the email and password from step 1.3.
4. Turn on airplane mode and open the app again to check that offline works.

Do the same on any other device (phone, computer) and sign in with the same account.

## 5. Bring over your current data from the claude.ai version

1. Open the claude.ai version, go to **Notes**, and tap **Save backup file**.
2. In the new app, sign in first. Then go to **Sync > Load backup** and pick that file.
3. It syncs to your account, and your other devices receive it the next time they're online.

## How syncing works

- Every change saves on the device first, so the app never waits for the internet.
- When a device is online, it sends its changes and receives the others', when you open the app and about every 20 seconds while it's open.
- If two devices changed **different** things while apart, both changes are kept. For example, HP on the tablet and town projects on the phone.
- If they changed the **same** thing, the most recent edit wins. Gold and the town treasury are the exception: changes from both devices are added together. Chronicle entries from both devices are combined.
- The gold label at the top means you're offline or a sync failed. Tap it to retry.

## Good to know

- **Free Supabase projects pause after about a week with no activity.** If sync stops after a break, sign in at supabase.com and press **Restore project**. The app keeps working offline in the meantime and catches up afterwards.
- **Updating the app:** if Claude gives you a new `index.html` (or other files), upload them to the same GitHub repository. Devices get the update the second time they open the app.
- **Keep a backup now and then:** **Sync > Save backup file**.
