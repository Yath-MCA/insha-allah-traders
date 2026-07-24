-- =============================================================================
-- 00007_manufacturing.sql
-- BOM, process routes, work orders, production entries
-- =============================================================================

CREATE TABLE public.boms (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  product_id      uuid NOT NULL REFERENCES public.products (id),
  code            text NOT NULL,
  name            text NOT NULL,
  version         text NOT NULL DEFAULT '1.0',
  is_active       boolean NOT NULL DEFAULT true,
  is_default      boolean NOT NULL DEFAULT false,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz,
  CONSTRAINT boms_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX boms_company_idx ON public.boms (company_id) WHERE deleted_at IS NULL;
CREATE INDEX boms_product_idx ON public.boms (product_id);
CREATE UNIQUE INDEX boms_one_default_uidx
  ON public.boms (company_id, product_id)
  WHERE is_default = true AND deleted_at IS NULL;

CREATE TABLE public.bom_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  bom_id          uuid NOT NULL REFERENCES public.boms (id) ON DELETE CASCADE,
  component_id    uuid NOT NULL REFERENCES public.products (id),
  line_no         integer NOT NULL,
  quantity        numeric(14,4) NOT NULL CHECK (quantity > 0),
  unit_id         uuid REFERENCES public.units (id),
  scrap_pct       numeric(5,2) NOT NULL DEFAULT 0,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT bom_items_line_key UNIQUE (bom_id, line_no)
);

CREATE INDEX bom_items_bom_idx ON public.bom_items (bom_id);
CREATE INDEX bom_items_component_idx ON public.bom_items (component_id);

-- ---------------------------------------------------------------------------
-- process routes / operations
-- ---------------------------------------------------------------------------
CREATE TABLE public.process_routes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  product_id      uuid NOT NULL REFERENCES public.products (id),
  code            text NOT NULL,
  name            text NOT NULL,
  version         text NOT NULL DEFAULT '1.0',
  is_active       boolean NOT NULL DEFAULT true,
  is_default      boolean NOT NULL DEFAULT false,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz,
  CONSTRAINT process_routes_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX process_routes_company_idx
  ON public.process_routes (company_id) WHERE deleted_at IS NULL;
CREATE INDEX process_routes_product_idx ON public.process_routes (product_id);

CREATE TABLE public.route_operations (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  process_route_id  uuid NOT NULL REFERENCES public.process_routes (id) ON DELETE CASCADE,
  sequence_no       integer NOT NULL,
  operation_code    text NOT NULL,
  operation_name    text NOT NULL,
  work_center       text,
  setup_minutes     numeric(10,2) NOT NULL DEFAULT 0,
  run_minutes       numeric(10,2) NOT NULL DEFAULT 0,
  description       text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT route_operations_seq_key UNIQUE (process_route_id, sequence_no)
);

CREATE INDEX route_operations_route_idx ON public.route_operations (process_route_id);

-- ---------------------------------------------------------------------------
-- work orders
-- ---------------------------------------------------------------------------
CREATE TABLE public.work_orders (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  product_id          uuid NOT NULL REFERENCES public.products (id),
  bom_id              uuid REFERENCES public.boms (id),
  process_route_id    uuid REFERENCES public.process_routes (id),
  sales_order_id      uuid REFERENCES public.sales_orders (id),
  warehouse_id        uuid REFERENCES public.warehouses (id),
  wo_number           text NOT NULL,
  wo_date             date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  planned_start       date,
  planned_end         date,
  actual_start        timestamptz,
  actual_end          timestamptz,
  status              public.work_order_status NOT NULL DEFAULT 'draft',
  quantity_planned    numeric(14,4) NOT NULL CHECK (quantity_planned > 0),
  quantity_completed  numeric(14,4) NOT NULL DEFAULT 0,
  quantity_scrapped   numeric(14,4) NOT NULL DEFAULT 0,
  priority            smallint NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT work_orders_company_number_key UNIQUE (company_id, wo_number)
);

CREATE INDEX work_orders_company_idx ON public.work_orders (company_id) WHERE deleted_at IS NULL;
CREATE INDEX work_orders_status_idx ON public.work_orders (company_id, status);
CREATE INDEX work_orders_product_idx ON public.work_orders (product_id);

CREATE TABLE public.work_order_materials (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  work_order_id   uuid NOT NULL REFERENCES public.work_orders (id) ON DELETE CASCADE,
  product_id      uuid NOT NULL REFERENCES public.products (id),
  line_no         integer NOT NULL,
  quantity_required numeric(14,4) NOT NULL CHECK (quantity_required > 0),
  quantity_issued   numeric(14,4) NOT NULL DEFAULT 0,
  unit_id         uuid REFERENCES public.units (id),
  warehouse_id    uuid REFERENCES public.warehouses (id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT work_order_materials_line_key UNIQUE (work_order_id, line_no)
);

CREATE INDEX work_order_materials_wo_idx ON public.work_order_materials (work_order_id);

-- ---------------------------------------------------------------------------
-- production entries
-- ---------------------------------------------------------------------------
CREATE TABLE public.production_entries (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  work_order_id     uuid NOT NULL REFERENCES public.work_orders (id),
  operation_id      uuid REFERENCES public.route_operations (id),
  entry_date        date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  quantity_good     numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity_good >= 0),
  quantity_reject   numeric(14,4) NOT NULL DEFAULT 0 CHECK (quantity_reject >= 0),
  warehouse_id      uuid REFERENCES public.warehouses (id),
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES public.profiles (id),
  updated_by        uuid REFERENCES public.profiles (id),
  deleted_at        timestamptz
);

CREATE INDEX production_entries_company_idx
  ON public.production_entries (company_id) WHERE deleted_at IS NULL;
CREATE INDEX production_entries_wo_idx ON public.production_entries (work_order_id);

CREATE TABLE public.production_consumptions (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id              uuid NOT NULL REFERENCES public.companies (id),
  production_entry_id     uuid NOT NULL REFERENCES public.production_entries (id) ON DELETE CASCADE,
  product_id              uuid NOT NULL REFERENCES public.products (id),
  warehouse_id            uuid REFERENCES public.warehouses (id),
  quantity                numeric(14,4) NOT NULL CHECK (quantity > 0),
  unit_id                 uuid REFERENCES public.units (id),
  created_at              timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX production_consumptions_entry_idx
  ON public.production_consumptions (production_entry_id);
