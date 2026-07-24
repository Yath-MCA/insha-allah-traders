-- =============================================================================
-- seed.sql — Phase 1 foundation seed for Insha Allah Traders ERP
--
-- Applied automatically on `supabase db reset` (see config.toml [db.seed]).
-- For a linked remote project: `psql` / SQL editor → run this file after migrations.
--
-- SUPER ADMIN BOOTSTRAP (required after first Auth user is created)
-- ---------------------------------------------------------------------------
-- 1. Create the user in Supabase Dashboard → Authentication → Users
--    (or: supabase auth signup / invite), note the user's UUID.
-- 2. Run (replace USER_UUID):
--
--   INSERT INTO public.user_roles (user_id, company_id, role_id)
--   VALUES (
--     'USER_UUID',
--     'a0000000-0000-4000-8000-000000000001',  -- Insha Allah Traders
--     'b0000000-0000-4000-8000-000000000001'   -- super_admin
--   )
--   ON CONFLICT (user_id, company_id, role_id) DO UPDATE
--     SET is_active = true, deleted_at = NULL;
--
--   UPDATE public.profiles
--   SET default_company_id = 'a0000000-0000-4000-8000-000000000001'
--   WHERE id = 'USER_UUID';
--
-- Do NOT put passwords or service-role keys in this file.
-- =============================================================================

-- Stable IDs for bootstrap scripts / docs
-- Company
--   a0000000-0000-4000-8000-000000000001  Insha Allah Traders
-- Roles b0000000-0000-4000-8000-00000000000N
-- Warehouses / units / categories use c/d/e prefixes below

