-- =============================================================================
-- 00005_purchase_expenses.sql
-- PR / PO / GRN / purchase invoices, vendor payments, expenses
-- =============================================================================

-- ---------------------------------------------------------------------------
-- purchase_requisitions
-- ---------------------------------------------------------------------------
CREATE TABLE public.purchase_requisitions (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  pr_number           text NOT NULL,
  pr_date             date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  required_by         date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  requested_by        uuid REFERENCES public.profiles (id),
  warehouse_id        uuid REFERENCES public.warehouses (id),
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT purchase_requisitions_company_number_key UNIQUE (company_id, pr_number)
);

CREATE INDEX purchase_requisitions_company_idx
  ON public.purchase_requisitions (company_id) WHERE deleted_at IS NULL;

CREATE TABLE public.purchase_requisition_items (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id                uuid NOT NULL REFERENCES public.companies (id),
  purchase_requisition_id   uuid NOT NULL REFERENCES public.purchase_requisitions (id) ON DELETE CASCADE,
  product_id                uuid REFERENCES public.products (id),
  line_no                   integer NOT NULL,
  description               text NOT NULL,
  unit_id                   uuid REFERENCES public.units (id),
  quantity                  numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity > 0),
  estimated_rate            numeric(14,4) NOT NULL DEFAULT 0,
  notes                     text,
  created_at                timestamptz NOT NULL DEFAULT now(),
  updated_at                timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_requisition_items_line_key UNIQUE (purchase_requisition_id, line_no)
);

-- ---------------------------------------------------------------------------
-- purchase_orders
-- ---------------------------------------------------------------------------
CREATE TABLE public.purchase_orders (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  vendor_id           uuid NOT NULL REFERENCES public.vendors (id),
  purchase_requisition_id uuid REFERENCES public.purchase_requisitions (id),
  po_number           text NOT NULL,
  po_date             date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  expected_date       date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  vendor_address      text,
  warehouse_id        uuid REFERENCES public.warehouses (id),
  currency_code       text NOT NULL DEFAULT 'INR',
  subtotal            numeric(14,2) NOT NULL DEFAULT 0,
  discount_amount     numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount      numeric(14,2) NOT NULL DEFAULT 0,
  cgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  cess_amount         numeric(14,2) NOT NULL DEFAULT 0,
  round_off           numeric(14,2) NOT NULL DEFAULT 0,
  grand_total         numeric(14,2) NOT NULL DEFAULT 0,
  notes               text,
  terms               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT purchase_orders_company_number_key UNIQUE (company_id, po_number)
);

CREATE INDEX purchase_orders_company_idx
  ON public.purchase_orders (company_id) WHERE deleted_at IS NULL;
CREATE INDEX purchase_orders_vendor_idx ON public.purchase_orders (vendor_id);
CREATE INDEX purchase_orders_status_idx ON public.purchase_orders (company_id, status);

CREATE TABLE public.purchase_order_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  purchase_order_id uuid NOT NULL REFERENCES public.purchase_orders (id) ON DELETE CASCADE,
  product_id        uuid REFERENCES public.products (id),
  line_no           integer NOT NULL,
  description       text NOT NULL,
  hsn_sac           text,
  unit_id           uuid REFERENCES public.units (id),
  quantity          numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  received_qty      numeric(14,4) NOT NULL DEFAULT 0,
  invoiced_qty      numeric(14,4) NOT NULL DEFAULT 0,
  rate              numeric(14,4) NOT NULL DEFAULT 0,
  discount_pct      numeric(5,2) NOT NULL DEFAULT 0,
  discount_amount   numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount    numeric(14,2) NOT NULL DEFAULT 0,
  gst_rate_id       uuid REFERENCES public.gst_rates (id),
  cgst_rate         numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate         numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate         numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount       numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount       numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount       numeric(14,2) NOT NULL DEFAULT 0,
  line_total        numeric(14,2) NOT NULL DEFAULT 0,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_order_items_line_key UNIQUE (purchase_order_id, line_no)
);

CREATE INDEX purchase_order_items_po_idx ON public.purchase_order_items (purchase_order_id);

-- ---------------------------------------------------------------------------
-- goods_receipts (GRN)
-- ---------------------------------------------------------------------------
CREATE TABLE public.goods_receipts (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  vendor_id           uuid NOT NULL REFERENCES public.vendors (id),
  purchase_order_id   uuid REFERENCES public.purchase_orders (id),
  warehouse_id        uuid NOT NULL REFERENCES public.warehouses (id),
  grn_number          text NOT NULL,
  grn_date            date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  vendor_invoice_number text,
  vendor_invoice_date date,
  vehicle_number      text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT goods_receipts_company_number_key UNIQUE (company_id, grn_number)
);

CREATE INDEX goods_receipts_company_idx
  ON public.goods_receipts (company_id) WHERE deleted_at IS NULL;
CREATE INDEX goods_receipts_po_idx ON public.goods_receipts (purchase_order_id);

CREATE TABLE public.goods_receipt_items (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id              uuid NOT NULL REFERENCES public.companies (id),
  goods_receipt_id        uuid NOT NULL REFERENCES public.goods_receipts (id) ON DELETE CASCADE,
  purchase_order_item_id  uuid REFERENCES public.purchase_order_items (id),
  product_id              uuid REFERENCES public.products (id),
  location_id             uuid REFERENCES public.locations (id),
  line_no                 integer NOT NULL,
  description             text NOT NULL,
  unit_id                 uuid REFERENCES public.units (id),
  quantity_ordered        numeric(14,4) NOT NULL DEFAULT 0,
  quantity_received       numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
  quantity_rejected       numeric(14,4) NOT NULL DEFAULT 0,
  notes                   text,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT goods_receipt_items_line_key UNIQUE (goods_receipt_id, line_no)
);

