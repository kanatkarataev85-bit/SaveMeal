# SaveMeal mobile app

This Flutter application is the current SaveMeal customer app for Android and
iOS. Run it from the `mobile` directory; `npm run dev` at the repository root
starts the separate backend API and does not launch a website.

The app opens with an animated SaveMeal splash screen and then shows a
mobile-first food catalog with full-width highlighted offers and a two-column
food grid. Search, category filters, language controls, and bottom navigation
are intentionally omitted. Quantities start at zero; a single fixed bottom
**Buy** panel appears after a portion is selected. It stays in place while
scrolling and submits all selected food items together.

## Run on an Android phone or emulator

From the repository root in PowerShell:

```powershell
Push-Location mobile
flutter pub get
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
Pop-Location
```

Connect an Android phone with USB debugging enabled or start an Android
emulator before running `flutter run`.

Before registering users, run the SQL files in `supabase/migrations` in
timestamp order in the Supabase SQL Editor and enable phone authentication
(including an SMS provider if phone confirmation is enabled). The app creates
phone/password accounts; a database trigger creates each user's row in
`public.profilespro`. The app uses the project's public anon/publishable key
and row-level security. Never put a `service_role` or secret key in the app.

## Build an Android preview APK

```powershell
Push-Location mobile
flutter build apk --debug
Pop-Location
```

The APK is created at `mobile\build\app\outputs\flutter-apk\app-debug.apk`.

## Prototype limitations

- The catalog uses the local `previewListings` sample data. No real listings,
  prices, orders, or platform statistics are loaded in this phase.
- Stock-limited quantities and the in-memory selections are UI-only
  interactions. Selecting **Buy** opens one
  combined order and sign-up screen with pickup/delivery selection. Pickup
  shows an explicitly marked demo cafe address; delivery requires an address.
  Accounts can be created or authenticated when Supabase is configured, but no
  order or payment is submitted.
- Registration and login use Supabase phone authentication when
  `SUPABASE_URL` and `SUPABASE_ANON_KEY` are provided with `--dart-define`.
  New accounts are saved to `public.profilespro`; phone verification is
  supported when enabled in Supabase.
- The SQL migrations must be applied to the Supabase project separately.
  The app intentionally does not include project keys.
- No order is submitted or saved. Payment-provider integration is not
  configured, and order history stays empty.
- Food photography is loaded from Unsplash over HTTPS and cached on device;
  placeholder imagery is shown when a photo cannot be loaded.
- The current interface is displayed in Russian.
