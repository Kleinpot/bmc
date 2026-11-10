# Sillage

Sillage is a Flutter fragrance storefront app with Supabase authentication, product browsing, cart checkout, and Xendit payment integration.

This project is built for a luxury perfume storefront where users can:
- sign up or log in with email/password
- browse fragrance products
- add items to a bag
- enter delivery details
- pay through Xendit
- return to the app after payment processing

## App flow overview

1. User opens the app.
2. If signed out, they land on the authentication screen.
3. After login, the app checks the user's role from the `profiles` table.
4. Customers see the storefront and can shop.
5. Admin users can access product management.
6. Checkout creates a Xendit invoice.
7. After payment, the browser redirects back to the app and the app verifies the invoice status.
8. User returns to the dashboard/home flow after payment processing.

## Prerequisites

Before running the app, install:
- Flutter SDK 3.13 or newer
- Dart SDK bundled with Flutter
- Android Studio / Xcode / VS Code with Flutter extensions
- Supabase CLI (for edge functions and secrets)
- A Supabase project
- A Xendit account (for live or sandbox testing)

## Step 1: Install project dependencies

Open a terminal in the project root and run:

```bash
flutter pub get
```

If Flutter is not installed or not recognized, install Flutter and restart the terminal.

## Step 2: Configure Supabase

### 2.1 Create a Supabase project

1. Go to Supabase.
2. Create a new project.
3. Copy:
   - Project URL
   - Publishable/anon key

### 2.2 Update the app credentials

Open `lib/main.dart` and update the Supabase initialization values:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  publishableKey: 'YOUR_SUPABASE_PUBLISHABLE_KEY',
);
```

If you are using a different project or environment, replace the values here.

### 2.3 Run the SQL setup

In the Supabase SQL Editor, run:
- `supabase/setup.sql`
- `supabase/promote_admin.sql` only when you want to promote an admin account

This sets up:
- `profiles` table
- product table and sample data
- auth/user role support
- admin policies
- necessary product storage setup

### 2.4 Create admin account

1. Run the app.
2. Sign up with an email/password.
3. If email confirmation is enabled, confirm the email first.
4. Run the admin promotion script with the target user email or ID.
5. Sign out and sign back in.

The app will then show the product management controls for admin users.

## Step 3: Configure Xendit

### 3.1 Set up Xendit secret

In your Supabase project, set the secret:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set XENDIT_SECRET_KEY=your_xendit_secret_key
```

### 3.2 Deploy Supabase functions

From the project root:

```bash
supabase functions deploy xendit-payment
supabase functions deploy xendit-return
```

The app relies on these functions:
- `supabase/functions/xendit-payment/index.ts`
- `supabase/functions/xendit-return/index.ts`

### 3.3 Payment flow behavior

The checkout flow does the following:
- builds a cart and item payload
- calls the `xendit-payment` Supabase function
- creates a Xendit invoice
- opens the invoice URL in the browser
- waits for the user to pay
- when returning to the app, it verifies the invoice status again
- sends the user back to the dashboard/home screen after processing

## Step 4: Run the app

Run the app from the root folder:

```bash
flutter run
```

If you want to run the alternate app entry screen:

```bash
flutter run -t lib/tarsi_main.dart
```

## Step 5: Test the storefront

### Customer side
- Create an account
- Sign in
- Browse products
- Add fragrances to the bag
- Proceed to checkout
- Select Xendit payment
- Complete the payment in the browser
- Return to the app

### Admin side
- Promote a user to admin
- Sign in again
- Use the admin product management tools

## Project structure

```text
.
├── lib/
│   ├── main.dart
│   ├── tarsi_main.dart
│   └── tarsi/
├── supabase/
│   ├── setup.sql
│   ├── promote_admin.sql
│   └── functions/
│       ├── xendit-payment/
│       └── xendit-return/
├── test/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── android/ ios/ web/ linux/ macos/ windows/
```

## Important notes

- Do not expose the Xendit secret key in the Flutter client.
- Keep secrets only in Supabase function environment variables.
- The app expects a valid Supabase URL and publishable key before it can authenticate.
- The redirect page verifies the payment status and then returns the user to the dashboard/home flow.

## Troubleshooting

### App won't start
- run `flutter pub get`
- check that the Flutter SDK is installed correctly
- confirm `lib/main.dart` contains the correct Supabase URL and key

### Login fails
- verify the Supabase project is created correctly
- confirm auth settings in Supabase are configured
- confirm email/password auth is enabled

### Payment fails
- confirm `XENDIT_SECRET_KEY` is set in Supabase
- check that the functions were deployed
- confirm the Xendit sandbox account is enabled
- verify the redirect URL is permitted

## License

This project is intended for internal or project-based use unless otherwise specified.