CREATE INDEX goods_receipt_items_grn_idx ON public.goods_receipt_items (goods_receipt_id);

-- ---------------------------------------------------------------------------
-- purchase_invoices
-- ---------------------------------------------------------------------------
CREATE TABLE public.purchase_invoices (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  vendor_id           uuid NOT NULL REFERENCES public.vendors (id),
  purchase_order_id   uuid REFERENCES public.purchase_orders (id),
  goods_receipt_id    uuid REFERENCES public.goods_receipts (id),
  purchase_invoice_number text NOT NULL,
  vendor_invoice_number   text,
  invoice_date        date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  due_date            date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  payment_status      public.payment_status NOT NULL DEFAULT 'unpaid',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  currency_code       text NOT NULL DEFAULT 'INR',
  subtotal            numeric(14,2) NOT NULL DEFAULT 0,
  discount_amount     numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount      numeric(14,2) NOT NULL DEFAULT 0,
  cgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  cess_amount         numeric(14,2) NOT NULL DEFAULT 0,
  round_off           numeric(14,2) NOT NULL DEFAULT 0,
  grand_total         numeric(14,2) NOT NULL DEFAULT 0,
  amount_paid         numeric(14,2) NOT NULL DEFAULT 0,
  amount_due          numeric(14,2) NOT NULL DEFAULT 0,
  notes               text,
  issued_at           timestamptz,
  cancelled_at        timestamptz,
  cancel_reason       text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT purchase_invoices_company_number_key UNIQUE (company_id, purchase_invoice_number)
);

CREATE INDEX purchase_invoices_company_idx
  ON public.purchase_invoices (company_id) WHERE deleted_at IS NULL;
CREATE INDEX purchase_invoices_vendor_idx ON public.purchase_invoices (vendor_id);
CREATE INDEX purchase_invoices_payment_status_idx
  ON public.purchase_invoices (company_id, payment_status);

CREATE TABLE public.purchase_invoice_items (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES public.companies (id),
  purchase_invoice_id   uuid NOT NULL REFERENCES public.purchase_invoices (id) ON DELETE CASCADE,
  product_id            uuid REFERENCES public.products (id),
  purchase_order_item_id uuid REFERENCES public.purchase_order_items (id),
  line_no               integer NOT NULL,
  description           text NOT NULL,
  hsn_sac               text,
  unit_id               uuid REFERENCES public.units (id),
  quantity              numeric(14,4) NOT NULL DEFAULT 0,
  rate                  numeric(14,4) NOT NULL DEFAULT 0,
  discount_pct          numeric(5,2) NOT NULL DEFAULT 0,
  discount_amount       numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount        numeric(14,2) NOT NULL DEFAULT 0,
  gst_rate_id           uuid REFERENCES public.gst_rates (id),
  cgst_rate             numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate             numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate             numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount           numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount           numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount           numeric(14,2) NOT NULL DEFAULT 0,
  line_total            numeric(14,2) NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT purchase_invoice_items_line_key UNIQUE (purchase_invoice_id, line_no)
);

CREATE INDEX purchase_invoice_items_pinv_idx ON public.purchase_invoice_items (purchase_invoice_id);

-- ---------------------------------------------------------------------------
-- vendor_payments
-- ---------------------------------------------------------------------------
CREATE TABLE public.vendor_payments (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  vendor_id           uuid NOT NULL REFERENCES public.vendors (id),
  payment_number      text NOT NULL,
  payment_date        date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  amount              numeric(14,2) NOT NULL CHECK (amount > 0),
  payment_mode        public.payment_mode NOT NULL DEFAULT 'neft',
  bank_account_id     uuid REFERENCES public.bank_accounts (id),
  reference_number    text,
  status              public.document_status NOT NULL DEFAULT 'issued',
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT vendor_payments_company_number_key UNIQUE (company_id, payment_number)
);

CREATE INDEX vendor_payments_company_idx
  ON public.vendor_payments (company_id) WHERE deleted_at IS NULL;
CREATE INDEX vendor_payments_vendor_idx ON public.vendor_payments (vendor_id);

CREATE TABLE public.vendor_payment_allocations (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES public.companies (id),
  vendor_payment_id     uuid NOT NULL REFERENCES public.vendor_payments (id) ON DELETE CASCADE,
  purchase_invoice_id   uuid NOT NULL REFERENCES public.purchase_invoices (id),
  amount                numeric(14,2) NOT NULL CHECK (amount > 0),
  created_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT vendor_payment_allocations_unique UNIQUE (vendor_payment_id, purchase_invoice_id)
);

CREATE INDEX vendor_payment_allocations_pinv_idx
  ON public.vendor_payment_allocations (purchase_invoice_id);

-- ---------------------------------------------------------------------------
-- expenses
-- ---------------------------------------------------------------------------
CREATE TABLE public.expenses (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  expense_category_id uuid REFERENCES public.expense_categories (id),
  vendor_id           uuid REFERENCES public.vendors (id),
  expense_number      text NOT NULL,
  expense_date        date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  payment_mode        public.payment_mode,
  bank_account_id     uuid REFERENCES public.bank_accounts (id),
  amount              numeric(14,2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
  taxable_amount      numeric(14,2) NOT NULL DEFAULT 0,
  cgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  grand_total         numeric(14,2) NOT NULL DEFAULT 0,
  gstin               text,
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  description         text,
  receipt_path        text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT expenses_company_number_key UNIQUE (company_id, expense_number)
);

CREATE INDEX expenses_company_idx ON public.expenses (company_id) WHERE deleted_at IS NULL;
CREATE INDEX expenses_date_idx ON public.expenses (company_id, expense_date);
CREATE INDEX expenses_category_idx ON public.expenses (expense_category_id);
