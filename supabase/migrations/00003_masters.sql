-- =============================================================================
-- 00003_masters.sql
-- Customers, vendors, products, categories, units, GST rates, warehouses
-- =============================================================================

SET search_path TO public, extensions;
-- ---------------------------------------------------------------------------
-- units of measure
-- ---------------------------------------------------------------------------
CREATE TABLE public.units (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   uuid NOT NULL REFERENCES public.companies (id),
  code         text NOT NULL,
  name         text NOT NULL,
  description  text,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES public.profiles (id),
  updated_by   uuid REFERENCES public.profiles (id),
  deleted_at   timestamptz,
  CONSTRAINT units_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX units_company_idx ON public.units (company_id) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- product categories
-- ---------------------------------------------------------------------------
CREATE TABLE public.product_categories (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   uuid NOT NULL REFERENCES public.companies (id),
  parent_id    uuid REFERENCES public.product_categories (id),
  code         text NOT NULL,
  name         text NOT NULL,
  description  text,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES public.profiles (id),
  updated_by   uuid REFERENCES public.profiles (id),
  deleted_at   timestamptz,
  CONSTRAINT product_categories_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX product_categories_company_idx
  ON public.product_categories (company_id) WHERE deleted_at IS NULL;
CREATE INDEX product_categories_parent_idx ON public.product_categories (parent_id);

-- ---------------------------------------------------------------------------
-- gst_rates (admin-configurable; NOT hardcoded business truth)
-- ---------------------------------------------------------------------------
CREATE TABLE public.gst_rates (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  name            text NOT NULL,
  hsn_sac_prefix  text,
  cgst_rate       numeric(5,2) NOT NULL DEFAULT 0 CHECK (cgst_rate >= 0 AND cgst_rate <= 100),
  sgst_rate       numeric(5,2) NOT NULL DEFAULT 0 CHECK (sgst_rate >= 0 AND sgst_rate <= 100),
  igst_rate       numeric(5,2) NOT NULL DEFAULT 0 CHECK (igst_rate >= 0 AND igst_rate <= 100),
  cess_rate       numeric(5,2) NOT NULL DEFAULT 0 CHECK (cess_rate >= 0 AND cess_rate <= 100),
  effective_from  date NOT NULL DEFAULT CURRENT_DATE,
  effective_to    date,
  is_active       boolean NOT NULL DEFAULT true,
  is_sample       boolean NOT NULL DEFAULT false,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz,
  CONSTRAINT gst_rates_effective_chk CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX gst_rates_company_idx ON public.gst_rates (company_id) WHERE deleted_at IS NULL;
CREATE INDEX gst_rates_active_idx
  ON public.gst_rates (company_id, is_active) WHERE deleted_at IS NULL;

COMMENT ON TABLE public.gst_rates IS
  'Company-configurable GST rates. Never treat seeded/sample rows as legal tax truth. Consult a CA.';
COMMENT ON COLUMN public.gst_rates.is_sample IS
  'True for illustrative seed rows; admin must configure real rates before production invoicing.';

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
CREATE TABLE public.products (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  category_id       uuid REFERENCES public.product_categories (id),
  unit_id           uuid REFERENCES public.units (id),
  gst_rate_id       uuid REFERENCES public.gst_rates (id),
  code              text NOT NULL,
  name              text NOT NULL,
  description       text,
  product_type      public.product_type NOT NULL DEFAULT 'finished_goods',
  hsn_sac           text,
  gst_treatment     public.gst_treatment NOT NULL DEFAULT 'taxable',
  sku               text,
  barcode           text,
  purchase_price    numeric(14,4) NOT NULL DEFAULT 0,
  selling_price     numeric(14,4) NOT NULL DEFAULT 0,
  mrp               numeric(14,4),
  reorder_level     numeric(14,4) NOT NULL DEFAULT 0,
  reorder_qty       numeric(14,4) NOT NULL DEFAULT 0,
  min_stock         numeric(14,4) NOT NULL DEFAULT 0,
  max_stock         numeric(14,4),
  weight_kg         numeric(14,4),
  thickness_mm      numeric(14,4),
  material_grade    text,
  is_stockable      boolean NOT NULL DEFAULT true,
  is_purchasable    boolean NOT NULL DEFAULT true,
  is_saleable       boolean NOT NULL DEFAULT true,
  is_active         boolean NOT NULL DEFAULT true,
  image_path        text,
  extra             jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES public.profiles (id),
  updated_by        uuid REFERENCES public.profiles (id),
  deleted_at        timestamptz,
  CONSTRAINT products_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX products_company_idx ON public.products (company_id) WHERE deleted_at IS NULL;
CREATE INDEX products_type_idx ON public.products (company_id, product_type) WHERE deleted_at IS NULL;
CREATE INDEX products_hsn_idx ON public.products (hsn_sac) WHERE hsn_sac IS NOT NULL;
CREATE INDEX products_name_trgm_idx ON public.products USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
CREATE TABLE public.customers (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  code                text NOT NULL,
  name                text NOT NULL,
  display_name        text,
  gstin               text,
  pan                 text,
  email               text,
  phone               text,
  mobile              text,
  billing_address_line1 text,
  billing_address_line2 text,
  billing_city        text,
  billing_state_code  public.indian_state_code,
  billing_pincode     text,
  shipping_address_line1 text,
  shipping_address_line2 text,
  shipping_city       text,
  shipping_state_code public.indian_state_code,
  shipping_pincode    text,
  place_of_supply     public.indian_state_code,
  credit_limit        numeric(14,2) NOT NULL DEFAULT 0,
  payment_terms_days  integer NOT NULL DEFAULT 30,
  contact_person      text,
  notes               text,
  is_active           boolean NOT NULL DEFAULT true,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT customers_company_code_key UNIQUE (company_id, code),
  CONSTRAINT customers_gstin_format CHECK (
    gstin IS NULL OR gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
  )
);

CREATE INDEX customers_company_idx ON public.customers (company_id) WHERE deleted_at IS NULL;
CREATE INDEX customers_gstin_idx ON public.customers (gstin) WHERE gstin IS NOT NULL;
CREATE INDEX customers_name_trgm_idx ON public.customers USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- vendors
-- ---------------------------------------------------------------------------
CREATE TABLE public.vendors (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  code                text NOT NULL,
  name                text NOT NULL,
  display_name        text,
  gstin               text,
  pan                 text,
  email               text,
  phone               text,
  mobile              text,
  address_line1       text,
  address_line2       text,
  city                text,
  state_code          public.indian_state_code,
  pincode             text,
  payment_terms_days  integer NOT NULL DEFAULT 30,
  contact_person      text,
  bank_name           text,
  bank_account_number text,
  bank_ifsc           text,
  notes               text,
  is_active           boolean NOT NULL DEFAULT true,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT vendors_company_code_key UNIQUE (company_id, code),
  CONSTRAINT vendors_gstin_format CHECK (
    gstin IS NULL OR gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
  )
);

CREATE INDEX vendors_company_idx ON public.vendors (company_id) WHERE deleted_at IS NULL;
CREATE INDEX vendors_gstin_idx ON public.vendors (gstin) WHERE gstin IS NOT NULL;
CREATE INDEX vendors_name_trgm_idx ON public.vendors USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- warehouses & bin locations
-- ---------------------------------------------------------------------------
CREATE TABLE public.warehouses (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  code            text NOT NULL,
  name            text NOT NULL,
  warehouse_type  public.warehouse_type NOT NULL DEFAULT 'general',
  address         text,
  is_default      boolean NOT NULL DEFAULT false,
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz,
  CONSTRAINT warehouses_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX warehouses_company_idx ON public.warehouses (company_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX warehouses_one_default_uidx
  ON public.warehouses (company_id)
  WHERE is_default = true AND deleted_at IS NULL;

CREATE TABLE public.locations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES public.companies (id),
  warehouse_id  uuid NOT NULL REFERENCES public.warehouses (id),
  code          text NOT NULL,
  name          text NOT NULL,
  aisle         text,
  rack          text,
  bin           text,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  created_by    uuid REFERENCES public.profiles (id),
  updated_by    uuid REFERENCES public.profiles (id),
  deleted_at    timestamptz,
  CONSTRAINT locations_wh_code_key UNIQUE (warehouse_id, code)
);

CREATE INDEX locations_company_idx ON public.locations (company_id) WHERE deleted_at IS NULL;
CREATE INDEX locations_warehouse_idx ON public.locations (warehouse_id) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- expense categories (used by purchase/expenses module)
-- ---------------------------------------------------------------------------
CREATE TABLE public.expense_categories (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   uuid NOT NULL REFERENCES public.companies (id),
  code         text NOT NULL,
  name         text NOT NULL,
  description  text,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES public.profiles (id),
  updated_by   uuid REFERENCES public.profiles (id),
  deleted_at   timestamptz,
  CONSTRAINT expense_categories_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX expense_categories_company_idx
  ON public.expense_categories (company_id) WHERE deleted_at IS NULL;
