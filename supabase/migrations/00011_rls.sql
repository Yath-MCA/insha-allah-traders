-- =============================================================================
-- 00011_rls.sql
-- Row Level Security: company isolation + has_permission
-- Viewer = read-only via permission matrix; anon cannot read company data
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_user_company_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT ur.company_id
  FROM public.user_roles ur
  WHERE ur.user_id = auth.uid()
    AND ur.is_active = true
    AND ur.deleted_at IS NULL;
$$;

CREATE OR REPLACE FUNCTION public.is_company_member(p_company_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    WHERE ur.user_id = auth.uid()
      AND ur.company_id = p_company_id
      AND ur.is_active = true
      AND ur.deleted_at IS NULL
  );
$$;

CREATE OR REPLACE FUNCTION public.has_permission(
  p_company_id uuid,
  p_resource text,
  p_action public.permission_action
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id AND r.deleted_at IS NULL
    JOIN public.role_permissions rp ON rp.role_id = r.id
    JOIN public.permissions p ON p.id = rp.permission_id
    WHERE ur.user_id = auth.uid()
      AND ur.company_id = p_company_id
      AND ur.is_active = true
      AND ur.deleted_at IS NULL
      AND (
        r.code = 'super_admin'
        OR (p.resource = p_resource AND p.action = p_action)
      )
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_user_company_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_company_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(uuid, text, public.permission_action) TO authenticated;

-- Grants (no auto-expose on newer Supabase)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO service_role;

-- Enable RLS everywhere in public
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.tablename);
  END LOOP;
END;
$$;

-- ---------------------------------------------------------------------------
-- Catalog tables (roles / permissions / role_permissions)
-- ---------------------------------------------------------------------------
CREATE POLICY roles_select ON public.roles
  FOR SELECT TO authenticated USING (deleted_at IS NULL);

CREATE POLICY permissions_select ON public.permissions
  FOR SELECT TO authenticated USING (true);

CREATE POLICY role_permissions_select ON public.role_permissions
  FOR SELECT TO authenticated USING (true);

-- ---------------------------------------------------------------------------
-- profiles: users see own profile; company admins see members of their companies
-- ---------------------------------------------------------------------------
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR id IN (
      SELECT ur.user_id
      FROM public.user_roles ur
      WHERE ur.company_id IN (SELECT public.get_user_company_ids())
        AND ur.deleted_at IS NULL
    )
  );

CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Inserts come from signup trigger (security definer) / service role

-- ---------------------------------------------------------------------------
-- Macro helpers via DO blocks for company-scoped tables
-- Pattern: SELECT if member + read perm; write ops need matching action
-- ---------------------------------------------------------------------------

-- companies
CREATE POLICY companies_select ON public.companies
  FOR SELECT TO authenticated
  USING (id IN (SELECT public.get_user_company_ids()) AND deleted_at IS NULL);

CREATE POLICY companies_update ON public.companies
  FOR UPDATE TO authenticated
  USING (public.has_permission(id, 'companies', 'update'))
  WITH CHECK (public.has_permission(id, 'companies', 'update'));

-- user_roles
CREATE POLICY user_roles_select ON public.user_roles
  FOR SELECT TO authenticated
  USING (company_id IN (SELECT public.get_user_company_ids()));

CREATE POLICY user_roles_insert ON public.user_roles
  FOR INSERT TO authenticated
  WITH CHECK (public.has_permission(company_id, 'users', 'create'));

CREATE POLICY user_roles_update ON public.user_roles
  FOR UPDATE TO authenticated
  USING (public.has_permission(company_id, 'users', 'update'))
  WITH CHECK (public.has_permission(company_id, 'users', 'update'));

CREATE POLICY user_roles_delete ON public.user_roles
  FOR DELETE TO authenticated
  USING (public.has_permission(company_id, 'users', 'delete'));

-- Generic company-scoped CRUD policy applicator
CREATE OR REPLACE FUNCTION public._apply_company_rls(
  p_table text,
  p_resource text,
  p_soft_delete boolean DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p_table || '_select', p_table);
  EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p_table || '_insert', p_table);
  EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p_table || '_update', p_table);
  EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p_table || '_delete', p_table);

  IF p_soft_delete THEN
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT TO authenticated
         USING (company_id IN (SELECT public.get_user_company_ids())
           AND public.has_permission(company_id, %L, ''read'')
           AND deleted_at IS NULL)',
      p_table || '_select', p_table, p_resource
    );
  ELSE
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT TO authenticated
         USING (company_id IN (SELECT public.get_user_company_ids())
           AND public.has_permission(company_id, %L, ''read''))',
      p_table || '_select', p_table, p_resource
    );
  END IF;

  EXECUTE format(
    'CREATE POLICY %I ON public.%I FOR INSERT TO authenticated
       WITH CHECK (public.has_permission(company_id, %L, ''create''))',
    p_table || '_insert', p_table, p_resource
  );

  EXECUTE format(
    'CREATE POLICY %I ON public.%I FOR UPDATE TO authenticated
       USING (public.has_permission(company_id, %L, ''update''))
       WITH CHECK (public.has_permission(company_id, %L, ''update''))',
    p_table || '_update', p_table, p_resource, p_resource
  );

  EXECUTE format(
    'CREATE POLICY %I ON public.%I FOR DELETE TO authenticated
       USING (public.has_permission(company_id, %L, ''delete''))',
    p_table || '_delete', p_table, p_resource
  );
