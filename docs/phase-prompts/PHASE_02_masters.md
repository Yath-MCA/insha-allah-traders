# Phase 2 — Customers, Vendors, Products & GST Master

**Goal:** Ship master-data CRUD so Sales/Purchase phases have real parties, items, and configurable GST rates.

## Prerequisites

- Phase 1 complete (auth, RBAC, company settings, shell).
- Schema already in `supabase/migrations/00003_masters.sql` (and related enums).
- Reuse `src/services/domain.ts` patterns, `RequirePermission`, TanStack Query, RHF + Zod.
- Replace Coming Soon stubs in `src/routes/index.tsx` for Phase 2 routes.

## In scope

- Customer master + contacts + detail page (tabs/sections for linked docs — empty until Phase 3)
- Vendor master + contacts + detail page (linked docs empty until Phase 4)
- Product / item master (categories, UOM, HSN/SAC, prices, stock mins)
- GST rates admin UI (create/update rates; never hardcode in app logic)
- Units listing/management if needed for product forms
- List pages: search, filters, pagination, sort, active/inactive
- Export CSV for list views

## Out of scope

- Quotations, invoices, purchase, inventory movements, PDFs (Phases 3+)
- Rewriting core migrations unless a proven column gap exists

## Tables involved

- `customers`, `customer_contacts` (if present; else contacts on customer row — match migration)
- `vendors`, `vendor_contacts` (same)
- `products`, `product_categories`, `units`
- `gst_rates`
- `audit_logs` (triggers already fire on masters)

## Routes

| Path | Page |
|------|------|
| `/customers` | Customer list |
| `/customers/new` | Create customer |
| `/customers/:id` | Detail + edit |
| `/vendors` | Vendor list |
| `/vendors/new` | Create vendor |
| `/vendors/:id` | Detail + edit |
| `/products` | Product list |
| `/products/new` | Create product |
| `/products/:id` | Detail + edit |
| `/gst-rates` | GST rate list + form |

Wire routes in `src/routes/index.tsx`; keep `phase: 2` items live in `src/constants/navigation.ts`.

## Components / features

```
src/features/customers/   # pages, forms, hooks
src/features/vendors/
src/features/products/
src/features/gst/         # gst-rates UI
src/services/customers.ts | vendors.ts | products.ts | gstRates.ts
```

Shared: data table, confirm dialogs, empty/loading/error states, toasts.

## Customer fields (align with DB)

Customer code, company/legal name, GSTIN, PAN, customer type (OEM / Tier 1 / Tier 2 / Industrial / Other), contact person, email, phone, billing/shipping address, state, city, pincode, payment terms, credit limit, default GST treatment (Registered / Unregistered / SEZ / Export), default price list ref if column exists, active/inactive.

Detail page sections (placeholders OK if no data yet): Quotations, Sales Orders, Delivery Challans, Invoices, Payments, Outstanding, Documents, Activity timeline.

## Vendor fields

Vendor code, company name, GSTIN, PAN, contact, phone, email, address, state, payment terms, bank account, IFSC, category (Steel Supplier, Raw Material, Welding Consumables, Tool Steel, Machine Supplier, Job Work, Coating, Plating, Transport, Maintenance, Other), active/inactive.

## Product fields

Types: Raw Material, Sheet Metal, Coil, Component, Assembly, Finished Good, Tool, Die, Jig, Fixture, Consumable, Service, Job Work.

Item code, internal/customer part number, description, category/subcategory, material, grade, thickness/width/length/weight, UOM, HSN, SAC, GST rate (FK or % from `gst_rates`), purchase/sales price, min stock, reorder level, lead time, active/inactive.

UOM: Nos, Kg, Ton, Meter, MM, Set, Hour, Job (seeded `units`).

## GST rates

Admin-configurable rows only. UI disclaimer: rates must be verified with a tax professional; system is not a CA substitute. No filing integration claims.

## API / data operations

- CRUD via Supabase client scoped by `company_id` from auth context
- Soft-delete or `is_active` per schema
- Zod schemas for all forms
- Unique codes per company (surface DB errors clearly)

## RBAC

Gate with: `customers`, `vendors`, `products`, `gst_rates`, `units` — actions `read|create|update|delete` as seeded. Viewer = read-only.

## Business rules

- INR for prices; DD/MM/YYYY; Asia/Kolkata
- Do not hardcode GST %
- Store HSN/SAC on products
- Track customer/vendor GSTIN
- Customer-specific part numbers supported on products

## Acceptance criteria

- [ ] All Phase 2 routes replace Coming Soon
- [ ] CRUD works against real Supabase (no mocks)
- [ ] Permission-gated UI + RLS still holds
- [ ] `npm run build` succeeds
- [ ] Empty states and validation errors are clear

**Implement this phase completely before Phase 3.**
