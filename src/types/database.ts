/** Domain types aligned with supabase/migrations (Phase 1). */

export type Uuid = string

export type BusinessType =
  | 'proprietorship'
  | 'partnership'
  | 'llp'
  | 'private_limited'
  | 'public_limited'
  | 'other'

export type IndianStateCode =
  | 'AN'
  | 'AP'
  | 'AR'
  | 'AS'
  | 'BR'
  | 'CH'
  | 'CT'
  | 'DL'
  | 'DN'
  | 'GA'
  | 'GJ'
  | 'HP'
  | 'HR'
  | 'JH'
  | 'JK'
  | 'KA'
  | 'KL'
  | 'LA'
  | 'LD'
  | 'MH'
  | 'ML'
  | 'MN'
  | 'MP'
  | 'MZ'
  | 'NL'
  | 'OD'
  | 'PB'
  | 'PY'
  | 'RJ'
  | 'SK'
  | 'TN'
  | 'TS'
  | 'UK'
  | 'UP'
  | 'WB'

export type PartnerStatus = 'active' | 'inactive'

export type PermissionAction =
  | 'read'
  | 'create'
  | 'update'
  | 'delete'
  | 'approve'
  | 'issue'
  | 'cancel'

export type Company = {
  id: Uuid
  legal_name: string
  trade_name: string | null
  business_type: BusinessType
  gstin: string | null
  pan: string | null
  tan: string | null
  cin: string | null
  email: string | null
  phone: string | null
  website: string | null
  address_line1: string | null
  address_line2: string | null
  city: string | null
  district: string | null
  state_code: IndianStateCode | null
  pincode: string | null
  country: string
  logo_path: string | null
  signature_path: string | null
  invoice_prefix: string
  is_active: boolean
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export type CompanySettings = {
  id: Uuid
  company_id: Uuid
  financial_year_start_month: number
  currency_code: string
  timezone: string
  date_format: string
  default_payment_terms_days: number
  enable_gst: boolean
  invoice_terms: string | null
  invoice_notes: string | null
  quotation_validity_days: number
  low_stock_alert: boolean
  extra: Record<string, unknown>
  created_at: string
  updated_at: string
}

export type Profile = {
  id: Uuid
  email: string | null
  full_name: string | null
  phone: string | null
  avatar_url: string | null
  default_company_id: Uuid | null
  is_active: boolean
  last_login_at: string | null
  created_at: string
  updated_at: string
}

export type Role = {
  id: Uuid
  code: string
  name: string
  description: string | null
  is_system: boolean
  sort_order: number
}

export type UserRole = {
  id: Uuid
  user_id: Uuid
  company_id: Uuid
  role_id: Uuid
  is_active: boolean
  deleted_at: string | null
  roles?: Role | null
  profiles?: Pick<Profile, 'id' | 'email' | 'full_name' | 'phone'> | null
}

export type BankAccount = {
  id: Uuid
  company_id: Uuid
  account_name: string
  bank_name: string
  branch_name: string | null
  account_number: string
  ifsc_code: string | null
  upi_id: string | null
  is_primary: boolean
  is_active: boolean
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export type Partner = {
  id: Uuid
  company_id: Uuid
  full_name: string
  pan: string | null
  email: string | null
  phone: string | null
  share_percent: number | null
  status: PartnerStatus
  address: string | null
  notes: string | null
  user_id: Uuid | null
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export type FinancialYear = {
  id: Uuid
  company_id: Uuid
  code: string
  label: string
  start_date: string
  end_date: string
  is_current: boolean
  is_closed: boolean
  created_at: string
  updated_at: string
  deleted_at: string | null
}

export type AuditLog = {
  id: Uuid
  company_id: Uuid | null
  table_name: string
  record_id: Uuid | null
  action: 'INSERT' | 'UPDATE' | 'DELETE' | 'SOFT_DELETE'
  old_data: Record<string, unknown> | null
  new_data: Record<string, unknown> | null
  changed_fields: string[] | null
  user_id: Uuid | null
  created_at: string
  profiles?: Pick<Profile, 'id' | 'email' | 'full_name'> | null
}

export type PermissionRow = {
  resource: string
  action: PermissionAction
}
