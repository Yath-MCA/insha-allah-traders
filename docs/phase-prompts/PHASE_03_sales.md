# Phase 3 — Quotations, Sales Orders, Delivery Challans, GST Invoices & Payments

**Goal:** End-to-end sales document flow with GST calculation, FY document numbering, customer payments, and A4 PDF preview/download/storage.

## Prerequisites

- Phase 2 masters live (customers, products, gst_rates).
- Schema: `supabase/migrations/00004_sales.sql`, numbering via `next_document_number()`, GST helpers in `00010_functions_triggers.sql`.
- Reuse company bank details / logo / signature from Phase 1 settings.

## In scope

- Quotations (+ convert → Sales Order)
- Sales Orders (ordered vs delivered qty tracking)
- Delivery Challans (+ convert → Invoice)
- Tax Invoices (issue lock; duplicate; cancel; credit/debit notes)
- Customer payments + allocations; outstanding / partially paid
- Print preview + PDF download; store PDFs in `invoice-pdfs` (and related) Storage bucket
- Email share stub optional; WhatsApp later — do not block on them

## Out of scope

- Purchase, inventory postings from DC (Phase 4–5 can hook), full reports dashboard (Phase 8)

## Tables involved

- `quotations`, `quotation_items`
- `sales_orders`, `sales_order_items`
- `delivery_challans`, `delivery_challan_items`
- `invoices`, `invoice_items`
- `credit_notes`, `credit_note_items`, `debit_notes`, `debit_note_items`
- `customer_payments`, `customer_payment_allocations`
- `document_sequences`, `financial_years`, `gst_rates`, `customers`, `products`, `bank_accounts`
- `documents` (optional link), `audit_logs`

## Routes

| Path | Page |
|------|------|
| `/sales/quotations` | List |
| `/sales/quotations/new`, `/sales/quotations/:id` | Create / view-edit |
| `/sales/orders` | List |
| `/sales/orders/new`, `/sales/orders/:id` | Create / view-edit |
| `/sales/delivery-challans` | List + detail |
| `/sales/invoices` | List + detail |
| `/sales/invoices/:id` | Invoice workspace (issue, PDF, payments) |
| `/sales/payments` | Receipts list + create |
| Credit/debit note routes under `/sales/...` as needed |

Replace Phase 3 stubs in `src/routes/index.tsx`.

## Components / features

```
src/features/sales/quotations/
src/features/sales/orders/
src/features/sales/delivery-challans/
src/features/sales/invoices/
src/features/sales/payments/
src/features/sales/pdf/          # A4 templates, print CSS
src/lib/gst.ts                   # CGST/SGST vs IGST from states + rate rows
src/services/sales/*.ts
```

Shared line-item editor, status badges, confirm dialogs (approve, issue, cancel).

## Document statuses

- Quotation: Draft, Sent, Under Negotiation, Approved, Rejected, Expired, Converted
- SO: Draft, Confirmed, In Production, Ready, Partially Delivered, Completed, Cancelled
- DC: Draft, Dispatched, Delivered
- Invoice: Draft, Approved, Issued, Partially Paid, Paid, Cancelled

## GST engine (invoice / quotation lines)

- Seller GSTIN (company) vs buyer GSTIN; place of supply vs supply state
- Same state → CGST + SGST; different → IGST (UTGST if schema supports)
- Line: qty, rate, discount, taxable, GST %, CGST/SGST/IGST amounts, line total
- Totals: subtotal, discount, taxable, CGST, SGST, IGST, round off, grand total
- Support flags: reverse charge, SEZ, export (B2B primary)
- Rates from `gst_rates` / product — **never hardcode**

## Numbering

Use DB function `next_document_number(company_id, doc_type)` concurrency-safe. Format like `IAT/2026-27/INV/0001` (prefix from company settings). Unique per company + FY.

## PDF

Professional A4: Tax Invoice, Quotation, Delivery Challan (PO PDF is Phase 4). Preview, download, upload to Storage. Footer: bank, UPI, terms, authorized signatory.

## API / data operations

- Create draft → update lines → status transitions via services
- **Issued invoices:** no edit of financial lines; cancel/credit note instead; no hard delete
- Convert QTN→SO, DC→Invoice copying lines with audit trail
- Payments update invoice paid status / outstanding

## RBAC

`quotations`, `sales_orders`, `delivery_challans`, `invoices`, `credit_notes`, `debit_notes`, `customer_payments` — gate create/update/approve/issue/cancel.

## Business rules

- Never delete issued invoices; cancel or reverse
- Unique invoice numbers; FY Apr–Mar IST
- INR, DD/MM/YYYY
- Audit on issue/cancel/payment
- Not a substitute for CA / tax professional (disclaimer on invoice UI)

## Acceptance criteria

- [ ] Full sales flow works with real Supabase data
- [ ] GST split correct for intra/inter-state using configured rates
- [ ] Issued invoice edit blocked; cancel/CN path works
- [ ] PDF preview + download + storage upload
- [ ] `npm run build` succeeds

**Implement this phase completely before Phase 4.**
