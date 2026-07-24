-- =============================================================================
-- 00006_inventory.sql
-- Inventory balances, ledger transactions, adjustments, transfers
-- =============================================================================

CREATE TABLE public.inventory_balances (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  product_id      uuid NOT NULL REFERENCES public.products (id),
  warehouse_id    uuid NOT NULL REFERENCES public.warehouses (id),
  location_id     uuid REFERENCES public.locations (id),
  quantity_on_hand    numeric(14,4) NOT NULL DEFAULT 0,
  quantity_reserved   numeric(14,4) NOT NULL DEFAULT 0,
  quantity_available  numeric(14,4) GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
  avg_cost            numeric(14,4) NOT NULL DEFAULT 0,
  last_txn_at         timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT inventory_balances_qty_chk CHECK (quantity_on_hand >= 0 AND quantity_reserved >= 0)
);

-- Unique per product/warehouse/location (NULL location = warehouse-level)
CREATE UNIQUE INDEX inventory_balances_wh_loc_uidx
  ON public.inventory_balances (company_id, product_id, warehouse_id, COALESCE(location_id, '00000000-0000-0000-0000-000000000000'::uuid));

CREATE INDEX inventory_balances_company_idx ON public.inventory_balances (company_id);
CREATE INDEX inventory_balances_product_idx ON public.inventory_balances (product_id);
CREATE INDEX inventory_balances_warehouse_idx ON public.inventory_balances (warehouse_id);

CREATE TABLE public.inventory_transactions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  product_id        uuid NOT NULL REFERENCES public.products (id),
  warehouse_id      uuid NOT NULL REFERENCES public.warehouses (id),
  location_id       uuid REFERENCES public.locations (id),
  txn_type          public.inventory_txn_type NOT NULL,
  txn_date          date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  quantity          numeric(14,4) NOT NULL CHECK (quantity <> 0),
  unit_cost         numeric(14,4) NOT NULL DEFAULT 0,
  reference_type    text,
  reference_id      uuid,
  reference_number  text,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES public.profiles (id)
);

CREATE INDEX inventory_transactions_company_idx ON public.inventory_transactions (company_id);
CREATE INDEX inventory_transactions_product_idx ON public.inventory_transactions (product_id, txn_date);
CREATE INDEX inventory_transactions_ref_idx
  ON public.inventory_transactions (reference_type, reference_id);
CREATE INDEX inventory_transactions_warehouse_idx
  ON public.inventory_transactions (warehouse_id, txn_date);

-- ---------------------------------------------------------------------------
-- stock adjustments
-- ---------------------------------------------------------------------------
CREATE TABLE public.stock_adjustments (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  warehouse_id        uuid NOT NULL REFERENCES public.warehouses (id),
  adjustment_number   text NOT NULL,
  adjustment_date     date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  reason              text,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT stock_adjustments_company_number_key UNIQUE (company_id, adjustment_number)
);

CREATE INDEX stock_adjustments_company_idx
  ON public.stock_adjustments (company_id) WHERE deleted_at IS NULL;

CREATE TABLE public.stock_adjustment_items (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id            uuid NOT NULL REFERENCES public.companies (id),
  stock_adjustment_id   uuid NOT NULL REFERENCES public.stock_adjustments (id) ON DELETE CASCADE,
  product_id            uuid NOT NULL REFERENCES public.products (id),
  location_id           uuid REFERENCES public.locations (id),
  line_no               integer NOT NULL,
  system_qty            numeric(14,4) NOT NULL DEFAULT 0,
  counted_qty           numeric(14,4) NOT NULL DEFAULT 0,
  difference_qty        numeric(14,4) NOT NULL DEFAULT 0,
  unit_cost             numeric(14,4) NOT NULL DEFAULT 0,
  notes                 text,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT stock_adjustment_items_line_key UNIQUE (stock_adjustment_id, line_no)
);

-- ---------------------------------------------------------------------------
-- stock transfers
-- ---------------------------------------------------------------------------
CREATE TABLE public.stock_transfers (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  from_warehouse_id   uuid NOT NULL REFERENCES public.warehouses (id),
  to_warehouse_id     uuid NOT NULL REFERENCES public.warehouses (id),
  transfer_number     text NOT NULL,
  transfer_date       date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.document_status NOT NULL DEFAULT 'draft',
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT stock_transfers_company_number_key UNIQUE (company_id, transfer_number),
  CONSTRAINT stock_transfers_wh_diff_chk CHECK (from_warehouse_id <> to_warehouse_id)
);

CREATE INDEX stock_transfers_company_idx
  ON public.stock_transfers (company_id) WHERE deleted_at IS NULL;

CREATE TABLE public.stock_transfer_items (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  stock_transfer_id   uuid NOT NULL REFERENCES public.stock_transfers (id) ON DELETE CASCADE,
  product_id          uuid NOT NULL REFERENCES public.products (id),
  from_location_id    uuid REFERENCES public.locations (id),
  to_location_id      uuid REFERENCES public.locations (id),
  line_no             integer NOT NULL,
  quantity            numeric(14,4) NOT NULL CHECK (quantity > 0),
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT stock_transfer_items_line_key UNIQUE (stock_transfer_id, line_no)
);
