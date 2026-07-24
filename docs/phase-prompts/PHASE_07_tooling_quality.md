# Phase 7 — Tooling, Jigs, Fixtures & Quality Management

**Goal:** Tool master lifecycle (press tools, dies, jigs, fixtures) plus incoming / in-process / final inspection and NCR CAPA tracking.

## Prerequisites

- Phase 2 customers/products; Phase 6 work orders preferred for in-process inspection links.
- Schema: `supabase/migrations/00008_tooling_quality.sql`.

## In scope

### Tooling

- Tool master: Press Tool, Progressive Die, Compound Die, Jig, Fixture, Gauge
- Fields: tool number, customer, part number, type, drawing number, revision, material, cost, supplier, status
- Statuses: Design, Development, Trial, Approved, Production, Maintenance, Obsolete
- Tool maintenance / repair / usage / life / history (`tool_maintenance`)
- Customer-owned tooling flag if column exists

### Quality

- Incoming inspection (material, supplier, PO, heat, grade, thickness, result)
- In-process (WO, process, parameter, spec, actual, result)
- Final (part, customer, drawing, revision, measurements, result)
- Results: Accepted / Rejected / Hold
- NCR: number, issue, root cause, corrective/preventive action, owner, closure date

## Out of scope

- Full GST/financial reports (Phase 8), deployment hardening (Phase 9)

## Tables involved

- `tools`, `tool_maintenance`
- `inspections`, `inspection_items`
- `ncrs`
- Links: `customers`, `products`, `vendors`, `purchase_orders`, `work_orders`

## Routes

| Path | Page |
|------|------|
| `/tooling` | Tool list + detail + maintenance |
| `/tooling/:id` | Tool history |
| `/quality` | Inspections list + create |
| `/quality/ncrs` | NCR list + detail (add nav if needed) |

Replace Phase 7 stubs in routes/nav.

## Components / features

```
src/features/tooling/
src/features/quality/inspections/
src/features/quality/ncrs/
src/services/tooling.ts
src/services/quality.ts
```

## API / data operations

- CRUD with company scope; document numbering for NCR via `next_document_number` if doc type exists
- Attach drawings/MTC via documents module stub or Storage paths for Phase 8 linkage
- Soft status transitions; keep history rows

## RBAC

`tooling`, `quality` — Quality Manager / Production as seeded.

## Business rules

- Support customer-owned tooling and drawing revision control
- Heat/batch on incoming inspection where applicable
- Audit important status changes

## Acceptance criteria

- [ ] Tool lifecycle + maintenance history works
- [ ] All three inspection types creatable
- [ ] NCR open → close workflow works
- [ ] `npm run build` succeeds

**Implement this phase completely before Phase 8.**