-- ---------------------------------------------------------------------------
-- Company: Insha Allah Traders (Partnership, Tamil Nadu)
-- GSTIN/PAN left NULL — enter real values in Settings before production use.
-- ---------------------------------------------------------------------------
INSERT INTO public.companies (
  id, legal_name, trade_name, business_type, state_code, country,
  invoice_prefix, city, address_line1, is_active
) VALUES (
  'a0000000-0000-4000-8000-000000000001',
  'Insha Allah Traders',
  'Insha Allah Traders',
  'partnership',
  'TN',
  'IN',
  'IAT',
  NULL,
  NULL,
  true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.company_settings (
  company_id,
  financial_year_start_month,
  currency_code,
  timezone,
  date_format,
  enable_gst,
  invoice_terms
) VALUES (
  'a0000000-0000-4000-8000-000000000001',
  4,
  'INR',
  'Asia/Kolkata',
  'DD/MM/YYYY',
  true,
  'Goods once sold will not be taken back. Subject to Tamil Nadu jurisdiction.'
) ON CONFLICT (company_id) DO NOTHING;

-- Current Indian FY (Apr–Mar) based on seed-run date in IST
UPDATE public.financial_years
SET is_current = false
WHERE company_id = 'a0000000-0000-4000-8000-000000000001'
  AND is_current = true;

INSERT INTO public.financial_years (
  id, company_id, code, label, start_date, end_date, is_current
)
SELECT
  'a0000000-0000-4000-8000-000000000010',
  'a0000000-0000-4000-8000-000000000001',
  b.fy_code,
  'FY ' || b.fy_code,
  b.fy_start,
  b.fy_end,
  true
FROM public.financial_year_bounds(public.ist_today()) AS b
ON CONFLICT (company_id, code) DO UPDATE
  SET is_current = true,
      start_date = EXCLUDED.start_date,
      end_date = EXCLUDED.end_date,
      label = EXCLUDED.label;

-- ---------------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------------
INSERT INTO public.roles (id, code, name, description, is_system, sort_order) VALUES
  ('b0000000-0000-4000-8000-000000000001', 'super_admin', 'Super Admin', 'Full system access within assigned companies', true, 1),
  ('b0000000-0000-4000-8000-000000000002', 'partner', 'Partner', 'Firm partner — financial & strategic visibility', true, 2),
  ('b0000000-0000-4000-8000-000000000003', 'admin', 'Admin', 'Company administrator', true, 3),
  ('b0000000-0000-4000-8000-000000000004', 'accountant', 'Accountant', 'Books, payments, GST registers', true, 4),
  ('b0000000-0000-4000-8000-000000000005', 'sales', 'Sales', 'Quotations, orders, invoices', true, 5),
  ('b0000000-0000-4000-8000-000000000006', 'purchase', 'Purchase', 'PR, PO, GRN, purchase invoices', true, 6),
  ('b0000000-0000-4000-8000-000000000007', 'store_manager', 'Store Manager', 'Warehouses, stock, inventory ops', true, 7),
  ('b0000000-0000-4000-8000-000000000008', 'production_manager', 'Production Manager', 'BOM, routes, work orders', true, 8),
  ('b0000000-0000-4000-8000-000000000009', 'quality_manager', 'Quality Manager', 'Inspections & NCRs', true, 9),
  ('b0000000-0000-4000-8000-000000000010', 'viewer', 'Viewer', 'Read-only access', true, 10)
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Permissions matrix (resource × action)
-- ---------------------------------------------------------------------------
WITH resources(resource) AS (
  VALUES
    ('companies'),
    ('company_settings'),
    ('bank_accounts'),
    ('partners'),
    ('financial_years'),
    ('document_sequences'),
    ('users'),
    ('roles'),
    ('customers'),
    ('vendors'),
    ('products'),
    ('gst_rates'),
    ('units'),
    ('warehouses'),
    ('quotations'),
    ('sales_orders'),
    ('delivery_challans'),
    ('invoices'),
    ('credit_notes'),
    ('debit_notes'),
    ('customer_payments'),
    ('purchase_requisitions'),
    ('purchase_orders'),
    ('goods_receipts'),
    ('purchase_invoices'),
    ('vendor_payments'),
    ('expenses'),
    ('inventory'),
    ('manufacturing'),
    ('tooling'),
    ('quality'),
    ('documents'),
    ('audit_logs')
),
actions(action) AS (
  SELECT unnest(ENUM_RANGE(NULL::public.permission_action))
)
INSERT INTO public.permissions (resource, action, description)
SELECT r.resource, a.action, initcap(a.action::text) || ' ' || replace(r.resource, '_', ' ')
FROM resources r
CROSS JOIN actions a
ON CONFLICT (resource, action) DO NOTHING;

-- Role → permission grants
-- Helper: grant all actions on a resource to a role code
CREATE OR REPLACE FUNCTION public._seed_grant(
  p_role_code text,
  p_resource text,
  p_actions public.permission_action[]
)
RETURNS void
LANGUAGE sql
AS $$
  INSERT INTO public.role_permissions (role_id, permission_id)
  SELECT r.id, p.id
  FROM public.roles r
  JOIN public.permissions p ON p.resource = p_resource AND p.action = ANY (p_actions)
  WHERE r.code = p_role_code
  ON CONFLICT (role_id, permission_id) DO NOTHING;
$$;

-- Super Admin: all permissions (also bypasses via has_permission)
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.code = 'super_admin'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Viewer: read everywhere
INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.roles r
CROSS JOIN public.permissions p
WHERE r.code = 'viewer'
  AND p.action = 'read'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Partner: read all + limited company/partner updates
SELECT public._seed_grant('partner', 'companies', ARRAY['read','update']::public.permission_action[]);
SELECT public._seed_grant('partner', 'company_settings', ARRAY['read','update']::public.permission_action[]);
SELECT public._seed_grant('partner', 'bank_accounts', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('partner', 'partners', ARRAY['read','create','update','delete']::public.permission_action[]);
SELECT public._seed_grant('partner', 'financial_years', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('partner', 'audit_logs', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('partner', 'invoices', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('partner', 'expenses', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('partner', 'inventory', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('partner', 'manufacturing', ARRAY['read']::public.permission_action[]);

-- Admin: broad ops except maybe nothing — full CRUD on settings/users/masters + approve
DO $$
DECLARE
  res text;
  admin_resources text[] := ARRAY[
    'companies','company_settings','bank_accounts','partners','financial_years','document_sequences',
    'users','roles','customers','vendors','products','gst_rates','units','warehouses',
    'quotations','sales_orders','delivery_challans','invoices','credit_notes','debit_notes','customer_payments',
    'purchase_requisitions','purchase_orders','goods_receipts','purchase_invoices','vendor_payments','expenses',
    'inventory','manufacturing','tooling','quality','documents','audit_logs'
  ];
BEGIN
  FOREACH res IN ARRAY admin_resources LOOP
    PERFORM public._seed_grant(
      'admin',
      res,
      ARRAY['read','create','update','delete','approve','issue','cancel']::public.permission_action[]
    );
  END LOOP;
END;
$$;

-- Accountant
SELECT public._seed_grant('accountant', 'company_settings', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'bank_accounts', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'financial_years', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'customers', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'vendors', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'gst_rates', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'invoices', ARRAY['read','create','update','issue','cancel','approve']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'credit_notes', ARRAY['read','create','update','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'debit_notes', ARRAY['read','create','update','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'customer_payments', ARRAY['read','create','update','delete']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'purchase_invoices', ARRAY['read','create','update','issue','cancel','approve']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'vendor_payments', ARRAY['read','create','update','delete']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'expenses', ARRAY['read','create','update','delete','approve']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'audit_logs', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('accountant', 'documents', ARRAY['read','create']::public.permission_action[]);

-- Sales
SELECT public._seed_grant('sales', 'customers', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('sales', 'products', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('sales', 'gst_rates', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('sales', 'quotations', ARRAY['read','create','update','delete','approve','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('sales', 'sales_orders', ARRAY['read','create','update','delete','approve','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('sales', 'delivery_challans', ARRAY['read','create','update','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('sales', 'invoices', ARRAY['read','create','update','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('sales', 'credit_notes', ARRAY['read','create']::public.permission_action[]);
SELECT public._seed_grant('sales', 'customer_payments', ARRAY['read','create']::public.permission_action[]);
SELECT public._seed_grant('sales', 'inventory', ARRAY['read']::public.permission_action[]);

-- Purchase
SELECT public._seed_grant('purchase', 'vendors', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'products', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'gst_rates', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'purchase_requisitions', ARRAY['read','create','update','delete','approve','cancel']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'purchase_orders', ARRAY['read','create','update','delete','approve','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'goods_receipts', ARRAY['read','create','update','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'purchase_invoices', ARRAY['read','create','update','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'vendor_payments', ARRAY['read','create']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'expenses', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'inventory', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('purchase', 'warehouses', ARRAY['read']::public.permission_action[]);

-- Store Manager
SELECT public._seed_grant('store_manager', 'products', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('store_manager', 'warehouses', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('store_manager', 'inventory', ARRAY['read','create','update','approve','issue']::public.permission_action[]);
SELECT public._seed_grant('store_manager', 'goods_receipts', ARRAY['read','create','update','issue']::public.permission_action[]);
SELECT public._seed_grant('store_manager', 'delivery_challans', ARRAY['read','create','update','issue']::public.permission_action[]);
SELECT public._seed_grant('store_manager', 'manufacturing', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('store_manager', 'tooling', ARRAY['read','create','update']::public.permission_action[]);

-- Production Manager
SELECT public._seed_grant('production_manager', 'products', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('production_manager', 'inventory', ARRAY['read','create','update']::public.permission_action[]);
SELECT public._seed_grant('production_manager', 'manufacturing', ARRAY['read','create','update','delete','approve','issue','cancel']::public.permission_action[]);
SELECT public._seed_grant('production_manager', 'warehouses', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('production_manager', 'tooling', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('production_manager', 'quality', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('production_manager', 'sales_orders', ARRAY['read']::public.permission_action[]);

-- Quality Manager
SELECT public._seed_grant('quality_manager', 'products', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('quality_manager', 'quality', ARRAY['read','create','update','delete','approve','cancel']::public.permission_action[]);
SELECT public._seed_grant('quality_manager', 'manufacturing', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('quality_manager', 'goods_receipts', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('quality_manager', 'tooling', ARRAY['read']::public.permission_action[]);
SELECT public._seed_grant('quality_manager', 'documents', ARRAY['read','create']::public.permission_action[]);

DROP FUNCTION public._seed_grant(text, text, public.permission_action[]);

-- ---------------------------------------------------------------------------
-- Default warehouses
-- ---------------------------------------------------------------------------
INSERT INTO public.warehouses (id, company_id, code, name, warehouse_type, is_default, is_active) VALUES
  ('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'RM', 'Raw Material', 'raw_material', true, true),
  ('c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'WIP', 'Work In Progress', 'wip', false, true),
  ('c0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'FG', 'Finished Goods', 'finished_goods', false, true),
  ('c0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', 'TOOL', 'Tool Room', 'tool_room', false, true),
  ('c0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000001', 'SCRAP', 'Scrap', 'scrap', false, true)
ON CONFLICT (company_id, code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Default UOMs
-- ---------------------------------------------------------------------------
INSERT INTO public.units (company_id, code, name, description) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'NOS', 'Numbers', 'Count / pieces'),
  ('a0000000-0000-4000-8000-000000000001', 'KG', 'Kilogram', 'Weight'),
  ('a0000000-0000-4000-8000-000000000001', 'G', 'Gram', 'Weight'),
  ('a0000000-0000-4000-8000-000000000001', 'MT', 'Metric Ton', 'Weight'),
  ('a0000000-0000-4000-8000-000000000001', 'M', 'Metre', 'Length'),
  ('a0000000-0000-4000-8000-000000000001', 'MM', 'Millimetre', 'Length'),
  ('a0000000-0000-4000-8000-000000000001', 'SQM', 'Square Metre', 'Area'),
  ('a0000000-0000-4000-8000-000000000001', 'SET', 'Set', 'Assembled set'),
  ('a0000000-0000-4000-8000-000000000001', 'BOX', 'Box', 'Packaging'),
  ('a0000000-0000-4000-8000-000000000001', 'LTR', 'Litre', 'Volume')
ON CONFLICT (company_id, code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Expense categories
-- ---------------------------------------------------------------------------
INSERT INTO public.expense_categories (company_id, code, name, description) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'RENT', 'Rent', 'Factory / office rent'),
  ('a0000000-0000-4000-8000-000000000001', 'POWER', 'Power & Fuel', 'Electricity, diesel, gas'),
  ('a0000000-0000-4000-8000-000000000001', 'TRANSPORT', 'Transport', 'Freight and logistics'),
  ('a0000000-0000-4000-8000-000000000001', 'MAINT', 'Maintenance', 'Repairs and maintenance'),
  ('a0000000-0000-4000-8000-000000000001', 'SALARY', 'Salaries & Wages', 'Payroll related'),
  ('a0000000-0000-4000-8000-000000000001', 'CONSUMABLE', 'Consumables', 'Shop floor consumables'),
  ('a0000000-0000-4000-8000-000000000001', 'PROF_FEE', 'Professional Fees', 'CA, legal, consultancy'),
  ('a0000000-0000-4000-8000-000000000001', 'MISC', 'Miscellaneous', 'Other expenses')
ON CONFLICT (company_id, code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- GST rates: intentionally EMPTY of production rates.
-- Optional SAMPLE rows marked is_sample = true — NOT legal tax truth.
-- Admin must configure real rates (and HSN) before issuing tax invoices.
-- Uncomment below only for UI demos:
--
-- INSERT INTO public.gst_rates (
--   company_id, name, cgst_rate, sgst_rate, igst_rate, is_sample, notes, is_active
-- ) VALUES (
--   'a0000000-0000-4000-8000-000000000001',
--   'SAMPLE 18% (illustrative only)',
--   9, 9, 18, true,
--   'SAMPLE ONLY — replace with CA-approved rates before production use.',
--   false
-- );
-- ---------------------------------------------------------------------------

-- Disclaimer (stored for UI footer / settings):
COMMENT ON TABLE public.gst_rates IS
  'Company-configurable GST rates. Seed leaves this empty (or sample-only). This ERP is not a substitute for a CA or tax professional.';
