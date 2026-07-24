-- =============================================================================
-- 00012_storage.sql
-- Storage buckets + RLS policies
-- Buckets: company-assets, documents, expense-receipts, invoice-pdfs
-- Path convention: {company_id}/...
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'company-assets',
    'company-assets',
    false,
    5242880, -- 5 MB
    ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml']
  ),
  (
    'documents',
    'documents',
    false,
    20971520, -- 20 MB
    ARRAY[
      'application/pdf',
      'image/png', 'image/jpeg', 'image/webp',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    ]
  ),
  (
    'expense-receipts',
    'expense-receipts',
    false,
    10485760, -- 10 MB
    ARRAY['application/pdf', 'image/png', 'image/jpeg', 'image/webp']
  ),
  (
    'invoice-pdfs',
    'invoice-pdfs',
    false,
    10485760, -- 10 MB
    ARRAY['application/pdf']
  )
ON CONFLICT (id) DO NOTHING;

-- Helper: first folder segment = company_id
CREATE OR REPLACE FUNCTION public.storage_company_id(object_name text)
RETURNS uuid
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  part text;
BEGIN
  part := split_part(object_name, '/', 1);
  IF part ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RETURN part::uuid;
  END IF;
  RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.storage_company_id(text) TO authenticated, anon, service_role;

-- company-assets
CREATE POLICY company_assets_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'company-assets'
    AND public.is_company_member(public.storage_company_id(name))
    AND public.has_permission(public.storage_company_id(name), 'company_settings', 'read')
  );

CREATE POLICY company_assets_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'company-assets'
    AND public.has_permission(public.storage_company_id(name), 'company_settings', 'update')
  );

CREATE POLICY company_assets_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'company-assets'
    AND public.has_permission(public.storage_company_id(name), 'company_settings', 'update')
  )
  WITH CHECK (
    bucket_id = 'company-assets'
    AND public.has_permission(public.storage_company_id(name), 'company_settings', 'update')
  );

CREATE POLICY company_assets_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'company-assets'
    AND public.has_permission(public.storage_company_id(name), 'company_settings', 'update')
  );

-- documents
CREATE POLICY documents_bucket_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'documents'
    AND public.has_permission(public.storage_company_id(name), 'documents', 'read')
  );

CREATE POLICY documents_bucket_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND public.has_permission(public.storage_company_id(name), 'documents', 'create')
  );

CREATE POLICY documents_bucket_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'documents'
    AND public.has_permission(public.storage_company_id(name), 'documents', 'update')
  )
  WITH CHECK (
    bucket_id = 'documents'
    AND public.has_permission(public.storage_company_id(name), 'documents', 'update')
  );

CREATE POLICY documents_bucket_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'documents'
    AND public.has_permission(public.storage_company_id(name), 'documents', 'delete')
  );

-- expense-receipts
CREATE POLICY expense_receipts_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'expense-receipts'
    AND public.has_permission(public.storage_company_id(name), 'expenses', 'read')
  );

CREATE POLICY expense_receipts_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'expense-receipts'
    AND public.has_permission(public.storage_company_id(name), 'expenses', 'create')
  );

CREATE POLICY expense_receipts_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'expense-receipts'
    AND public.has_permission(public.storage_company_id(name), 'expenses', 'update')
  )
  WITH CHECK (
    bucket_id = 'expense-receipts'
    AND public.has_permission(public.storage_company_id(name), 'expenses', 'update')
  );

CREATE POLICY expense_receipts_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'expense-receipts'
    AND public.has_permission(public.storage_company_id(name), 'expenses', 'delete')
  );

-- invoice-pdfs
CREATE POLICY invoice_pdfs_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'invoice-pdfs'
    AND public.has_permission(public.storage_company_id(name), 'invoices', 'read')
  );

CREATE POLICY invoice_pdfs_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'invoice-pdfs'
    AND public.has_permission(public.storage_company_id(name), 'invoices', 'create')
  );

CREATE POLICY invoice_pdfs_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'invoice-pdfs'
    AND public.has_permission(public.storage_company_id(name), 'invoices', 'update')
  )
  WITH CHECK (
    bucket_id = 'invoice-pdfs'
    AND public.has_permission(public.storage_company_id(name), 'invoices', 'update')
  );

CREATE POLICY invoice_pdfs_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'invoice-pdfs'
    AND public.has_permission(public.storage_company_id(name), 'invoices', 'delete')
  );
