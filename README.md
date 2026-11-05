# SILLAGE

A luxury fragrance storefront with Supabase email/password authentication.

## Supabase setup

1. Create a Supabase project.
2. In **Project Settings → API**, copy the Project URL and the publishable
   (anon) key.
3. Configure **Authentication → URL Configuration** with the app's redirect
   URL if using OAuth or email confirmation.
4. To enable Google sign-in, configure Google as a Supabase Auth provider and
   set its client credentials in the Supabase dashboard.
5. Run the app from the `myapp` directory with your project values supplied at
   build/run time:

   ```text
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

The storefront entrypoint is [`lib/main.dart`](./lib/main.dart), which is what
`flutter run` uses by default. Supabase is initialized only when both values are
provided; otherwise the app displays setup instructions. Use the project URL
and publishable/anon key from Supabase **Project Settings > API**. Never put a
Supabase `service_role` key in the client app.

The separate [`lib/tarsi_main.dart`](./lib/tarsi_main.dart) entrypoint runs the
Tarsi plan screen when explicitly selected with
`flutter run -t lib/tarsi_main.dart`.

## Authentication behavior

- When signed out, the storefront shows the account screen. Choose **CREATE
  ACCOUNT**, enter a name, email, and password, then confirm the email if
  Supabase requires confirmation.
- Choose **LOG IN** to sign in with the created account. A successful sign-up
  or sign-in establishes a Supabase session and the app opens the storefront.
- The app listens to Supabase auth state changes. **Log out** calls
  `signOut()` and returns to the account screen; signing in again restores the
  authenticated storefront.
- Account creation saves the full name in the user's `full_name` metadata.
- Email confirmation behavior follows the Supabase project's Auth settings.
  Disable **Confirm email** in Supabase Auth if new users should enter the
  dashboard immediately; otherwise they must confirm their email before a
  session is created.
- The signed-in storefront greets the customer by name and includes a log out
  action.
- Supabase persists and restores the auth session between app launches.
- The signed-in role is fetched from that user's `profiles` row. Signing out
  returns to the account screen; signing in again fetches the profile role
  afresh and updates admin controls.

## Product administration

1. Run [`supabase/setup.sql`](./supabase/setup.sql) in the Supabase SQL Editor.
   This creates/backfills profiles, creates the products table, enables
   row-level security, and loads the initial fragrance collection.
2. Create the administrator account with **CREATE ACCOUNT** in the app, then
   confirm its email if email confirmation is enabled. This creates a regular
   customer account first; the app deliberately does not let users promote
   themselves to admin.
3. Open [`supabase/promote_admin.sql`](./supabase/promote_admin.sql), set
   either `target_email` or `target_user_id` (set the other to `NULL`), and run
   the script in the Supabase SQL Editor. It reports the promoted user ID.
4. Sign out and sign back in to refresh the account's role. The **Manage
   products** control will appear. From there the administrator can add,
   edit, and remove products. Rerun `supabase/setup.sql` for existing projects
   to create/backfill profiles and install the profile-based admin policies.

The `profiles` table is created and seeded by `setup.sql`; a database trigger
creates a customer profile for each new account. The trusted promotion script
updates both `profiles.role` and `auth.users` app metadata. Product row-level
security checks `profiles.role` for every insert, update, and delete. Clients
can read only their own profile and cannot change roles. Never put a Supabase
`service_role` key in the app.
