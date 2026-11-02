# SaveMeal MVP

SaveMeal is a mobile-first food rescue application for Bishkek, Kyrgyzstan.

## Current app: Flutter for Android and iOS

The current customer app is in [`mobile/`](./mobile/README.md). In VS Code,
select **SaveMeal (Flutter)** in Run and Debug, or run `flutter run` from the
`mobile` directory. The app uses local sample listings; registration and login
can connect to Supabase and save user profiles to `public.profilespro` when
configured as described in the mobile README.

## Backend API (separate from the mobile app)

The Express + SQLite API remains in this workspace for possible future
integration. It is not connected to the Flutter app or Supabase. Running
`npm run dev` starts the API only; it does not launch a website.

### Backend stack

- Backend: Express, TypeScript, SQLite via better-sqlite3
- Auth: JWT stored in an httpOnly cookie (Bearer token fallback for tests)
- Validation: Zod schemas on every write endpoint

### Run the API on Windows PowerShell

1. Open PowerShell in the project root.
2. Install dependencies:
   ```powershell
   npm install
   ```
3. Create a local environment file:
   ```powershell
   Copy-Item .env.example .env
   ```
4. Start the API in development mode:
   ```powershell
   npm run dev
   ```
## API endpoints

Auth:
- `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`

Catalog:
- `GET /api/listings` — server-side filters: `q`, `category`, `serviceType`, `maxPrice`, `available`, `sort` (`new | price_asc | price_desc | discount`). Returns `{ items, meta }`.
- `GET /api/listings/:id`
- `POST /api/listings` — restaurant only, new listing starts as `pending_review`

Orders:
- `POST /api/orders` — customer only; delivery fee is added server-side, donations cannot be ordered
- `GET /api/orders/my`
- `PATCH /api/orders/:id/status` — role-aware state machine, portions are returned on cancel/refund

Donations:
- `GET /api/donations`
- `POST /api/donations/request` — approved organizations only
- `GET /api/donations/requests/my` — organization view
- `GET /api/donations/requests/received` — restaurant view
- `POST /api/donations/requests/:id/status` — pending → approved/rejected → collected → completed

Complaints:
- `POST /api/complaints` — about an order or a listing

Admin (administrator only):
- `GET /api/admin/overview`
- `GET /api/admin/listings`
- `POST /api/admin/listings/moderate` — `approve` / `reject` with a mandatory reason
- `POST /api/admin/verify-user`
- `POST /api/admin/complaints/:id/status`

Public:
- `GET /api/health`
- `GET /api/stats` — real platform metrics used by the landing page

## Security notes

- Anonymous listings never expose the real restaurant name to shoppers or other restaurants; only the owner and administrators see it.
- Only `published` listings are visible to guests, customers and organizations.
- Order status changes are validated against an explicit transition table and the caller's role.
- Demo credentials endpoint (`/api/demo/seed-info`) is disabled outside development.
- All admin actions are written to the `audit_logs` table.

## Demo data

Demo accounts are seeded automatically in development mode:

- customer@savemeal.kg / Customer123!
- restaurant@savemeal.kg / Restaurant123!
- org@savemeal.kg / Org123456!
- admin@savemeal.kg / Admin123!

Demo credentials are intentionally included for development and hackathon use only.

## Validation

Run the API tests:

```powershell
npm test
```

Run the full frontend + server build:

```powershell
npm run build
npm start        # serves API and the built frontend on http://localhost:4000
```

## API status

Implemented:

- Secure registration and login with role-based access control
- Restaurant listing creation form with moderation queue
- Admin panel: user verification, listing approval/rejection with reasons, complaint handling
- Catalog with real server-side filtering and sorting
- Order lifecycle with validated state transitions and inventory rollback
- Donation workflow: organization request → restaurant approval → pickup → completion
- Real platform statistics from the API on the landing page
- Complaints for both orders and listings
- Toasts, skeleton loaders, empty states, footer, 404 page

Remaining as future work:

- Real image upload (currently URL-based)
- Payments integration
- Production deployment and hardening

## Demo script

1. Open http://localhost:5173 — landing page shows live stats from `/api/stats`.
2. Log in as `customer@savemeal.kg`, open the catalog, apply filters, order an item with delivery and check the transparent price breakdown.
3. Log in as `restaurant@savemeal.kg`, create a new listing (it goes to moderation), then move an order through confirm → prepare → ready → complete.
4. Log in as `admin@savemeal.kg`, open the moderation panel and approve the pending listing.
5. Log in as `org@savemeal.kg`, send a donation request, then switch back to the restaurant to approve it.
