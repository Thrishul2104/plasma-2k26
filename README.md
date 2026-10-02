# PLASMA 2K26 — JNNCE Techfest Website

Public site + coordinator admin panel + database + PDF rulebooks + payment (UPI) + QR codes.
No coding needed to run it. Follow the parts **in order**: A (database) → B (your files) → C (deploy) → D (test).

## What is in this folder

```
plasma-2k26/
├── index.html            Public website (events, registration, payment, venue, map, QR)
├── admin.html            Coordinator panel (login required)  ->  yoursite.vercel.app/admin.html
├── qr.html               Makes a QR code + link for every event's registration
├── supabase_setup.sql    ONE file that builds the whole database
├── README.md             This guide
├── rulebooks/            7 PDF rulebooks (one per event)
├── logos/                put jnnce.png and vtu.png here
├── images/events/        optional photo per event (see the README.txt inside)
├── images/gallery/       8 real fest photos already included (1.jpg ... 8.jpg)
├── images/about/         4 photos already included, shown inline in the About section
├── images/instagram/     instagram-qr.png - QR that opens @plasma_2k26
└── upi-qr.png            (you add this) your UPI payment QR image
```

Accounts needed (all free): **Supabase** (database) and **Vercel** (hosting). GitHub is optional.

---

## PART A — Create the database (Supabase)

**A1. Create a project**
1. Go to https://supabase.com and sign in.
2. Click **New project**. Name it `plasma-2k26`, set a database password (save it somewhere), choose the region nearest you (e.g. *Mumbai / ap-south-1*), click **Create**. Wait 1–2 minutes.

**A2. Build all tables in one go**
1. Left menu → **SQL Editor** → **New query**.
2. Open `supabase_setup.sql` from this folder, copy **everything**, paste, click **Run**.
3. You should see *"Success. No rows returned"*. That created the events and registrations tables, the security rules, and your 7 events for the 27 & 28 October 2026 fest - Robo Race, Sumo War, Line Follower, Robo Tug of War, H/W Hackathon + PCB Design, Robo Climbing, Robo Soccer - with fees ₹200 / ₹400 and rulebook links. If you had already run an older version of this file, it safely renames "Hardware Hackathon" to the new name and hides (does not delete) "RC Car Race" and "Paper Presentation", which are no longer in this year's lineup.
4. It is safe to run the file again any time; it never deletes your data.
5. Check: left menu → **Table Editor** → `events` should list 7 rows.

**A3. Create coordinator logins** (head coordinator does this)
1. Left menu → **Authentication** → **Users** → **Add user** → **Create new user**.
2. Enter the coordinator's **email** and a **password**, keep **Auto Confirm User** ticked, click **Create user**.
3. Repeat for each coordinator (include yourself).

**A4. Allow those emails into the admin panel**
1. SQL Editor → New query, paste this with the real emails (same emails as A3), Run:
   ```sql
   insert into public.admins (email) values
     ('head.coordinator@gmail.com'),
     ('coordinator2@gmail.com')
   on conflict do nothing;
   ```
2. Only emails in this list can open the admin panel. To remove someone later:
   `delete from public.admins where email = 'coordinator2@gmail.com';`

**A5. Stop strangers creating accounts**
Authentication → **Sign In / Providers** (wording may vary slightly) → under *User Signups*, turn **OFF** "Allow new users to sign up". Coordinators are added only by you in A3.

**A6. Copy your two connection values**
1. Left menu → **Project Settings** (gear) → **API Keys** (or **Data API**).
2. Note the **Project URL** (looks like `https://abcdefgh.supabase.co`).
3. Note the **anon public** key (long text starting `eyJ…`, on the *Legacy API Keys* tab) **or** the **Publishable key** (starts `sb_publishable_…`). Either works in this site.
4. Never use the `service_role` / `secret` key anywhere in these files.

> The three HTML files currently contain the URL and key of the project you were already using. **If that is the same project you just set up, do nothing.** If you created a new project, do Part B step 1.
> Supabase is retiring the old `eyJ…` anon keys by the end of 2026, so if the dashboard offers a Publishable key, prefer that one.

---

## PART B — Personalise your files

**B1. (Only if your Supabase project is different)** Open `index.html`, `admin.html` and `qr.html` in Notepad / VS Code. In **each** file search for `supabase.co`. You will find a line like
`var SB_URL="https://....supabase.co",SB_KEY="eyJ...";` (in `admin.html`: `var SB="...",KEY="...";`).
Replace the URL and the key with yours from A6. Save all three.

**B2. Your UPI payment**
1. Open `index.html`, search for `UPI_VPA`. Change `your-upi-id@bank` to your real UPI ID (e.g. `plasma2k26@okhdfcbank`). Keep the quotes.
2. Save your payment QR image as **`upi-qr.png`** in the main folder (next to `index.html`).
3. Until you set a real UPI ID, the "Pay via UPI App" button stays hidden and only the QR + UTR box show.
4. The button opens GPay/PhonePe/Paytm **on phones only**. On laptops people scan the QR.
5. Payments are not verified automatically. Participants type their UPI transaction ID (UTR); a coordinator checks it against the bank statement (the admin panel shows every UTR).

**B3. Logos** — put `jnnce.png` and `vtu.png` in the `logos/` folder (exact lowercase names). VTU shows top-left, JNNCE top-right. Until then, text badges show instead.

**B4. Photos** — the About section and the "Glimpses of PLASMA" gallery already have 8 real photos from a past fest, plus your Instagram QR - no action needed. Per-event photos are still optional: drop one in `images/events/` named after the event (e.g. `robo-race.jpg`) and it replaces that card's icon automatically. Details are in the README.txt inside the folder.

