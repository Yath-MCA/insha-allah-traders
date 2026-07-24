-- =============================================================================
-- 00008_tooling_quality.sql
-- Tools, maintenance, inspections, NCRs
-- =============================================================================

CREATE TABLE public.tools (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  code              text NOT NULL,
  name              text NOT NULL,
  description       text,
  tool_type         text,
  serial_number     text,
  status            public.tool_status NOT NULL DEFAULT 'available',
  warehouse_id      uuid REFERENCES public.warehouses (id),
  location_id       uuid REFERENCES public.locations (id),
  purchase_date     date,
  purchase_cost     numeric(14,2),
  calibration_due   date,
  next_maintenance  date,
  notes             text,
  is_active         boolean NOT NULL DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES public.profiles (id),
  updated_by        uuid REFERENCES public.profiles (id),
  deleted_at        timestamptz,
  CONSTRAINT tools_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX tools_company_idx ON public.tools (company_id) WHERE deleted_at IS NULL;
CREATE INDEX tools_status_idx ON public.tools (company_id, status);

CREATE TABLE public.tool_maintenance (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  tool_id           uuid NOT NULL REFERENCES public.tools (id),
  maintenance_type  public.maintenance_type NOT NULL DEFAULT 'preventive',
  maintenance_date  date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  performed_by      uuid REFERENCES public.profiles (id),
  cost              numeric(14,2) NOT NULL DEFAULT 0,
  next_due_date     date,
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  created_by        uuid REFERENCES public.profiles (id),
  updated_by        uuid REFERENCES public.profiles (id),
  deleted_at        timestamptz
);

CREATE INDEX tool_maintenance_company_idx
  ON public.tool_maintenance (company_id) WHERE deleted_at IS NULL;
CREATE INDEX tool_maintenance_tool_idx ON public.tool_maintenance (tool_id);

-- ---------------------------------------------------------------------------
-- inspections
-- ---------------------------------------------------------------------------
CREATE TABLE public.inspections (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  inspection_number   text NOT NULL,
  inspection_date     date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  product_id          uuid REFERENCES public.products (id),
  work_order_id       uuid REFERENCES public.work_orders (id),
  goods_receipt_id    uuid REFERENCES public.goods_receipts (id),
  inspector_id        uuid REFERENCES public.profiles (id),
  result              public.inspection_result NOT NULL DEFAULT 'pending',
  quantity_inspected  numeric(14,4) NOT NULL DEFAULT 0,
  quantity_passed     numeric(14,4) NOT NULL DEFAULT 0,
  quantity_failed     numeric(14,4) NOT NULL DEFAULT 0,
  notes               text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT inspections_company_number_key UNIQUE (company_id, inspection_number)
);

CREATE INDEX inspections_company_idx ON public.inspections (company_id) WHERE deleted_at IS NULL;
CREATE INDEX inspections_result_idx ON public.inspections (company_id, result);

CREATE TABLE public.inspection_items (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  inspection_id   uuid NOT NULL REFERENCES public.inspections (id) ON DELETE CASCADE,
  line_no         integer NOT NULL,
  parameter_name  text NOT NULL,
  specification   text,
  measured_value  text,
  result          public.inspection_result NOT NULL DEFAULT 'pending',
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT inspection_items_line_key UNIQUE (inspection_id, line_no)
);

CREATE INDEX inspection_items_inspection_idx ON public.inspection_items (inspection_id);

-- ---------------------------------------------------------------------------
-- non-conformance reports (NCRs)
-- ---------------------------------------------------------------------------
CREATE TABLE public.ncrs (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id          uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id   uuid REFERENCES public.financial_years (id),
  ncr_number          text NOT NULL,
  ncr_date            date NOT NULL DEFAULT (timezone('Asia/Kolkata', now()))::date,
  status              public.ncr_status NOT NULL DEFAULT 'open',
  severity            public.ncr_severity NOT NULL DEFAULT 'minor',
  product_id          uuid REFERENCES public.products (id),
  work_order_id       uuid REFERENCES public.work_orders (id),
  inspection_id       uuid REFERENCES public.inspections (id),
  customer_id         uuid REFERENCES public.customers (id),
  vendor_id           uuid REFERENCES public.vendors (id),
  title               text NOT NULL,
  description         text,
  root_cause          text,
  corrective_action   text,
  preventive_action   text,
  raised_by           uuid REFERENCES public.profiles (id),
  assigned_to         uuid REFERENCES public.profiles (id),
  closed_at           timestamptz,
  closed_by           uuid REFERENCES public.profiles (id),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid REFERENCES public.profiles (id),
  updated_by          uuid REFERENCES public.profiles (id),
  deleted_at          timestamptz,
  CONSTRAINT ncrs_company_number_key UNIQUE (company_id, ncr_number)
);

CREATE INDEX ncrs_company_idx ON public.ncrs (company_id) WHERE deleted_at IS NULL;
CREATE INDEX ncrs_status_idx ON public.ncrs (company_id, status);
CREATE INDEX ncrs_severity_idx ON public.ncrs (company_id, severity);
