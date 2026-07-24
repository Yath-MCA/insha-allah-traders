import { supabase } from '@/lib/supabase'
import type {
  AuditLog,
  BankAccount,
  Company,
  CompanySettings,
  FinancialYear,
  Partner,
  PermissionAction,
  PermissionRow,
  Profile,
  Role,
  UserRole,
} from '@/types'

/** PostgREST may type embedded relations as object or array; normalize to one. */
function one<T>(value: T | T[] | null | undefined): T | null {
  if (value == null) return null
  return Array.isArray(value) ? (value[0] ?? null) : value
}

function throwIfError(error: { message: string } | null): asserts error is null {
  if (error) throw new Error(error.message)
}

// ---------------------------------------------------------------------------
// Auth / profile
// ---------------------------------------------------------------------------

export async function getProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select(
      'id, email, full_name, phone, avatar_url, default_company_id, is_active, last_login_at, created_at, updated_at',
    )
    .eq('id', userId)
    .maybeSingle()
  throwIfError(error)
  return data as Profile | null
}

export async function updateProfile(
  userId: string,
  patch: Partial<Pick<Profile, 'full_name' | 'phone' | 'default_company_id'>>,
): Promise<Profile> {
  const { data, error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', userId)
    .select(
      'id, email, full_name, phone, avatar_url, default_company_id, is_active, last_login_at, created_at, updated_at',
    )
    .single()
  throwIfError(error)
  return data as Profile
}

export async function touchLastLogin(userId: string): Promise<void> {
  const { error } = await supabase
    .from('profiles')
    .update({ last_login_at: new Date().toISOString() })
    .eq('id', userId)
  throwIfError(error)
}

// ---------------------------------------------------------------------------
// Membership / RBAC
// ---------------------------------------------------------------------------

export async function getUserCompanyIds(): Promise<string[]> {
  const { data, error } = await supabase.rpc('get_user_company_ids')
  throwIfError(error)
  return (data as string[] | null) ?? []
}

export async function fetchCompany(companyId: string): Promise<Company | null> {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('id', companyId)
    .is('deleted_at', null)
    .maybeSingle()
  throwIfError(error)
  return data as Company | null
}

export async function fetchUserRoles(companyId: string, userId: string) {
  const { data, error } = await supabase
    .from('user_roles')
    .select(
      `
      id, user_id, company_id, role_id, is_active, deleted_at,
      roles ( id, code, name, description, is_system, sort_order )
    `,
    )
    .eq('company_id', companyId)
    .eq('user_id', userId)
    .eq('is_active', true)
    .is('deleted_at', null)
  throwIfError(error)
  return ((data ?? []) as unknown as UserRole[]).map((row) => ({
    ...row,
    roles: one(row.roles as Role | Role[] | null),
  }))
}

export async function fetchUserPermissions(
  companyId: string,
  userId: string,
): Promise<PermissionRow[]> {
  const roles = await fetchUserRoles(companyId, userId)
  if (roles.some((r) => r.roles?.code === 'super_admin')) {
    // Client treats super_admin as unrestricted; RLS also bypasses via has_permission
    return [{ resource: '*', action: 'read' as PermissionAction }]
  }

  const roleIds = roles.map((r) => r.role_id)
  if (roleIds.length === 0) return []

  const { data, error } = await supabase
    .from('role_permissions')
    .select(
      `
      permissions ( resource, action )
    `,
    )
    .in('role_id', roleIds)
  throwIfError(error)

  const rows: PermissionRow[] = []
  for (const row of data ?? []) {
    const perm = (row as { permissions: PermissionRow | PermissionRow[] | null })
      .permissions
    if (!perm) continue
    if (Array.isArray(perm)) rows.push(...perm)
    else rows.push(perm)
  }
  return rows
}

export async function listRoles(): Promise<Role[]> {
  const { data, error } = await supabase
    .from('roles')
    .select('id, code, name, description, is_system, sort_order')
    .is('deleted_at', null)
    .order('sort_order')
  throwIfError(error)
  return (data ?? []) as Role[]
}

// ---------------------------------------------------------------------------
// Company settings
// ---------------------------------------------------------------------------

export async function fetchCompanySettings(
  companyId: string,
): Promise<CompanySettings | null> {
  const { data, error } = await supabase
    .from('company_settings')
    .select('*')
    .eq('company_id', companyId)
    .maybeSingle()
  throwIfError(error)
  return data as CompanySettings | null
}

export async function updateCompany(
  companyId: string,
  patch: Partial<Company>,
): Promise<Company> {
  const { data, error } = await supabase
    .from('companies')
    .update(patch)
    .eq('id', companyId)
    .select('*')
    .single()
  throwIfError(error)
  return data as Company
}

export async function updateCompanySettings(
  companyId: string,
  patch: Partial<CompanySettings>,
): Promise<CompanySettings> {
  const { data, error } = await supabase
    .from('company_settings')
    .update(patch)
    .eq('company_id', companyId)
    .select('*')
    .single()
  throwIfError(error)
  return data as CompanySettings
}

// ---------------------------------------------------------------------------
// Bank accounts
// ---------------------------------------------------------------------------

export async function listBankAccounts(companyId: string): Promise<BankAccount[]> {
  const { data, error } = await supabase
    .from('bank_accounts')
    .select('*')
    .eq('company_id', companyId)
    .is('deleted_at', null)
    .order('is_primary', { ascending: false })
    .order('account_name')
  throwIfError(error)
  return (data ?? []) as BankAccount[]
}

export async function createBankAccount(
  input: Omit<
    BankAccount,
    'id' | 'created_at' | 'updated_at' | 'deleted_at'
  >,
): Promise<BankAccount> {
  if (input.is_primary) {
    await clearPrimaryBank(input.company_id)
  }
  const { data, error } = await supabase
    .from('bank_accounts')
    .insert(input)
    .select('*')
    .single()
  throwIfError(error)
  return data as BankAccount
}

export async function updateBankAccount(
  id: string,
  companyId: string,
  patch: Partial<BankAccount>,
): Promise<BankAccount> {
  if (patch.is_primary) {
    await clearPrimaryBank(companyId)
  }
  const { data, error } = await supabase
    .from('bank_accounts')
    .update(patch)
    .eq('id', id)
    .eq('company_id', companyId)
    .select('*')
    .single()
  throwIfError(error)
  return data as BankAccount
}

export async function softDeleteBankAccount(
  id: string,
  companyId: string,
): Promise<void> {
  const { error } = await supabase
    .from('bank_accounts')
    .update({ deleted_at: new Date().toISOString(), is_primary: false })
    .eq('id', id)
    .eq('company_id', companyId)
  throwIfError(error)
}

async function clearPrimaryBank(companyId: string): Promise<void> {
  const { error } = await supabase
    .from('bank_accounts')
    .update({ is_primary: false })
    .eq('company_id', companyId)
    .eq('is_primary', true)
    .is('deleted_at', null)
  throwIfError(error)
}

// ---------------------------------------------------------------------------
// Partners
// ---------------------------------------------------------------------------

export async function listPartners(companyId: string): Promise<Partner[]> {
  const { data, error } = await supabase
    .from('partners')
    .select('*')
    .eq('company_id', companyId)
    .is('deleted_at', null)
    .order('full_name')
  throwIfError(error)
  return (data ?? []) as Partner[]
}

export async function createPartner(
  input: Omit<Partner, 'id' | 'created_at' | 'updated_at' | 'deleted_at'>,
): Promise<Partner> {
  const { data, error } = await supabase
    .from('partners')
    .insert(input)
    .select('*')
    .single()
  throwIfError(error)
  return data as Partner
}

export async function updatePartner(
  id: string,
  companyId: string,
  patch: Partial<Partner>,
): Promise<Partner> {
  const { data, error } = await supabase
    .from('partners')
    .update(patch)
    .eq('id', id)
    .eq('company_id', companyId)
    .select('*')
    .single()
  throwIfError(error)
  return data as Partner
}

export async function softDeletePartner(
  id: string,
  companyId: string,
): Promise<void> {
  const { error } = await supabase
    .from('partners')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .eq('company_id', companyId)
  throwIfError(error)
}

// ---------------------------------------------------------------------------
// Financial years
// ---------------------------------------------------------------------------

export async function listFinancialYears(
  companyId: string,
): Promise<FinancialYear[]> {
  const { data, error } = await supabase
    .from('financial_years')
    .select('*')
    .eq('company_id', companyId)
    .is('deleted_at', null)
    .order('start_date', { ascending: false })
  throwIfError(error)
  return (data ?? []) as FinancialYear[]
}

export async function setCurrentFinancialYear(
  companyId: string,
  financialYearId: string,
): Promise<void> {
  const { error: clearError } = await supabase
    .from('financial_years')
    .update({ is_current: false })
    .eq('company_id', companyId)
    .eq('is_current', true)
    .is('deleted_at', null)
  throwIfError(clearError)

  const { error } = await supabase
    .from('financial_years')
    .update({ is_current: true })
    .eq('id', financialYearId)
    .eq('company_id', companyId)
  throwIfError(error)
}

export async function ensureFinancialYear(
  companyId: string,
  asOfDate?: string,
): Promise<FinancialYear> {
  const { data, error } = await supabase.rpc('ensure_financial_year', {
    p_company_id: companyId,
    p_date: asOfDate ?? null,
  })
  throwIfError(error)
  const id = data as string
  const { data: fy, error: fyError } = await supabase
    .from('financial_years')
    .select('*')
    .eq('id', id)
    .single()
  throwIfError(fyError)
  return fy as FinancialYear
}

// ---------------------------------------------------------------------------
// Users / roles
// ---------------------------------------------------------------------------

export async function listCompanyUsers(companyId: string): Promise<UserRole[]> {
  const { data, error } = await supabase
    .from('user_roles')
    .select(
      `
      id, user_id, company_id, role_id, is_active, deleted_at,
      roles ( id, code, name, description, is_system, sort_order ),
      profiles:user_id ( id, email, full_name, phone )
    `,
    )
    .eq('company_id', companyId)
    .is('deleted_at', null)
    .order('created_at')
  throwIfError(error)
  return ((data ?? []) as unknown as UserRole[]).map((row) => ({
    ...row,
    roles: one(row.roles as Role | Role[] | null),
    profiles: one(
      row.profiles as
        | Pick<Profile, 'id' | 'email' | 'full_name' | 'phone'>
        | Pick<Profile, 'id' | 'email' | 'full_name' | 'phone'>[]
        | null,
    ),
  }))
}

export async function assignUserRole(input: {
  user_id: string
  company_id: string
  role_id: string
}): Promise<UserRole> {
  const { data, error } = await supabase
    .from('user_roles')
    .upsert(
      {
        user_id: input.user_id,
        company_id: input.company_id,
        role_id: input.role_id,
        is_active: true,
        deleted_at: null,
      },
      { onConflict: 'user_id,company_id,role_id' },
    )
    .select(
      `
      id, user_id, company_id, role_id, is_active, deleted_at,
      roles ( id, code, name, description, is_system, sort_order ),
      profiles:user_id ( id, email, full_name, phone )
    `,
    )
    .single()
  throwIfError(error)
  const row = data as unknown as UserRole
  return {
    ...row,
    roles: one(row.roles as Role | Role[] | null),
    profiles: one(
      row.profiles as
        | Pick<Profile, 'id' | 'email' | 'full_name' | 'phone'>
        | Pick<Profile, 'id' | 'email' | 'full_name' | 'phone'>[]
        | null,
    ),
  }
}

export async function deactivateUserRole(id: string): Promise<void> {
  const { error } = await supabase
    .from('user_roles')
    .update({ is_active: false, deleted_at: new Date().toISOString() })
    .eq('id', id)
  throwIfError(error)
}

// ---------------------------------------------------------------------------
// Audit logs
// ---------------------------------------------------------------------------

export async function listAuditLogs(
  companyId: string,
  limit = 100,
): Promise<AuditLog[]> {
  const { data, error } = await supabase
    .from('audit_logs')
    .select(
      `
      id, company_id, table_name, record_id, action, old_data, new_data,
      changed_fields, user_id, created_at,
      profiles:user_id ( id, email, full_name )
    `,
    )
    .eq('company_id', companyId)
    .order('created_at', { ascending: false })
    .limit(limit)
  throwIfError(error)
  return ((data ?? []) as unknown as AuditLog[]).map((row) => ({
    ...row,
    profiles: one(
      row.profiles as
        | Pick<Profile, 'id' | 'email' | 'full_name'>
        | Pick<Profile, 'id' | 'email' | 'full_name'>[]
        | null,
    ),
  }))
}

// ---------------------------------------------------------------------------
// Storage (company-assets)
// ---------------------------------------------------------------------------

const ASSETS_BUCKET = 'company-assets'

export async function uploadCompanyAsset(
  companyId: string,
  kind: 'logo' | 'signature',
  file: File,
): Promise<string> {
  const ext = file.name.split('.').pop()?.toLowerCase() || 'png'
  const path = `${companyId}/${kind}.${ext}`
  const { error } = await supabase.storage.from(ASSETS_BUCKET).upload(path, file, {
    upsert: true,
    contentType: file.type,
  })
  throwIfError(error)
  return path
}

export async function getCompanyAssetUrl(
  path: string | null | undefined,
): Promise<string | null> {
  if (!path) return null
  const { data, error } = await supabase.storage
    .from(ASSETS_BUCKET)
    .createSignedUrl(path, 60 * 60)
  if (error) return null
  return data.signedUrl
}
