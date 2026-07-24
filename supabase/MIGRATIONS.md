# Migrations reference

Ordered SQL migrations for the Phase 1 ERP schema. Filenames use a numeric prefix (`00001`–`00012`) so apply order is stable under Supabase CLI.

## Files

| # | File | Purpose |
|---|------|---------|
| 1 | `00001_extensions_and_enums.sql` | `pgcrypto`, `pg_trgm`; shared enums |
| 2 | `00002_core_auth_company.sql` | companies, profiles, roles, permissions, user_roles, settings, banks, partners, FY, document_sequences |
| 3 | `00003_masters.sql` | units, categories, gst_rates, products, customers, vendors, warehouses, locations, expense_categories |
| 4 | `00004_sales.sql` | quotations → SO → DC → invoices, credit/debit notes, customer payments |
| 5 | `00005_purchase_expenses.sql` | PR/PO/GRN/purchase invoices, vendor payments, expenses |
| 6 | `00006_inventory.sql` | balances, inventory_transactions, adjustments, transfers |
| 7 | `00007_manufacturing.sql` | BOM, routes, work orders, production |
| 8 | `00008_tooling_quality.sql` | tools, maintenance, inspections, NCRs |
| 9 | `00009_documents_audit.sql` | documents metadata, audit_logs |
| 10 | `00010_functions_triggers.sql` | updated_at, audit fields, signup profile, FY helpers, `next_document_number`, GST split, issued-doc guards, audit writers |
| 11 | `00011_rls.sql` | RLS + `get_user_company_ids` / `has_permission` |
| 12 | `00012_storage.sql` | buckets + storage RLS |

## Conventions

- UUID primary keys (`gen_random_uuid()`)
- `company_id` on all business tables
- `created_at` / `updated_at` (`timestamptz`); display as Asia/Kolkata in the app
- `created_by` / `updated_by` → `profiles`
- Soft delete via `deleted_at` where appropriate
- Unique business keys scoped by company (e.g. `(company_id, invoice_number)`)
- Indian FY: 1 Apr – 31 Mar
- Document numbers: `{prefix}/{fy}/{doc_type}/{padded_seq}` e.g. `IAT/2026-27/INV/0001`
- GST rates live in `gst_rates` (admin-configurable); SQL helper only chooses CGST+SGST vs IGST from state comparison

## Auth linkage

- `profiles.id` = `auth.users.id`
- Trigger `on_auth_user_created` inserts profile on signup
- Company access via `user_roles` (multi-company ready)

## RLS

- `anon`: no grants on business tables
- `authenticated`: company isolation + `has_permission(company_id, resource, action)`
- `super_admin` role bypasses permission checks inside `has_permission`
- Viewer: `read` only (seeded)
- Issued invoices / credit / debit / purchase invoices: hard delete blocked; direct edits blocked (cancel or payment fields only)

## How to apply

```bash
# Local full reset (migrations + seed)
npx supabase db reset

# Remote
npx supabase db push
# then run seed.sql once in SQL Editor if needed
```

## Key tables (by domain)

**Core:** `companies`, `profiles`, `roles`, `permissions`, `role_permissions`, `user_roles`, `company_settings`, `bank_accounts`, `partners`, `financial_years`, `document_sequences`

**Masters:** `customers`, `vendors`, `products`, `product_categories`, `units`, `gst_rates`, `warehouses`, `locations`, `expense_categories`

**Sales:** `quotations`, `sales_orders`, `delivery_challans`, `invoices`, `credit_notes`, `debit_notes`, `customer_payments` (+ `*_items` / allocations)

**Purchase:** `purchase_requisitions`, `purchase_orders`, `goods_receipts`, `purchase_invoices`, `vendor_payments`, `expenses`

**Inventory:** `inventory_balances`, `inventory_transactions`, `stock_adjustments`, `stock_transfers`

**Manufacturing:** `boms`, `bom_items`, `process_routes`, `route_operations`, `work_orders`, `production_entries`

**Quality / tooling:** `tools`, `tool_maintenance`, `inspections`, `ncrs`

**System:** `documents`, `audit_logs`
