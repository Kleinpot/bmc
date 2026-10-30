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
5. Run the app with the project values supplied at build/run time:

   ```text
   flutter pub get
   flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

The app intentionally uses placeholders when those values are not supplied and
shows a setup message instead of attempting to initialize an invalid client.
Never put a Supabase `service_role` key in the client app.

## Authentication behavior

- Supabase auth state automatically selects the sign-in screen or the
  authenticated storefront/dashboard.
- Account creation saves the full name in the user's `full_name` metadata.
- Email confirmation behavior follows the Supabase project's Auth settings.
  Disable **Confirm email** in Supabase Auth if new users should enter the
  dashboard immediately; otherwise they must confirm their email before a
  session is created.
- The signed-in storefront greets the customer by name and includes a log out
  action.
- Supabase persists and restores the auth session between app launches.
