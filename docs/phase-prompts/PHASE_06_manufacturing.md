# Phase 6 — Manufacturing, BOM, Work Orders & Production

**Goal:** Bill of Materials (multi-level), process routing, work orders linked to sales orders, and production recording with material consumption / output.

## Prerequisites

- Phase 2 products; Phase 5 inventory for consumption/output postings.
- Schema: `supabase/migrations/00007_manufacturing.sql`.

## In scope

- BOM header + components (revision, version, effective date, scrap %, process)
- Multi-level BOM navigation/explosion view
- Process routes + operations (sequence, machine, times, labour, in-house vs outsourced)
- Process catalog: Laser Cutting, Shearing, Blanking, Punching, Stamping, Bending, Welding, Riveting, Grinding, Coating, Assembly, Inspection
- Work Orders (link SO, customer, product, BOM, qty, dates, priority)
- Production entries: input material, output/reject/scrap qty, operator, machine, shift, date
- Status workflow: Planned → Released → In Production → Hold → Completed / Cancelled
- Job-work / subcontract flag on operations

## Out of scope

- Tooling life tracking UI (Phase 7), quality NCR (Phase 7), full utilization reports (Phase 8)

## Tables involved

- `boms`, `bom_items`
- `process_routes`, `route_operations`
- `work_orders`, `work_order_materials`
- `production_entries`, `production_consumptions`
- `products`, `sales_orders`, `inventory_transactions` (postings)

## Routes

| Path | Page |
|------|------|
| `/manufacturing/bom` | BOM list + editor |
| `/manufacturing/routes` | Routes (add nav if needed) |
| `/manufacturing/work-orders` | WO list + detail |
| `/manufacturing/production` | Production entry UI (add if needed) |

Replace Phase 6 stubs; extend `navigation.ts` for routes/production if added.

## Components / features

```
src/features/manufacturing/bom/
src/features/manufacturing/routes/
src/features/manufacturing/work-orders/
src/features/manufacturing/production/
src/services/manufacturing/*.ts
```

## API / data operations

- CRUD BOM/routes/WO with Zod
- Completing production should create inventory transactions (consume components, receive FG) via service or RPC
- Prevent editing completed WO materials without reverse entry

## RBAC

`manufacturing` — Production Manager create/update; Viewer read.

## Business rules

- Support outsourced processes
- Customer part numbers / drawing revision on product/WO where columns exist
- Audit status changes
- IST dates, INR costs if captured

## Acceptance criteria

- [ ] Multi-level BOM create/view works
- [ ] WO lifecycle + production entry works
- [ ] Inventory side-effects for consumption/output (or clear documented hook if deferred with reason)
- [ ] `npm run build` succeeds

**Implement this phase completely before Phase 7.**
