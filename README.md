# Sela Business Intelligence Learning Hub — prototype

## What this package contains
- `index.html` — responsive website prototype.
- `supabase-schema.sql` — starter database schema for a production backend.
- This README — deployment and security notes.

## Important: this is a prototype, not a live secure learning platform
The demo uses browser localStorage and demonstration accounts. Its changes stay in that browser and are not shared with other students. The demo credentials are intentionally public. Do not use real student data, passwords, private files, or live classes with this version.

Demo login:
- Administrator: `admin@sela.demo`
- Student: `student@sela.demo`
- Password for either: `SelaDemo2026!`

## Preview locally
Open `index.html` in a modern browser. On mobile, open the same file in your browser if your file manager supports it.

## Publish the static prototype on GitHub Pages
1. Create a new GitHub repository, for example `sela-learning-hub`.
2. Upload `index.html` to the repository root.
3. In the repository, open **Settings → Pages**.
4. Select deployment from the `main` branch and `/ (root)`, then save.
5. Wait for GitHub Pages to provide the site URL.

GitHub Pages hosts only the front end. It does not make the demo sign-in secure or create a shared database.

## Production setup before real students use it
1. Create a Supabase project.
2. Run `supabase-schema.sql` in the Supabase SQL Editor.
3. Configure Supabase Auth for student and administrator accounts.
4. Add Row Level Security policies and test that students can only access their own records and enrolled course content.
5. Use Supabase Storage buckets with access policies for lesson files and assignment submissions.
6. Connect the front end to Supabase using the public project URL and anon/publishable key only. Never put a service-role key or database password in browser code.
7. Create the first administrator securely; do not allow public users to self-assign an administrator role.
8. Test on Android phones and slow mobile connections.

The SQL is a starting point, not a complete production security audit. Policies must be reviewed and tested before real student data is stored.
