-- =============================================================================
-- 00004_sales.sql
-- Quotations → SO → DC → Tax Invoice, credit/debit notes, customer payments
-- =============================================================================

-- Shared line-item money columns: qty, rate, discount, taxable, tax splits, total

-- ---------------------------------------------------------------------------
-- quotations
-- ---------------------------------------------------------------------------
CREATE TABLE public.quotations (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
  quotation_number    text NOT NULL,
  quotation_date      date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  valid_until         date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  billing_address     text,
  shipping_address    text,
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
  CONSTRAINT quotations_company_number_key UNIQUE (company_id, quotation_number)
);

CREATE INDEX quotations_company_idx ON public.quotations (company_id) WHERE deleted_at IS NULL;
CREATE INDEX quotations_customer_idx ON public.quotations (customer_id);
CREATE INDEX quotations_date_idx ON public.quotations (company_id, quotation_date);
CREATE INDEX quotations_status_idx ON public.quotations (company_id, status);

CREATE TABLE public.quotation_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  quotation_id    uuid NOT NULL REFERENCES public.quotations (id) ON DELETE CASCADE,
  product_id      uuid REFERENCES public.products (id),
  line_no         integer NOT NULL,
  description     text NOT NULL,
  hsn_sac         text,
  unit_id         uuid REFERENCES public.units (id),
  quantity        numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  rate            numeric(14,4) NOT NULL DEFAULT 0,
  discount_pct    numeric(5,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount  numeric(14,2) NOT NULL DEFAULT 0,
  gst_rate_id     uuid REFERENCES public.gst_rates (id),
  cgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  line_total      numeric(14,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT quotation_items_line_key UNIQUE (quotation_id, line_no)
);

CREATE INDEX quotation_items_quotation_idx ON public.quotation_items (quotation_id);

-- ---------------------------------------------------------------------------
-- sales_orders
-- ---------------------------------------------------------------------------
CREATE TABLE public.sales_orders (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
  quotation_id        uuid REFERENCES public.quotations (id),
  so_number           text NOT NULL,
  so_date             date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  delivery_date       date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  billing_address     text,
  shipping_address    text,
  currency_code       text NOT NULL DEFAULT 'INR',
  customer_po_number  text,
  customer_po_date    date,
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
  CONSTRAINT sales_orders_company_number_key UNIQUE (company_id, so_number)
);

CREATE INDEX sales_orders_company_idx ON public.sales_orders (company_id) WHERE deleted_at IS NULL;
CREATE INDEX sales_orders_customer_idx ON public.sales_orders (customer_id);
CREATE INDEX sales_orders_date_idx ON public.sales_orders (company_id, so_date);
CREATE INDEX sales_orders_status_idx ON public.sales_orders (company_id, status);

CREATE TABLE public.sales_order_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  sales_order_id  uuid NOT NULL REFERENCES public.sales_orders (id) ON DELETE CASCADE,
  product_id      uuid REFERENCES public.products (id),
  line_no         integer NOT NULL,
  description     text NOT NULL,
  hsn_sac         text,
  unit_id         uuid REFERENCES public.units (id),
  quantity        numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  delivered_qty   numeric(14,4) NOT NULL DEFAULT 0,
  invoiced_qty    numeric(14,4) NOT NULL DEFAULT 0,
  rate            numeric(14,4) NOT NULL DEFAULT 0,
  discount_pct    numeric(5,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount  numeric(14,2) NOT NULL DEFAULT 0,
  gst_rate_id     uuid REFERENCES public.gst_rates (id),
  cgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  line_total      numeric(14,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT sales_order_items_line_key UNIQUE (sales_order_id, line_no)
);

CREATE INDEX sales_order_items_so_idx ON public.sales_order_items (sales_order_id);

-- ---------------------------------------------------------------------------
-- delivery_challans
-- ---------------------------------------------------------------------------
CREATE TABLE public.delivery_challans (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
  sales_order_id      uuid REFERENCES public.sales_orders (id),
  warehouse_id        uuid REFERENCES public.warehouses (id),
  dc_number           text NOT NULL,
  dc_date             date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  vehicle_number      text,
  transporter_name    text,
  lr_number           text,
  shipping_address    text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT delivery_challans_company_number_key UNIQUE (company_id, dc_number)
);

CREATE INDEX delivery_challans_company_idx
  ON public.delivery_challans (company_id) WHERE deleted_at IS NULL;
CREATE INDEX delivery_challans_so_idx ON public.delivery_challans (sales_order_id);

CREATE TABLE public.delivery_challan_items (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES public.companies (id),
  delivery_challan_id   uuid NOT NULL REFERENCES public.delivery_challans (id) ON DELETE CASCADE,
  sales_order_item_id   uuid REFERENCES public.sales_order_items (id),
  product_id            uuid REFERENCES public.products (id),
  line_no               integer NOT NULL,
  description           text NOT NULL,
  unit_id               uuid REFERENCES public.units (id),
  quantity              numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT delivery_challan_items_line_key UNIQUE (delivery_challan_id, line_no)
);

CREATE INDEX delivery_challan_items_dc_idx ON public.delivery_challan_items (delivery_challan_id);

-- ---------------------------------------------------------------------------
-- invoices (tax invoices)
-- ---------------------------------------------------------------------------
CREATE TABLE public.invoices (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
  sales_order_id      uuid REFERENCES public.sales_orders (id),
  delivery_challan_id uuid REFERENCES public.delivery_challans (id),
  invoice_number      text NOT NULL,
  invoice_date        date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  due_date            date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  payment_status      public.payment_status NOT NULL DEFAULT 'unpaid',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  seller_state_code   public.indian_state_code,
  billing_address     text,
  shipping_address    text,
  currency_code       text NOT NULL DEFAULT 'INR',
  irn                 text,
  ack_number          text,
  ack_date            timestamptz,
  eway_bill_number    text,
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
  terms               text,
  pdf_path            text,
  issued_at           timestamptz,
  cancelled_at        timestamptz,
  cancel_reason       text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT invoices_company_number_key UNIQUE (company_id, invoice_number)
);

CREATE INDEX invoices_company_idx ON public.invoices (company_id) WHERE deleted_at IS NULL;
CREATE INDEX invoices_customer_idx ON public.invoices (customer_id);
CREATE INDEX invoices_date_idx ON public.invoices (company_id, invoice_date);
CREATE INDEX invoices_status_idx ON public.invoices (company_id, status);
CREATE INDEX invoices_payment_status_idx ON public.invoices (company_id, payment_status);

CREATE TABLE public.invoice_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  invoice_id      uuid NOT NULL REFERENCES public.invoices (id) ON DELETE CASCADE,
  product_id      uuid REFERENCES public.products (id),
  sales_order_item_id uuid REFERENCES public.sales_order_items (id),
  line_no         integer NOT NULL,
  description     text NOT NULL,
  hsn_sac         text,
  unit_id         uuid REFERENCES public.units (id),
  quantity        numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  rate            numeric(14,4) NOT NULL DEFAULT 0,
  discount_pct    numeric(5,2) NOT NULL DEFAULT 0,
  discount_amount numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount  numeric(14,2) NOT NULL DEFAULT 0,
  gst_rate_id     uuid REFERENCES public.gst_rates (id),
  cgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  line_total      numeric(14,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT invoice_items_line_key UNIQUE (invoice_id, line_no)
);

CREATE INDEX invoice_items_invoice_idx ON public.invoice_items (invoice_id);

-- ---------------------------------------------------------------------------
-- credit_notes / debit_notes
-- ---------------------------------------------------------------------------
CREATE TABLE public.credit_notes (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
  invoice_id          uuid REFERENCES public.invoices (id),
  credit_note_number  text NOT NULL,
  credit_note_date    date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  reason              text,
  subtotal            numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount      numeric(14,2) NOT NULL DEFAULT 0,
  cgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  grand_total         numeric(14,2) NOT NULL DEFAULT 0,
  notes               text,
  issued_at           timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT credit_notes_company_number_key UNIQUE (company_id, credit_note_number)
);

CREATE INDEX credit_notes_company_idx ON public.credit_notes (company_id) WHERE deleted_at IS NULL;

CREATE TABLE public.credit_note_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  credit_note_id  uuid NOT NULL REFERENCES public.credit_notes (id) ON DELETE CASCADE,
  product_id      uuid REFERENCES public.products (id),
  invoice_item_id uuid REFERENCES public.invoice_items (id),
  line_no         integer NOT NULL,
  description     text NOT NULL,
  hsn_sac         text,
  unit_id         uuid REFERENCES public.units (id),
  quantity        numeric(14,4) NOT NULL DEFAULT 0,
  rate            numeric(14,4) NOT NULL DEFAULT 0,
  taxable_amount  numeric(14,2) NOT NULL DEFAULT 0,
  cgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  line_total      numeric(14,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT credit_note_items_line_key UNIQUE (credit_note_id, line_no)
);

CREATE TABLE public.debit_notes (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
  invoice_id          uuid REFERENCES public.invoices (id),
  debit_note_number   text NOT NULL,
  debit_note_date     date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  place_of_supply     public.indian_state_code,
  tax_split           public.tax_split_type,
  reason              text,
  subtotal            numeric(14,2) NOT NULL DEFAULT 0,
  taxable_amount      numeric(14,2) NOT NULL DEFAULT 0,
  cgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount         numeric(14,2) NOT NULL DEFAULT 0,
  grand_total         numeric(14,2) NOT NULL DEFAULT 0,
  notes               text,
  issued_at           timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT debit_notes_company_number_key UNIQUE (company_id, debit_note_number)
);

CREATE INDEX debit_notes_company_idx ON public.debit_notes (company_id) WHERE deleted_at IS NULL;

CREATE TABLE public.debit_note_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  debit_note_id   uuid NOT NULL REFERENCES public.debit_notes (id) ON DELETE CASCADE,
  product_id      uuid REFERENCES public.products (id),
  invoice_item_id uuid REFERENCES public.invoice_items (id),
  line_no         integer NOT NULL,
  description     text NOT NULL,
  hsn_sac         text,
  unit_id         uuid REFERENCES public.units (id),
  quantity        numeric(14,4) NOT NULL DEFAULT 0,
  rate            numeric(14,4) NOT NULL DEFAULT 0,
  taxable_amount  numeric(14,2) NOT NULL DEFAULT 0,
  cgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  sgst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  igst_rate       numeric(5,2) NOT NULL DEFAULT 0,
  cgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  sgst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  igst_amount     numeric(14,2) NOT NULL DEFAULT 0,
  line_total      numeric(14,2) NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT debit_note_items_line_key UNIQUE (debit_note_id, line_no)
);

-- ---------------------------------------------------------------------------
-- customer_payments
-- ---------------------------------------------------------------------------
CREATE TABLE public.customer_payments (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  customer_id         uuid NOT NULL REFERENCES public.customers (id),
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
  CONSTRAINT customer_payments_company_number_key UNIQUE (company_id, payment_number)
);

CREATE INDEX customer_payments_company_idx
  ON public.customer_payments (company_id) WHERE deleted_at IS NULL;
CREATE INDEX customer_payments_customer_idx ON public.customer_payments (customer_id);

CREATE TABLE public.customer_payment_allocations (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES public.companies (id),
  customer_payment_id   uuid NOT NULL REFERENCES public.customer_payments (id) ON DELETE CASCADE,
  invoice_id            uuid NOT NULL REFERENCES public.invoices (id),
  amount                numeric(14,2) NOT NULL CHECK (amount > 0),
  created_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT customer_payment_allocations_unique UNIQUE (customer_payment_id, invoice_id)
);

CREATE INDEX customer_payment_allocations_invoice_idx
  ON public.customer_payment_allocations (invoice_id);
