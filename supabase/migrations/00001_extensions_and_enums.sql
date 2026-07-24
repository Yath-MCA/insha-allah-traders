-- =============================================================================
-- 00001_extensions_and_enums.sql
-- Extensions and shared enums for Insha Allah Traders ERP
-- =============================================================================

-- Prefer gen_random_uuid from pgcrypto/pg15+
CREATE SCHEMA IF NOT EXISTS extensions;

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA extensions;

-- Make trgm operator class visible to subsequent statements in this migration chain
SET search_path TO public, extensions;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

CREATE TYPE public.business_type AS ENUM (
  'proprietorship',
  'partnership',
  'llp',
  'private_limited',
  'public_limited',
  'other'
);

CREATE TYPE public.indian_state_code AS ENUM (
  'AN', 'AP', 'AR', 'AS', 'BR', 'CH', 'CT', 'DL', 'DN', 'GA',
  'GJ', 'HP', 'HR', 'JH', 'JK', 'KA', 'KL', 'LA', 'LD', 'MH',
  'ML', 'MN', 'MP', 'MZ', 'NL', 'OD', 'PB', 'PY', 'RJ', 'SK',
  'TN', 'TS', 'UK', 'UP', 'WB'
);

CREATE TYPE public.permission_action AS ENUM (
  'read',
  'create',
  'update',
  'delete',
  'approve',
  'issue',
  'cancel'
);

CREATE TYPE public.document_status AS ENUM (
  'draft',
  'submitted',
  'approved',
  'issued',
  'partially_fulfilled',
  'fulfilled',
  'closed',
  'cancelled',
  'rejected'
);

CREATE TYPE public.gst_treatment AS ENUM (
  'taxable',
  'exempt',
  'nil_rated',
  'non_gst',
  'zero_rated'
);

CREATE TYPE public.tax_split_type AS ENUM (
  'cgst_sgst',
  'igst'
);

CREATE TYPE public.product_type AS ENUM (
  'raw_material',
  'semi_finished',
  'finished_goods',
  'consumable',
  'service',
  'tool',
  'scrap'
);

CREATE TYPE public.warehouse_type AS ENUM (
  'raw_material',
  'wip',
  'finished_goods',
  'tool_room',
  'scrap',
  'general'
);

CREATE TYPE public.inventory_txn_type AS ENUM (
  'receipt',
  'issue',
  'transfer_in',
  'transfer_out',
  'adjustment_in',
  'adjustment_out',
  'production_issue',
  'production_receipt',
  'return_in',
  'return_out'
);

CREATE TYPE public.payment_mode AS ENUM (
  'cash',
  'cheque',
  'neft',
  'rtgs',
  'imps',
  'upi',
  'card',
  'other'
);

CREATE TYPE public.payment_status AS ENUM (
  'unpaid',
  'partial',
  'paid',
  'overdue',
  'cancelled'
);

CREATE TYPE public.partner_status AS ENUM (
  'active',
  'inactive'
);

CREATE TYPE public.work_order_status AS ENUM (
  'draft',
  'planned',
  'released',
  'in_progress',
  'completed',
  'closed',
  'cancelled'
);

CREATE TYPE public.tool_status AS ENUM (
  'available',
  'in_use',
  'under_maintenance',
  'retired',
  'scrapped'
);

CREATE TYPE public.maintenance_type AS ENUM (
  'preventive',
  'corrective',
  'calibration',
  'other'
);

CREATE TYPE public.inspection_result AS ENUM (
  'pass',
  'fail',
  'conditional',
  'pending'
);

CREATE TYPE public.ncr_status AS ENUM (
  'open',
  'under_review',
  'corrective_action',
  'closed',
  'void'
);

CREATE TYPE public.ncr_severity AS ENUM (
  'minor',
  'major',
  'critical'
);

CREATE TYPE public.document_type_code AS ENUM (
  'QUO',   -- quotation
  'SO',    -- sales order
  'DC',    -- delivery challan
  'INV',   -- tax invoice
  'CN',    -- credit note
  'DN',    -- debit note
  'PR',    -- purchase requisition
  'PO',    -- purchase order
  'GRN',   -- goods receipt
  'PINV',  -- purchase invoice
  'EXP',   -- expense
  'CPAY',  -- customer payment
  'VPAY',  -- vendor payment
  'WO',    -- work order
  'ST',    -- stock transfer
  'SA',    -- stock adjustment
  'NCR',   -- non-conformance
  'INS'    -- inspection
);

CREATE TYPE public.party_type AS ENUM (
  'customer',
  'vendor',
  'both'
);

COMMENT ON TYPE public.document_type_code IS
  'Short codes used in document numbering, e.g. IAT/2026-27/INV/0001';
