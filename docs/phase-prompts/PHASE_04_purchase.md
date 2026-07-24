# Phase 4 — Purchases, Expenses, Vendor Payments & Financial Records

**Goal:** Purchase workflow (PR → PO → GRN → Purchase Invoice → Payment), expenses with receipt uploads, and vendor payment tracking.

## Prerequisites

- Phase 2 vendors/products/GST; Phase 3 patterns for line items, numbering, PDF, payments.
- Schema: `supabase/migrations/00005_purchase_expenses.sql`.

## In scope

- Purchase Requisitions (if in schema; else skip UI and start at PO)
- Purchase Orders (+ approve; PDF)
- Goods Receipts (ordered / received / rejected / accepted qty)
- Purchase Invoices (vendor bill capture + GST)
- Vendor payments + allocations; outstanding / overdue
- Expenses (categories, GST/TDS fields if present, receipt upload to `expense-receipts`)
- Confirm dialogs for approve / cancel

## Out of scope

- Full inventory ledger UI (Phase 5) — GRN may call inventory RPC/triggers if already in DB; otherwise leave hook comments for Phase 5
- Sales modules (already Phase 3)

## Tables involved

- `purchase_requisitions`, `purchase_requisition_items`
- `purchase_orders`, `purchase_order_items`
- `goods_receipts`, `goods_receipt_items`
- `purchase_invoices`, `purchase_invoice_items`
- `vendor_payments`, `vendor_payment_allocations`
- `expenses`, `expense_categories`
- `vendors`, `products`, `gst_rates`, `document_sequences`
- Storage: `expense-receipts`, PO PDFs as appropriate

## Routes

| Path | Page |
|------|------|
| `/purchase/orders` | PO list + detail/new |
| `/purchase/grn` | GRN list + detail/new |
| `/purchase/invoices` | Purchase invoice list + detail |
| `/purchase/expenses` | Expenses list + form + attachment |
| `/purchase/payments` | Vendor payments |
| Optional: `/purchase/requisitions` | If implementing PR |

Replace Phase 4 stubs in `src/routes/index.tsx`. Extend nav if PR is added.

## Components / features

```
src/features/purchase/orders/
src/features/purchase/grn/
src/features/purchase/invoices/
src/features/purchase/payments/
src/features/purchase/expenses/
src/features/purchase/pdf/       # PO PDF
src/services/purchase/*.ts
```

## Workflow

```
Purchase Request → Purchase Order → Goods Receipt → Purchase Invoice → Payment
```

PO fields: PO number, vendor, dates, items, qty, rate, GST, terms.  
GRN: GRN number, PO, vendor, received date, ordered/received/rejected/accepted qty.  
Purchase invoice: vendor invoice number, date, GST lines, totals.  
Expense: number, date, vendor, category, amount, GST, TDS if applicable, method, attachment, notes.

Expense categories (seeded): Rent, Electricity, Salary, Transport, Maintenance, Consumables, Tools, Software, Professional Fees, CA Fees, Legal Fees, Insurance, Bank Charges, Telephone, Internet, Other.

## Numbering / PDF

Use `next_document_number` for PO/GRN/expense/payment prefixes (`IAT/YYYY-YY/PO/0001`, etc.). PO A4 PDF: preview, download, storage.

## API / data operations

- Real Supabase CRUD + status transitions
- Soft-cancel issued POs / invoices where schema requires; no silent hard deletes of posted financials
- Payment allocations update purchase invoice outstanding
- Expense receipt upload with Storage policies (company-scoped paths)

## RBAC

`purchase_requisitions`, `purchase_orders`, `goods_receipts`, `purchase_invoices`, `vendor_payments`, `expenses` — Purchase / Accountant / Admin roles as seeded.

## Business rules

- INR, IST, DD/MM/YYYY
- Configurable GST; vendor GSTIN tracked
- Audit create/update/approve/cancel/payment
- Disclaimer: not a CA substitute

## Acceptance criteria

- [ ] PO → GRN → purchase invoice → payment path works
- [ ] Expenses with receipt upload work
- [ ] PO PDF works
- [ ] Coming Soon stubs for Phase 4 routes removed
- [ ] `npm run build` succeeds

**Implement this phase completely before Phase 5.**
