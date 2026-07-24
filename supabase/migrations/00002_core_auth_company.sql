-- =============================================================================
-- 00002_core_auth_company.sql
-- Companies, profiles, RBAC, settings, partners, FY, document sequences
-- =============================================================================

-- ---------------------------------------------------------------------------
-- companies
-- ---------------------------------------------------------------------------
CREATE TABLE public.companies (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  legal_name      text NOT NULL,
  trade_name      text,
  business_type   public.business_type NOT NULL DEFAULT 'partnership',
  gstin           text,
  pan             text,
  tan             text,
  cin             text,
  email           text,
  phone           text,
  website         text,
  address_line1   text,
  address_line2   text,
  city            text,
  district        text,
  state_code      public.indian_state_code,
  pincode         text,
  country         text NOT NULL DEFAULT 'IN',
  logo_path       text,
  signature_path  text,
  invoice_prefix  text NOT NULL DEFAULT 'IAT',
  is_active       boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid,
  updated_by      uuid,
  deleted_at      timestamptz,
  CONSTRAINT companies_gstin_format CHECK (
    gstin IS NULL OR gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
  ),
  CONSTRAINT companies_pan_format CHECK (
    pan IS NULL OR pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]{1}$'
  )
);

CREATE UNIQUE INDEX companies_gstin_uidx
  ON public.companies (gstin) WHERE gstin IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX companies_active_idx ON public.companies (is_active) WHERE deleted_at IS NULL;

COMMENT ON TABLE public.companies IS 'Multi-tenant company master; seed company is Insha Allah Traders';

-- ---------------------------------------------------------------------------
-- profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id                  uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email               text,
  full_name           text,
  phone               text,
  avatar_url          text,
  default_company_id  uuid REFERENCES public.companies (id),
  is_active           boolean NOT NULL DEFAULT true,
  last_login_at       timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  created_by          uuid,
  updated_by          uuid,
  deleted_at          timestamptz
);

CREATE INDEX profiles_default_company_idx ON public.profiles (default_company_id);
CREATE INDEX profiles_email_idx ON public.profiles (email);

-- Deferred FKs for audit columns on companies → profiles
ALTER TABLE public.companies
  ADD CONSTRAINT companies_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.profiles (id),
  ADD CONSTRAINT companies_updated_by_fkey
    FOREIGN KEY (updated_by) REFERENCES public.profiles (id);

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES public.profiles (id),
  ADD CONSTRAINT profiles_updated_by_fkey
    FOREIGN KEY (updated_by) REFERENCES public.profiles (id);

-- ---------------------------------------------------------------------------
-- roles / permissions / RBAC
-- ---------------------------------------------------------------------------
CREATE TABLE public.roles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code         text NOT NULL,
  name         text NOT NULL,
  description  text,
  is_system    boolean NOT NULL DEFAULT true,
  sort_order   integer NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  deleted_at   timestamptz,
  CONSTRAINT roles_code_key UNIQUE (code)
);

CREATE TABLE public.permissions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resource     text NOT NULL,
  action       public.permission_action NOT NULL,
  description  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT permissions_resource_action_key UNIQUE (resource, action)
);

CREATE TABLE public.role_permissions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id         uuid NOT NULL REFERENCES public.roles (id) ON DELETE CASCADE,
  permission_id   uuid NOT NULL REFERENCES public.permissions (id) ON DELETE CASCADE,
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT role_permissions_role_perm_key UNIQUE (role_id, permission_id)
);

CREATE INDEX role_permissions_role_idx ON public.role_permissions (role_id);
CREATE INDEX role_permissions_perm_idx ON public.role_permissions (permission_id);

CREATE TABLE public.user_roles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  company_id   uuid NOT NULL REFERENCES public.companies (id),
  role_id      uuid NOT NULL REFERENCES public.roles (id),
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  created_by   uuid REFERENCES public.profiles (id),
  updated_by   uuid REFERENCES public.profiles (id),
  deleted_at   timestamptz,
  CONSTRAINT user_roles_user_company_role_key UNIQUE (user_id, company_id, role_id)
);

CREATE INDEX user_roles_user_idx ON public.user_roles (user_id) WHERE deleted_at IS NULL;
CREATE INDEX user_roles_company_idx ON public.user_roles (company_id) WHERE deleted_at IS NULL;
CREATE INDEX user_roles_role_idx ON public.user_roles (role_id);

