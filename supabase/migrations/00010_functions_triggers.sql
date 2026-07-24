-- =============================================================================
-- 00010_functions_triggers.sql
-- updated_at, audit fields, FY helpers, next_document_number, GST split,
-- soft-delete guards, signup profile trigger, audit writers
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Utility: set updated_at
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Utility: set created_by / updated_by from auth.uid()
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_audit_fields()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.created_by IS NULL THEN
      NEW.created_by := uid;
    END IF;
    NEW.updated_by := COALESCE(NEW.updated_by, uid);
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_by := COALESCE(uid, NEW.updated_by);
    -- Preserve created_by
    NEW.created_by := OLD.created_by;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Signup → profile
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Indian FY helpers (Apr 1 – Mar 31, Asia/Kolkata)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.ist_today()
RETURNS date
LANGUAGE sql
STABLE
AS $$
  SELECT (timezone('Asia/Kolkata', now()))::date;
$$;

CREATE OR REPLACE FUNCTION public.financial_year_bounds(p_date date DEFAULT public.ist_today())
RETURNS TABLE (fy_start date, fy_end date, fy_code text)
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT
    CASE
      WHEN EXTRACT(MONTH FROM p_date) >= 4
        THEN make_date(EXTRACT(YEAR FROM p_date)::int, 4, 1)
      ELSE make_date(EXTRACT(YEAR FROM p_date)::int - 1, 4, 1)
    END AS fy_start,
    CASE
      WHEN EXTRACT(MONTH FROM p_date) >= 4
        THEN make_date(EXTRACT(YEAR FROM p_date)::int + 1, 3, 31)
      ELSE make_date(EXTRACT(YEAR FROM p_date)::int, 3, 31)
    END AS fy_end,
    CASE
      WHEN EXTRACT(MONTH FROM p_date) >= 4
        THEN EXTRACT(YEAR FROM p_date)::int::text
             || '-'
             || right((EXTRACT(YEAR FROM p_date)::int + 1)::text, 2)
      ELSE (EXTRACT(YEAR FROM p_date)::int - 1)::text
             || '-'
             || right(EXTRACT(YEAR FROM p_date)::int::text, 2)
    END AS fy_code;
$$;