END;
$$;

-- Child tables: same company_id pattern
DO $$
DECLARE
  rec record;
BEGIN
  FOR rec IN
    SELECT * FROM (VALUES
      -- settings / company
      ('company_settings', 'company_settings', false),
      ('bank_accounts', 'bank_accounts', true),
      ('partners', 'partners', true),
      ('financial_years', 'financial_years', true),
      ('document_sequences', 'document_sequences', false),
      -- masters
      ('units', 'units', true),
      ('product_categories', 'products', true),
      ('gst_rates', 'gst_rates', true),
      ('products', 'products', true),
      ('customers', 'customers', true),
      ('vendors', 'vendors', true),
      ('warehouses', 'warehouses', true),
      ('locations', 'warehouses', true),
      ('expense_categories', 'expenses', true),
      -- sales
      ('quotations', 'quotations', true),
      ('quotation_items', 'quotations', false),
      ('sales_orders', 'sales_orders', true),
      ('sales_order_items', 'sales_orders', false),
      ('delivery_challans', 'delivery_challans', true),
      ('delivery_challan_items', 'delivery_challans', false),
      ('invoices', 'invoices', true),
      ('invoice_items', 'invoices', false),
      ('credit_notes', 'credit_notes', true),
      ('credit_note_items', 'credit_notes', false),
      ('debit_notes', 'debit_notes', true),
      ('debit_note_items', 'debit_notes', false),
      ('customer_payments', 'customer_payments', true),
      ('customer_payment_allocations', 'customer_payments', false),
      -- purchase
      ('purchase_requisitions', 'purchase_requisitions', true),
      ('purchase_requisition_items', 'purchase_requisitions', false),
      ('purchase_orders', 'purchase_orders', true),
      ('purchase_order_items', 'purchase_orders', false),
      ('goods_receipts', 'goods_receipts', true),
      ('goods_receipt_items', 'goods_receipts', false),
      ('purchase_invoices', 'purchase_invoices', true),
      ('purchase_invoice_items', 'purchase_invoices', false),
      ('vendor_payments', 'vendor_payments', true),
      ('vendor_payment_allocations', 'vendor_payments', false),
      ('expenses', 'expenses', true),
      -- inventory
      ('inventory_balances', 'inventory', false),
      ('inventory_transactions', 'inventory', false),
      ('stock_adjustments', 'inventory', true),
      ('stock_adjustment_items', 'inventory', false),
      ('stock_transfers', 'inventory', true),
      ('stock_transfer_items', 'inventory', false),
      -- manufacturing
      ('boms', 'manufacturing', true),
      ('bom_items', 'manufacturing', false),
      ('process_routes', 'manufacturing', true),
      ('route_operations', 'manufacturing', false),
      ('work_orders', 'manufacturing', true),
      ('work_order_materials', 'manufacturing', false),
      ('production_entries', 'manufacturing', true),
      ('production_consumptions', 'manufacturing', false),
      -- tooling / quality
      ('tools', 'tooling', true),
      ('tool_maintenance', 'tooling', true),
      ('inspections', 'quality', true),
      ('inspection_items', 'quality', false),
      ('ncrs', 'quality', true),
      -- documents
      ('documents', 'documents', true)
    ) AS t(tbl, resource, soft)
  LOOP
    PERFORM public._apply_company_rls(rec.tbl, rec.resource, rec.soft);
  END LOOP;
END;
$$;

-- audit_logs: read-only for users with audit_logs.read; no client writes
CREATE POLICY audit_logs_select ON public.audit_logs
  FOR SELECT TO authenticated
  USING (
    company_id IN (SELECT public.get_user_company_ids())
    AND public.has_permission(company_id, 'audit_logs', 'read')
  );

-- Inserts only via security definer trigger (table owner / definer bypasses RLS
-- when function owner is postgres/supabase_admin). Explicit deny for authenticated writes:
-- (no INSERT/UPDATE/DELETE policies for authenticated)

-- inventory_transactions: allow insert with create perm (ledger append)
-- already applied via _apply_company_rls

-- Drop helper applicator (optional keep for future migrations — keep it)
COMMENT ON FUNCTION public._apply_company_rls(text, text, boolean) IS
  'Internal helper used during migrations to attach standard company RLS policies.';

-- Ensure anon has zero table access beyond what grants allow (we did not GRANT to anon)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