-- ---------------------------------------------------------------------------
-- company_settings (1:1 extensible key bag + typed columns)
-- ---------------------------------------------------------------------------
CREATE TABLE public.company_settings (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id              uuid NOT NULL REFERENCES public.companies (id),
  financial_year_start_month smallint NOT NULL DEFAULT 4
    CHECK (financial_year_start_month BETWEEN 1 AND 12),
  currency_code           text NOT NULL DEFAULT 'INR',
  timezone                text NOT NULL DEFAULT 'Asia/Kolkata',
  date_format             text NOT NULL DEFAULT 'DD/MM/YYYY',
  default_payment_terms_days integer NOT NULL DEFAULT 30,
  enable_gst              boolean NOT NULL DEFAULT true,
  invoice_terms           text,
  invoice_notes           text,
  quotation_validity_days integer NOT NULL DEFAULT 30,
  low_stock_alert         boolean NOT NULL DEFAULT true,
  extra                   jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  created_by              uuid REFERENCES public.profiles (id),
  updated_by              uuid REFERENCES public.profiles (id),
  CONSTRAINT company_settings_company_key UNIQUE (company_id)
);

-- ---------------------------------------------------------------------------
-- bank_accounts
-- ---------------------------------------------------------------------------
CREATE TABLE public.bank_accounts (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  account_name    text NOT NULL,
  bank_name       text NOT NULL,
  branch_name     text,
  account_number  text NOT NULL,
  ifsc_code       text,
  upi_id          text,
  is_primary      boolean NOT NULL DEFAULT false,
  is_active       boolean NOT NULL DEFAULT true,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz
);

CREATE INDEX bank_accounts_company_idx
  ON public.bank_accounts (company_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX bank_accounts_one_primary_uidx
  ON public.bank_accounts (company_id)
  WHERE is_primary = true AND deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- partners (firm partners / owners — not trade partners)
-- ---------------------------------------------------------------------------
CREATE TABLE public.partners (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  full_name       text NOT NULL,
  pan             text,
  email           text,
  phone           text,
  share_percent   numeric(5,2) CHECK (share_percent IS NULL OR (share_percent >= 0 AND share_percent <= 100)),
  status          public.partner_status NOT NULL DEFAULT 'active',
  address         text,
  notes           text,
  user_id         uuid REFERENCES public.profiles (id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz
);

CREATE INDEX partners_company_idx ON public.partners (company_id) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- financial_years (Indian FY Apr–Mar)
-- ---------------------------------------------------------------------------
CREATE TABLE public.financial_years (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  code            text NOT NULL,          -- e.g. 2026-27
  label           text NOT NULL,          -- e.g. FY 2026-27
  start_date      date NOT NULL,          -- Apr 1
  end_date        date NOT NULL,          -- Mar 31
  is_current      boolean NOT NULL DEFAULT false,
  is_closed       boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_by      uuid REFERENCES public.profiles (id),
  updated_by      uuid REFERENCES public.profiles (id),
  deleted_at      timestamptz,
  CONSTRAINT financial_years_dates_chk CHECK (end_date > start_date),
  CONSTRAINT financial_years_company_code_key UNIQUE (company_id, code)
);

CREATE INDEX financial_years_company_idx
  ON public.financial_years (company_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX financial_years_one_current_uidx
  ON public.financial_years (company_id)
  WHERE is_current = true AND deleted_at IS NULL;

COMMENT ON TABLE public.financial_years IS
  'Indian financial years (1 Apr – 31 Mar). Application displays Asia/Kolkata.';

-- ---------------------------------------------------------------------------
-- document_sequences (concurrency-safe numbering via FOR UPDATE)
-- ---------------------------------------------------------------------------
CREATE TABLE public.document_sequences (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES public.companies (id),
  financial_year_id uuid NOT NULL REFERENCES public.financial_years (id),
  doc_type          public.document_type_code NOT NULL,
  prefix_override   text,                 -- optional; else companies.invoice_prefix
  last_number       integer NOT NULL DEFAULT 0 CHECK (last_number >= 0),
  pad_length        smallint NOT NULL DEFAULT 4 CHECK (pad_length BETWEEN 1 AND 10),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT document_sequences_company_fy_type_key
    UNIQUE (company_id, financial_year_id, doc_type)
);

CREATE INDEX document_sequences_company_idx ON public.document_sequences (company_id);