CREATE OR REPLACE FUNCTION public.ensure_financial_year(
  p_company_id uuid,
  p_date date DEFAULT public.ist_today()
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_bounds record;
  v_id uuid;
BEGIN
  SELECT * INTO v_bounds FROM public.financial_year_bounds(p_date);

  SELECT id INTO v_id
  FROM public.financial_years
  WHERE company_id = p_company_id
    AND code = v_bounds.fy_code
    AND deleted_at IS NULL;

  IF v_id IS NULL THEN
    INSERT INTO public.financial_years (
      company_id, code, label, start_date, end_date, is_current
    )
    VALUES (
      p_company_id,
      v_bounds.fy_code,
      'FY ' || v_bounds.fy_code,
      v_bounds.fy_start,
      v_bounds.fy_end,
      false
    )
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Concurrency-safe document numbering: PREFIX/FY/TYPE/0001
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.next_document_number(
  p_company_id uuid,
  p_doc_type public.document_type_code,
  p_date date DEFAULT public.ist_today()
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fy_id uuid;
  v_fy_code text;
  v_prefix text;
  v_pad smallint;
  v_next integer;
  v_seq_id uuid;
BEGIN
  IF p_company_id IS NULL THEN
    RAISE EXCEPTION 'company_id is required';
  END IF;

  v_fy_id := public.ensure_financial_year(p_company_id, p_date);

  SELECT code INTO v_fy_code
  FROM public.financial_years
  WHERE id = v_fy_id;

  SELECT COALESCE(c.invoice_prefix, 'DOC')
  INTO v_prefix
  FROM public.companies c
  WHERE c.id = p_company_id
    AND c.deleted_at IS NULL;

  IF v_prefix IS NULL THEN
    RAISE EXCEPTION 'Company % not found', p_company_id;
  END IF;

  -- Lock sequence row (create if missing)
  SELECT id INTO v_seq_id
  FROM public.document_sequences
  WHERE company_id = p_company_id
    AND financial_year_id = v_fy_id
    AND doc_type = p_doc_type
  FOR UPDATE;

  IF v_seq_id IS NULL THEN
    INSERT INTO public.document_sequences (
      company_id, financial_year_id, doc_type, last_number, pad_length
    )
    VALUES (p_company_id, v_fy_id, p_doc_type, 0, 4)
    ON CONFLICT (company_id, financial_year_id, doc_type) DO NOTHING;

    SELECT id INTO v_seq_id
    FROM public.document_sequences
    WHERE company_id = p_company_id
      AND financial_year_id = v_fy_id
      AND doc_type = p_doc_type
    FOR UPDATE;
  END IF;

  UPDATE public.document_sequences
  SET last_number = last_number + 1,
      updated_at = now()
  WHERE id = v_seq_id
  RETURNING last_number, pad_length, COALESCE(prefix_override, v_prefix)
  INTO v_next, v_pad, v_prefix;

  RETURN v_prefix
    || '/' || v_fy_code
    || '/' || p_doc_type::text
    || '/' || lpad(v_next::text, v_pad, '0');
END;
$$;

COMMENT ON FUNCTION public.next_document_number(uuid, public.document_type_code, date) IS
  'Returns concurrency-safe numbers like IAT/2026-27/INV/0001 using row lock on document_sequences.';

GRANT EXECUTE ON FUNCTION public.next_document_number(uuid, public.document_type_code, date) TO authenticated;

-- ---------------------------------------------------------------------------
-- GST split helper: same state → CGST+SGST; else IGST
-- Rates come from caller / gst_rates table — never hardcoded here.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.compute_gst_split(
  p_seller_state public.indian_state_code,
  p_place_of_supply public.indian_state_code,
  p_taxable_amount numeric,
  p_cgst_rate numeric,
  p_sgst_rate numeric,
  p_igst_rate numeric
)
RETURNS TABLE (
  tax_split public.tax_split_type,
  cgst_amount numeric,
  sgst_amount numeric,
  igst_amount numeric
)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF p_seller_state IS NULL OR p_place_of_supply IS NULL THEN
    -- Default to intra-state when incomplete; app should validate before issue
    tax_split := 'cgst_sgst';
    cgst_amount := round(COALESCE(p_taxable_amount, 0) * COALESCE(p_cgst_rate, 0) / 100.0, 2);
    sgst_amount := round(COALESCE(p_taxable_amount, 0) * COALESCE(p_sgst_rate, 0) / 100.0, 2);
    igst_amount := 0;
    RETURN NEXT;
    RETURN;
  END IF;

  IF p_seller_state = p_place_of_supply THEN
    tax_split := 'cgst_sgst';
    cgst_amount := round(COALESCE(p_taxable_amount, 0) * COALESCE(p_cgst_rate, 0) / 100.0, 2);
    sgst_amount := round(COALESCE(p_taxable_amount, 0) * COALESCE(p_sgst_rate, 0) / 100.0, 2);
    igst_amount := 0;
  ELSE
    tax_split := 'igst';
    cgst_amount := 0;
    sgst_amount := 0;
    igst_amount := round(COALESCE(p_taxable_amount, 0) * COALESCE(p_igst_rate, 0) / 100.0, 2);
  END IF;

  RETURN NEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.compute_gst_split(
  public.indian_state_code, public.indian_state_code, numeric, numeric, numeric, numeric
) TO authenticated;

-- ---------------------------------------------------------------------------
-- Soft-delete / hard-delete guards for issued financial documents
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_issued_financial_doc()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_status text;
  v_new jsonb;
  v_old jsonb;
  v_locked boolean := false;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_status := OLD.status::text;
    IF v_status IN ('issued', 'fulfilled', 'partially_fulfilled', 'closed') THEN
      RAISE EXCEPTION
        'Hard delete is not allowed for % documents in status % (id=%)',
        TG_TABLE_NAME, v_status, OLD.id
        USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN OLD;
  END IF;

  v_status := OLD.status::text;
  v_locked := v_status IN ('issued', 'fulfilled', 'partially_fulfilled', 'closed');

  IF v_locked THEN
    -- Soft-delete blocked for issued docs
    IF (to_jsonb(NEW) ? 'deleted_at')
       AND OLD.deleted_at IS NULL
       AND NEW.deleted_at IS NOT NULL THEN
      RAISE EXCEPTION
        'Soft delete is not allowed for issued % (id=%). Cancel the document instead.',
        TG_TABLE_NAME, OLD.id
        USING ERRCODE = 'restrict_violation';
    END IF;

    IF NEW.status::text = 'cancelled' AND OLD.status::text IN ('issued', 'fulfilled', 'partially_fulfilled') THEN
      IF to_jsonb(NEW) ? 'cancelled_at' THEN
        NEW.cancelled_at := COALESCE(NEW.cancelled_at, now());
      END IF;
      RETURN NEW;
    END IF;

    IF NEW.status::text IS DISTINCT FROM OLD.status::text THEN
      RAISE EXCEPTION
        'Invalid status transition for %: % → %',
        TG_TABLE_NAME, OLD.status, NEW.status
        USING ERRCODE = 'restrict_violation';
    END IF;

    -- Same status: allow payment reconciliation fields on invoices only
    v_old := to_jsonb(OLD) - 'updated_at' - 'updated_by';
    v_new := to_jsonb(NEW) - 'updated_at' - 'updated_by';

    IF TG_TABLE_NAME IN ('invoices', 'purchase_invoices') THEN
      v_old := v_old - 'amount_paid' - 'amount_due' - 'payment_status';
      v_new := v_new - 'amount_paid' - 'amount_due' - 'payment_status';
    END IF;

    IF v_old IS DISTINCT FROM v_new THEN
      RAISE EXCEPTION
        'Issued % cannot be edited directly (id=%). Cancel or use a privileged transition.',
        TG_TABLE_NAME, OLD.id
        USING ERRCODE = 'restrict_violation';
    END IF;
  END IF;

  IF OLD.status::text = 'cancelled' AND NEW.status::text IS DISTINCT FROM OLD.status::text THEN
    RAISE EXCEPTION 'Cancelled documents cannot be reopened via direct update';
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Generic audit logger
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.write_audit_log()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_company_id uuid;
  v_record_id uuid;
  v_old jsonb;
  v_new jsonb;
  v_action text;
  v_changed text[];
  v_row jsonb;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_old := to_jsonb(OLD);
    v_new := NULL;
    v_action := 'DELETE';
    v_record_id := OLD.id;
    v_row := v_old;
  ELSIF TG_OP = 'INSERT' THEN
    v_old := NULL;
    v_new := to_jsonb(NEW);
    v_action := 'INSERT';
    v_record_id := NEW.id;
    v_row := v_new;
  ELSE
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);
    v_record_id := NEW.id;
    v_row := v_new;

    IF (v_new ? 'deleted_at')
       AND (v_old->>'deleted_at') IS NULL
       AND (v_new->>'deleted_at') IS NOT NULL THEN
      v_action := 'SOFT_DELETE';
    ELSE
      v_action := 'UPDATE';
    END IF;

    SELECT array_agg(k)
    INTO v_changed
    FROM (
      SELECT key AS k
      FROM jsonb_each(v_old) o
      FULL OUTER JOIN jsonb_each(v_new) n USING (key)
      WHERE o.value IS DISTINCT FROM n.value
        AND key NOT IN ('updated_at', 'updated_by')
    ) s;
  END IF;

  IF v_row ? 'company_id' AND (v_row->>'company_id') IS NOT NULL THEN
    v_company_id := (v_row->>'company_id')::uuid;
  END IF;

  INSERT INTO public.audit_logs (
    company_id, table_name, record_id, action, old_data, new_data, changed_fields, user_id
  ) VALUES (
    v_company_id, TG_TABLE_NAME, v_record_id, v_action, v_old, v_new, v_changed, auth.uid()
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Attach updated_at + audit field triggers (tables with updated_at)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'companies','profiles','roles','user_roles','company_settings','bank_accounts','partners',
    'financial_years','document_sequences','units','product_categories','gst_rates','products',
    'customers','vendors','warehouses','locations','expense_categories',
    'quotations','quotation_items','sales_orders','sales_order_items',
    'delivery_challans','delivery_challan_items','invoices','invoice_items',
    'credit_notes','credit_note_items','debit_notes','debit_note_items',
    'customer_payments','purchase_requisitions','purchase_requisition_items',
    'purchase_orders','purchase_order_items','goods_receipts','goods_receipt_items',
    'purchase_invoices','purchase_invoice_items','vendor_payments','expenses',
    'inventory_balances','stock_adjustments','stock_adjustment_items',
    'stock_transfers','stock_transfer_items',
    'boms','bom_items','process_routes','route_operations','work_orders','work_order_materials',
    'production_entries','tools','tool_maintenance','inspections','inspection_items','ncrs',
    'documents'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%s_updated_at ON public.%I;
       CREATE TRIGGER trg_%s_updated_at
         BEFORE UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

-- created_by/updated_by on business tables that have those columns
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'companies','profiles','user_roles','company_settings','bank_accounts','partners',
    'financial_years','units','product_categories','gst_rates','products',
    'customers','vendors','warehouses','locations','expense_categories',
    'quotations','sales_orders','delivery_challans','invoices',
    'credit_notes','debit_notes','customer_payments',
    'purchase_requisitions','purchase_orders','goods_receipts','purchase_invoices',
    'vendor_payments','expenses','stock_adjustments','stock_transfers',
    'boms','process_routes','work_orders','production_entries',
    'tools','tool_maintenance','inspections','ncrs'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%s_audit_fields ON public.%I;
       CREATE TRIGGER trg_%s_audit_fields
         BEFORE INSERT OR UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.set_audit_fields();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

-- Issued-doc guards
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'invoices','credit_notes','debit_notes','purchase_invoices'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%s_issued_guard ON public.%I;
       CREATE TRIGGER trg_%s_issued_guard
         BEFORE UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.guard_issued_financial_doc();',
      t, t, t, t
    );
  END LOOP;
END;
$$;

-- Audit triggers on financial + master tables
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'companies','company_settings','bank_accounts','partners','financial_years',
    'customers','vendors','products','gst_rates','warehouses',
    'quotations','sales_orders','delivery_challans','invoices',
    'credit_notes','debit_notes','customer_payments',
    'purchase_orders','goods_receipts','purchase_invoices','vendor_payments','expenses',
    'stock_adjustments','stock_transfers','work_orders','ncrs','user_roles'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%s_audit_log ON public.%I;
       CREATE TRIGGER trg_%s_audit_log
         AFTER INSERT OR UPDATE OR DELETE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.write_audit_log();',
      t, t, t, t
    );
  END LOOP;
END;
$$;
