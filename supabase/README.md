# Supabase — Insha Allah Traders ERP

PostgreSQL schema, RLS, storage, and seed for Phase 1.

## Layout

```
supabase/
├── config.toml
├── seed.sql
├── MIGRATIONS.md
├── README.md          ← this file
└── migrations/
    ├── 00001_extensions_and_enums.sql
    ├── 00002_core_auth_company.sql
    ├── 00003_masters.sql
    ├── 00004_sales.sql
    ├── 00005_purchase_expenses.sql
    ├── 00006_inventory.sql
    ├── 00007_manufacturing.sql
    ├── 00008_tooling_quality.sql
    ├── 00009_documents_audit.sql
    ├── 00010_functions_triggers.sql
    ├── 00011_rls.sql
    └── 00012_storage.sql
```

## Apply migrations

### Local

```bash
npx supabase start
npx supabase db reset          # runs migrations 00001–00012 then seed.sql
```

### Remote (linked project)

```bash
npx supabase link --project-ref <YOUR_PROJECT_REF>
npx supabase db push           # applies pending migrations
```

Then run `seed.sql` once (SQL Editor or `psql`), unless you use a reset workflow that already seeds.

See [MIGRATIONS.md](./MIGRATIONS.md) for table map and conventions.

## Super Admin bootstrap

Seed creates **company**, **roles**, **permissions**, **warehouses**, **UOMs**, and **expense categories**. It does **not** create an Auth user (that lives in `auth.users`).

1. Create a user in Dashboard → Authentication → Users (or invite/signup).
2. Copy the user UUID.
3. Attach Super Admin:

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

Signup automatically creates a `profiles` row (`profiles.id = auth.users.id`) via trigger.

## Seed notes

| Item | Detail |
|------|--------|
| Company | Insha Allah Traders, Partnership, TN, prefix **IAT** |
| GSTIN/PAN | Left empty — set in Settings before production |
| GST rates | Empty (no hardcoded tax truth). Optional sample rows commented in `seed.sql` |
| Warehouses | RM, WIP, FG, Tool Room, Scrap |
| Roles | Super Admin, Partner, Admin, Accountant, Sales, Purchase, Store Manager, Production Manager, Quality Manager, Viewer |
| Numbering | `next_document_number()` → e.g. `IAT/2026-27/INV/0001` (FY Apr–Mar IST) |

Disclaimer: this system is not a substitute for a CA or tax professional.

## Storage buckets

| Bucket | Use |
|--------|-----|
| `company-assets` | Logo, signature |
| `documents` | General attachments |
| `expense-receipts` | Expense scans |
| `invoice-pdfs` | Generated invoice PDFs |

Object paths must start with `{company_id}/...` for RLS.
