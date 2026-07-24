-- =============================================================================
-- 00009_documents_audit.sql
-- Document metadata + audit_logs
-- =============================================================================

CREATE TABLE public.documents (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES public.companies (id),
  bucket          text NOT NULL,
  path            text NOT NULL,
  file_name       text NOT NULL,
  mime_type       text,
  file_size       bigint CHECK (file_size IS NULL OR file_size >= 0),
  entity_type     text,
  entity_id       uuid,
  description     text,
  uploaded_by     uuid REFERENCES public.profiles (id),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  deleted_at      timestamptz,
  CONSTRAINT documents_bucket_path_key UNIQUE (bucket, path)
);

CREATE INDEX documents_company_idx ON public.documents (company_id) WHERE deleted_at IS NULL;
CREATE INDEX documents_entity_idx ON public.documents (entity_type, entity_id);

COMMENT ON TABLE public.documents IS
  'Metadata for files in Storage buckets (company-assets, documents, expense-receipts, invoice-pdfs).';

-- ---------------------------------------------------------------------------
-- audit_logs (append-only; no updated_at / soft delete)
-- ---------------------------------------------------------------------------
CREATE TABLE public.audit_logs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid REFERENCES public.companies (id),
  table_name    text NOT NULL,
  record_id     uuid,
  action        text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE')),
  old_data      jsonb,
  new_data      jsonb,
  changed_fields text[],
  user_id       uuid REFERENCES public.profiles (id),
  ip_address    inet,
  user_agent    text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX audit_logs_company_idx ON public.audit_logs (company_id, created_at DESC);
CREATE INDEX audit_logs_table_idx ON public.audit_logs (table_name, created_at DESC);
CREATE INDEX audit_logs_record_idx ON public.audit_logs (table_name, record_id);
CREATE INDEX audit_logs_user_idx ON public.audit_logs (user_id, created_at DESC);

COMMENT ON TABLE public.audit_logs IS
  'Immutable audit trail written by DB triggers on financial and master tables.';
