# Insha Allah Traders

Public company website plus multi-tenant React + Supabase ERP for **Insha Allah Traders** (Tamil Nadu sheet-metal manufacturing). Visitors use `/` for the manufacturing profile; staff enter the ERP only via `/login` → `/app`. Phase 1 delivers foundation: full database schema/RLS, auth + RBAC, company settings shell, and a compiling app.

This product assists bookkeeping and GST-aware invoicing. **It is not a substitute for a Chartered Accountant or tax professional.** GST rates are admin-configurable; there is **no GST filing API**.

## Stack

- Vite + React 19 + TypeScript
- Tailwind CSS + shadcn/ui
- React Router + TanStack Query + React Hook Form + Zod
- Supabase (Auth, Postgres, Storage, RLS)

## Prerequisites

- Node.js 20+
- npm
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`npx supabase` is fine)
- A Supabase project (local or cloud)

## 1. Install dependencies

```bash
npm install
```

## 2. Create / link a Supabase project

### Cloud

1. Create a project at [supabase.com](https://supabase.com).
2. Copy **Project URL** and **anon public** key (Settings → API).
3. Link the CLI:

```bash
npx supabase login
npx supabase link --project-ref <YOUR_PROJECT_REF>
```

### Local

```bash
npx supabase start
```

Local API URL and anon key are printed by `supabase start` (also in `supabase status`).

## 3. Apply migrations

Migrations live in `supabase/migrations/` (`00001`–`00012`). Details: [supabase/MIGRATIONS.md](./supabase/MIGRATIONS.md).

### Local (migrations + seed)

```bash
npx supabase db reset
```

### Remote (linked project)

```bash
npx supabase db push
```

Then run seed once (SQL Editor or `psql`) if you did not reset:

```bash
# example with psql connection string from the dashboard
psql "$DATABASE_URL" -f supabase/seed.sql
```

More detail: [supabase/README.md](./supabase/README.md).

## 4. Environment variables

Copy the example file and fill in values. **Never put the service-role key in the frontend.**

```bash
cp .env.example .env.local
```

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

## 5. Auth redirect URLs

In Supabase Dashboard → Authentication → URL configuration, add:

- Site URL: `http://localhost:5173` (or your deploy URL)
- Redirect URLs:
  - `http://localhost:5173/reset-password`
  - `http://localhost:5173/**` (optional for local)

Password reset emails use `{origin}/reset-password`.

## 6. Run the app

```bash
npm run dev
```

Build check:

```bash
npm run build
```

## 7. GitHub Pages

The public site (and ERP UI) deploy to **GitHub Pages** from `dist/` via Actions — not from the branch source tree.

**Live URL:** [https://Yath-MCA.github.io/insha-allah-traders/](https://Yath-MCA.github.io/insha-allah-traders/)

### One-time repo setup

1. **Settings → Pages → Build and deployment → Source:** **GitHub Actions** (not “Deploy from a branch”).
2. **Settings → Secrets and variables → Actions** — add:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
3. **Supabase → Authentication → URL configuration** — add redirect URLs for the Pages origin, for example:
   - Site URL (or additional): `https://Yath-MCA.github.io/insha-allah-traders`
   - Redirect URLs:
     - `https://Yath-MCA.github.io/insha-allah-traders/**`
     - `https://Yath-MCA.github.io/insha-allah-traders/reset-password`

Vite `base` and React Router `basename` are set to `/insha-allah-traders/`. Pushing to `main` runs [`.github/workflows/deploy-pages.yml`](./.github/workflows/deploy-pages.yml) (build + `404.html` SPA fallback + deploy). You can also run the workflow manually (**Actions → Deploy GitHub Pages → Run workflow**).

`/app` login on the live site needs the secrets above and matching Auth redirect URLs; without them the UI may load but Supabase auth will fail.

## 8. First user + Super Admin bootstrap

Seed creates company, roles, permissions, warehouses, UOMs, etc. It does **not** create an Auth user.

1. Create a user: Dashboard → Authentication → Users (or sign-up if enabled).
2. Copy the user UUID.
3. Attach Super Admin (SQL Editor). Full script: [supabase/README.md](./supabase/README.md#super-admin-bootstrap).

```sql
INSERT INTO public.user_roles (user_id, company_id, role_id)
VALUES (
  'USER_UUID',
  'a0000000-0000-4000-8000-000000000001',  -- Insha Allah Traders
  'b0000000-0000-4000-8000-000000000001'   -- super_admin
)
ON CONFLICT (user_id, company_id, role_id) DO UPDATE
  SET is_active = true, deleted_at = NULL;

UPDATE public.profiles
SET default_company_id = 'a0000000-0000-4000-8000-000000000001'
WHERE id = 'USER_UUID';
```

Then sign in at `/login` (lands on `/app`). Additional users: create in Auth, then **Settings → Users & roles** (paste UUID + assign role).

## Development phases

Phase 1 (foundation) is implemented in this repo. **Phases 2–9** are build briefs you can paste into Cursor:

**[docs/phase-prompts/](./docs/phase-prompts/)** — index + one markdown prompt per phase (masters → sales → purchase → inventory → manufacturing → tooling/quality → reports/docs → hardening).

Use them in order; each prompt lists tables, routes, components, RBAC, and acceptance criteria. Prefer UI/services on the existing schema; avoid rewriting migrations unless a real gap appears.

## Routes

### Public company website (no login)

| Route | Notes |
|-------|--------|
| `/` | Brand-first home — manufacturing hero, enquire + Staff Login CTAs |
| `/capabilities` | Full 16-item manufacturing catalogue (grouped) |
| `/about` | Partnership firm, Tamil Nadu industrial context |
| `/contact` | Phone / email / address (optional `VITE_PUBLIC_*` env overrides) |

Staff Login in the public header goes to `/login`.

### ERP auth entry

| Route | Notes |
|-------|--------|
| `/login` | Supabase Auth — post-login → `/app` (or deep link under `/app/*`) |
| `/forgot-password`, `/reset-password` | Password reset flow |

Unauthenticated `/app/*` redirects to `/login`. Authenticated `/login` redirects to `/app`.

### ERP (authenticated, under `/app`)

| Route | Notes |
|-------|--------|
| `/app` | Dashboard placeholder |
| `/app/profile` | User profile |
| `/app/settings/company` | Company master, banks, logo/signature |
| `/app/settings/partners` | Partner CRUD |
| `/app/settings/users` | List members, assign roles |
| `/app/settings/financial-year` | Apr–Mar FY list / select current |
| `/app/audit-logs` | Permission-gated read-only list |
| Other `/app/...` nav items | Coming Soon (Phase N) stubs — see [docs/phase-prompts](./docs/phase-prompts/) |

## Backup notes

- **Dashboard:** Project → Database → Backups (plan-dependent).
- **Logical dump:** use the database connection string from Settings → Database:

```bash
pg_dump "$DATABASE_URL" --format=custom --file=iat-$(date +%Y%m%d).dump
```

- Keep Storage bucket contents (`company-assets`, `documents`, etc.) in your backup plan separately if needed.
- Prefer regular dumps before large migrations or production cutovers.

## Project layout

```
src/
  components/     # ui, layout, shared
  features/       # website, auth, company, dashboard, audit
  services/       # Supabase data access
  constants/      # permissions, navigation (ERP hrefs under /app)
  lib/            # supabase client, formatters
docs/
  phase-prompts/  # Phase 2–9 agent prompts
supabase/
  migrations/     # full ERP schema
  seed.sql
```

## License / ownership

Private project for Insha Allah Traders operations.
