# Phase 5 — Inventory, Warehouse & Stock Management

**Goal:** Warehouse/location master UI and inventory ledger with stock in/out/transfer/adjustment, including steel batch/heat traceability fields where present.

## Prerequisites

- Phase 2 products; Phase 4 GRN preferred (receipts should post stock).
- Schema: `supabase/migrations/00006_inventory.sql`, warehouses in `00003_masters.sql`.

## In scope

- Warehouses CRUD (Raw Material Store, WIP, Finished Goods, Tool Room, Scrap — seeded)
- Locations (rack/bin) under warehouses
- Current stock / balances view
- Stock ledger (item movements)
- Stock In / Out / Transfer / Adjustment flows
- Every movement creates `inventory_transactions`
- Reports within module: current stock, low stock, valuation stub, movement, item ledger, batch traceability
- Steel fields when columns exist: grade, thickness, heat number, coil number, batch

## Out of scope

- Full manufacturing consumption UI (Phase 6 should post consumption/output)
- Company-wide financial reports (Phase 8)

## Tables involved

- `warehouses`, `locations`
- `inventory_balances`
- `inventory_transactions`
- `stock_adjustments`, `stock_adjustment_items`
- `stock_transfers`, `stock_transfer_items`
- `products`, `units`

## Routes

| Path | Page |
|------|------|
| `/inventory` | Stock overview / ledger |
| `/inventory/warehouses` | Warehouses + locations |
| `/inventory/adjustments` | Adjustments (add if useful) |
| `/inventory/transfers` | Transfers (add if useful) |
| `/inventory/items/:productId` | Item ledger detail |

Update `src/constants/navigation.ts` if new hrefs are added; replace Phase 5 stubs.

## Components / features

```
src/features/inventory/stock/
src/features/inventory/warehouses/
src/features/inventory/adjustments/
src/features/inventory/transfers/
src/services/inventory/*.ts
```

## Movement rules

Record: item, warehouse/location, batch/heat when applicable, qty, unit, cost, from/to location, user, date, reference document (PO/GRN/SO/DC/WO/adjustment).

Types: Opening, Purchase, GRN, Sales, Delivery, Production Consumption, Production Output, Adjustment, Scrap, Return, Transfer.

## API / data operations

- Prefer DB functions/triggers for balance updates if they exist; otherwise transactional service writes (balance + ledger in one flow)
- Never allow negative stock without explicit override permission if product policy requires
- Soft-delete adjustments carefully; prefer reversing entries

## RBAC

`inventory`, `warehouses` — Store Manager create/update; Viewer read-only.

## Business rules

- Every stock movement → inventory transaction
- Batch/heat for raw steel where applicable
- INR costing, IST timestamps, DD/MM/YYYY

## Acceptance criteria

- [ ] Warehouse/location management works
- [ ] Adjustments and transfers update balances + ledger
- [ ] Low stock visible from min/reorder on products
- [ ] Phase 5 routes live; `npm run build` succeeds

**Implement this phase completely before Phase 6.**