**B5. Dates, venue, prizes** — do NOT edit code for these. After deploying, use the admin panel (Part E).

---

## PART C — Deploy on Vercel

Pick **one** option.

### Option 1 — Drag and drop (fastest, no installs)
1. Go to **https://vercel.com/drop** and sign in.
2. Drag the whole **`plasma-2k26`** folder (or a .zip of it) onto the page.
3. Choose your team, name the project (e.g. `plasma-2k26`), click **Deploy**.
4. You get a live URL like `https://plasma-2k26.vercel.app`.
Note: every drop creates a *new* project, so for later updates use Option 2 or 3 to keep the same URL.

### Option 2 — GitHub → Vercel (best for updates)
1. Create an empty repo at https://github.com/new (name `plasma-2k26`, no README).
2. In a terminal, inside the `plasma-2k26` folder:
   ```bash
   git init
   git add .
   git commit -m "PLASMA 2K26 site"
   git branch -M main
   git remote add origin https://github.com/YOUR-USERNAME/plasma-2k26.git
   git push -u origin main
   ```
3. Go to https://vercel.com/new → **Import** your repo.
4. **Framework Preset: Other.** Leave *Build Command* and *Output Directory* empty. Click **Deploy**.
5. From now on, every `git push` updates the live site automatically.

### Option 3 — Vercel CLI
```bash
npm i -g vercel
cd plasma-2k26
vercel --prod
```
Answer the prompts: set up and deploy → **Y**; link to existing project → **N**; project name → `plasma-2k26`; directory → `./`; override settings → **N**.

Deploy the **contents of the `plasma-2k26` folder** so that `index.html` sits at the top level (not inside another folder).

---

## PART D — Test it (2 minutes)

Open your live URL and check each line:

- [ ] Logos/badges at the very top (VTU left, JNNCE right); college name in the middle.
- [ ] **About The College** section appears above Events, with 4 campus photos.
- [ ] **Events** section shows 7 cards, each with fee and a **Rulebook** button that opens a PDF.
- [ ] Click a card → the registration form scrolls into view with that event selected and the fee shown.
- [ ] Submit a test registration → "Registered! See you at PLASMA 2K26."
- [ ] Open `yoursite/admin.html`, log in with a coordinator email → the events table and your test registration appear.
- [ ] Bottom of page: address (Savalanga Road, Navule, Shimoga 577204), map, coordinator numbers.
- [ ] Open `yoursite/qr.html` → a QR + link for every event.
- [ ] Bottom of the home page: a "Follow Us on Instagram" section with a working QR and a button to @plasma_2k26.

If anything is wrong, the red message in the Events section says why. See the troubleshooting table below.

---

## PART E — Running the fest (day-to-day)

| I want to… | Do this |
|---|---|
| Add / edit an event, date, time, venue, prize, fee, coordinator name & phone, rulebook link | Open `/admin.html` → log in → fill the form → **Save event**. Live instantly, no redeploy. |
| Announce the schedule | Edit each event and fill *Date*, *Start*, *End*, *Venue*. It moves from "Schedule TBA" into a Day tab automatically. |
| Close registration / hide an event | Edit it and untick **Registration open** / **Published**. |
| See who registered and their UTR | Admin → **Registrations** tab. **Export CSV** downloads it (opens in Excel). |
| Give a poster QR for one event | Open `/qr.html` → **Download PNG** on that event. |
| Update the Instagram link or QR | Search `index.html` for `instagram.com/plasma_2k26` (the link) and `images/instagram/instagram-qr.png` (replace that file to change the QR image). |
| Replace a rulebook | Overwrite the file in `rulebooks/` with the same name and redeploy (Option 2/3). |
| Add a coordinator | Repeat A3 + A4. |
| Remove a coordinator | `delete from public.admins where email='…';` and delete the user in Authentication → Users. |
| Change the "Prize Pool" number | It is calculated automatically from the numeric prizes you enter on each event. |

---

## Troubleshooting

| What you see | Cause and fix |
|---|---|
| Red text: **"No published events found…"** | Table is empty or events are hidden. Re-run `supabase_setup.sql`. |
| Red text: **"Could not load events (error 401…)"** | Wrong or expired key in `index.html`. Redo A6 + B1. |
| Red text: **"Could not load events (error 404…)"** | Tables not created. Run `supabase_setup.sql` (A2). |
| Red text: **"Could not reach the database"** | Wrong Project URL, or the free Supabase project is **paused** (Supabase pauses idle free projects after about a week). Open supabase.com → your project → **Restore**. |
| Admin: **"This account is not an admin"** | Email is not in the admins list (A4), or has a typo. |
| Admin: **"Login failed"** | Wrong password, or the user was created without *Auto Confirm* (Authentication → Users → confirm it). |
| Admin: **"Save failed (400): Could not find the '…' column"** | Database is missing a column. Re-run `supabase_setup.sql`; it adds any missing column. |
| Admin: **"Save failed (403)"** / permission denied | Your login email is not in the admins list (A4). |
| Admin: **"Session expired"** | Logged in more than an hour ago. Log in again. |
| Rulebook button gives *404* | The `rulebooks/` folder was not deployed next to `index.html`. |
| Logos show "JNNCE" / "VTU" text | `logos/jnnce.png` / `logos/vtu.png` missing or misnamed (must be lowercase). |
| "Registration failed" for someone | They probably already registered for that event with the same email. |

## Security notes
- The key inside the HTML files is meant to be public. The database rules (in `supabase_setup.sql`) decide what visitors can do: read published events, submit a registration, nothing else. Only admins can see registrations.
- `admin.html` is reachable by anyone, but it shows nothing without a coordinator login.
- Registration details include names, emails and phone numbers: share the CSV only with coordinators.
