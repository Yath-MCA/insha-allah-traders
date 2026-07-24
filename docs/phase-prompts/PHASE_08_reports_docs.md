# Phase 8 — Reports, GST Reports, Dashboard & Document Management

**Goal:** Operational dashboard with real KPIs/charts, exportable business + GST registers, and company document vault on Supabase Storage.

## Prerequisites

- Phases 2–7 data flowing (sales, purchase, inventory, manufacturing as available).
- Schema: transactional tables + `documents`, `audit_logs`; Storage buckets `documents`, `invoice-pdfs`, etc.

## In scope

### Dashboard (`/`)

Replace Phase 1 placeholder with live cards:

- Total / this-month sales, outstanding & overdue receivables
- Purchases, outstanding payables
- Cash/bank balance (from payments + expenses as modeled)
- Inventory value, low stock count
- Open orders, pending deliveries, pending POs

Charts (Recharts): monthly sales/purchases, receivables, payables, expense trends.

Quick actions: New Quotation, SO, Invoice, PO, GRN, Expense, Stock Adjustment (link to existing routes).

Recent activity from `audit_logs` or recent docs.

### Reports (`/reports` and children)

Sales: by customer/product, monthly, GST sales, outstanding.  
Purchase: by vendor, monthly, vendor outstanding.  
Inventory: summary, ledger, valuation, low stock.  
Manufacturing: production summary, rejection, scrap, machine utilization (best-effort).  
Tooling: cost, development, maintenance.  
Financial: income & expense, cash flow, receivables, payables.

Exports: CSV, Excel (e.g. SheetJS), PDF where useful.

### GST dashboard / registers

Sales register, purchase register, output/input GST, CGST/SGST/IGST, HSN summary, customer/vendor GST summary.

Design for later reconciliation with GST portal — **do not claim direct GST filing** unless a real API is implemented (it is not).

### Documents

Upload / download / preview / version / category / linked entity (`documents` table + Storage). Categories: Partnership Deed, GST Certificate, Udyam, PAN, Bank, Customer/Vendor PO, Drawings, CAD, RFQ, Quotation, Invoices, Inspection, MTC, Tool drawings, etc. Enforce Storage RLS / company path prefixes.

## Out of scope

- Production deploy runbooks depth beyond what’s needed here (Phase 9 expands)
- Changing RLS architecture

## Tables involved

- All operational tables (read aggregations)
- `documents`, `audit_logs`
- Storage buckets

## Routes

| Path | Page |
|------|------|
| `/` | Live dashboard |
| `/reports` | Report hub |
| `/reports/gst` | GST registers |
| `/reports/...` | Individual report pages as needed |
| `/documents` | Document vault (add to nav) |

Update navigation for Documents if missing.

## Components / features

```
src/features/dashboard/        # upgrade HomePage
src/features/reports/
src/features/reports/gst/
src/features/documents/
src/services/reports/*.ts
src/services/documents.ts
```

## API / data operations

- Aggregate via Supabase queries/RPC views; keep heavy logic in services
- Date filters in IST; FY-aware defaults (Apr–Mar)
- Export helpers shared

## RBAC

Reports: Partner/Accountant/Admin read; Documents: `documents` resource; Dashboard readable by authenticated company users with role-appropriate cards.

## Business rules

- INR formatting; DD/MM/YYYY
- GST figures from invoice/purchase lines — configurable rates already applied at document time
- Disclaimer on GST report pages: not a filing product / not CA advice

## Acceptance criteria

- [ ] Dashboard shows real numbers (zeros OK if no data)
- [ ] At least core sales/purchase/inventory/GST reports + CSV export
- [ ] Document upload/download with company isolation
- [ ] `npm run build` succeeds

**Implement this phase completely before Phase 9.**
