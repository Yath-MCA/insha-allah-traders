# Phase prompts (Phases 2–9)

Ready-to-paste Cursor/agent briefs for building the ERP **after Phase 1**.

Phase 1 (foundation: schema, RLS, auth, company settings, app shell) is already in the repo. The **full PostgreSQL schema** lives under [`supabase/migrations/`](../../supabase/migrations/). Prefer **UI + services + hooks**; only add a migration when a real schema gap appears.

## How to use

1. Complete phases **in order** (2 → 9).
2. In Cursor, open the phase file (or `@`-mention it) and ask the agent to implement it fully.
3. Before coding, the agent should confirm tables, routes, and components from the prompt.
4. After the phase: `npm run build` must succeed; replace Coming Soon stubs for that phase’s routes.

| Phase | File | Focus |
|-------|------|--------|
| 2 | [PHASE_02_masters.md](./PHASE_02_masters.md) | Customers, Vendors, Products, GST rates |
| 3 | [PHASE_03_sales.md](./PHASE_03_sales.md) | Quotations → SO → DC → Invoices, payments, PDF |
| 4 | [PHASE_04_purchase.md](./PHASE_04_purchase.md) | PO, GRN, purchase invoices, expenses, vendor payments |
| 5 | [PHASE_05_inventory.md](./PHASE_05_inventory.md) | Warehouses, stock ledger, adjustments, transfers |
| 6 | [PHASE_06_manufacturing.md](./PHASE_06_manufacturing.md) | BOM, routing, work orders, production |
| 7 | [PHASE_07_tooling_quality.md](./PHASE_07_tooling_quality.md) | Tooling, inspections, NCR |
| 8 | [PHASE_08_reports_docs.md](./PHASE_08_reports_docs.md) | Dashboard KPIs, reports, GST registers, documents |
| 9 | [PHASE_09_hardening.md](./PHASE_09_hardening.md) | Security, audit polish, testing, backup, deploy |

## Conventions (all phases)

- Company: **Insha Allah Traders** (Partnership), prefix **IAT**, multi-tenant via `company_id` + RLS
- INR, Asia/Kolkata, DD/MM/YYYY display
- GST rates from `gst_rates` — never hardcode tax rates as business truth
- No service-role key in frontend (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` only)
- Reuse: `src/services/`, `RequirePermission`, `formatINR` / `formatDateDDMMYYYY`, shadcn, industrial steel/slate UI
- Permission resource keys: see [`src/constants/permissions.ts`](../../src/constants/permissions.ts)
- Nav routes: see [`src/constants/navigation.ts`](../../src/constants/navigation.ts)

Root setup: [README.md](../../README.md)
