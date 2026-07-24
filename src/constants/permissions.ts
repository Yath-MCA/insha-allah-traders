/**
 * Role and permission keys mirroring supabase/seed.sql.
 * RLS + has_permission() remain the source of truth; this drives UI gating.
 */

export const ROLES = [
  'Super Admin',
  'Partner',
  'Admin',
  'Accountant',
  'Sales',
  'Purchase',
  'Store Manager',
  'Production Manager',
  'Quality Manager',
  'Viewer',
] as const

export type RoleName = (typeof ROLES)[number]

export const ROLE_SLUGS = {
  'Super Admin': 'super_admin',
  Partner: 'partner',
  Admin: 'admin',
  Accountant: 'accountant',
  Sales: 'sales',
  Purchase: 'purchase',
  'Store Manager': 'store_manager',
  'Production Manager': 'production_manager',
  'Quality Manager': 'quality_manager',
  Viewer: 'viewer',
} as const satisfies Record<RoleName, string>

export type RoleSlug = (typeof ROLE_SLUGS)[RoleName]

export const PERMISSION_ACTIONS = [
  'read',
  'create',
  'update',
  'delete',
  'approve',
  'issue',
  'cancel',
] as const

export type PermissionAction = (typeof PERMISSION_ACTIONS)[number]

/** Resources seeded in public.permissions (see seed.sql) */
export const PERMISSION_RESOURCES = [
  'companies',
  'company_settings',
  'bank_accounts',
  'partners',
  'financial_years',
  'document_sequences',
  'users',
  'roles',
  'customers',
  'vendors',
  'products',
  'gst_rates',
  'units',
  'warehouses',
  'quotations',
  'sales_orders',
  'delivery_challans',
  'invoices',
  'credit_notes',
  'debit_notes',
  'customer_payments',
  'purchase_requisitions',
  'purchase_orders',
  'goods_receipts',
  'purchase_invoices',
  'vendor_payments',
  'expenses',
  'inventory',
  'manufacturing',
  'tooling',
  'quality',
  'documents',
  'audit_logs',
] as const

export type PermissionResource = (typeof PERMISSION_RESOURCES)[number]

export type PermissionKey = `${PermissionResource}:${PermissionAction}`

export function permissionKey(
  resource: string,
  action: string,
): PermissionKey {
  return `${resource}:${action}` as PermissionKey
}

/** UI-facing summary of seed grants (not exhaustive for every action). */
export const ROLE_PERMISSION_SUMMARY: Partial<
  Record<RoleSlug, readonly PermissionKey[]>
> = {
  super_admin: PERMISSION_RESOURCES.flatMap((r) =>
    PERMISSION_ACTIONS.map((a) => permissionKey(r, a)),
  ),
  partner: [
    'companies:read',
    'companies:update',
    'company_settings:read',
    'company_settings:update',
    'bank_accounts:read',
    'bank_accounts:create',
    'bank_accounts:update',
    'partners:read',
    'partners:create',
    'partners:update',
    'partners:delete',
    'financial_years:read',
    'financial_years:create',
    'financial_years:update',
    'audit_logs:read',
    'invoices:read',
    'expenses:read',
    'inventory:read',
    'manufacturing:read',
  ],
  admin: [
    'companies:read',
    'companies:update',
    'company_settings:read',
    'company_settings:update',
    'bank_accounts:read',
    'bank_accounts:create',
    'bank_accounts:update',
    'bank_accounts:delete',
    'partners:read',
    'partners:create',
    'partners:update',
    'partners:delete',
    'financial_years:read',
    'financial_years:create',
    'financial_years:update',
    'users:read',
    'users:create',
    'users:update',
    'users:delete',
    'roles:read',
    'audit_logs:read',
  ],
  accountant: [
    'company_settings:read',
    'bank_accounts:read',
    'financial_years:read',
    'invoices:read',
    'expenses:read',
    'audit_logs:read',
  ],
  sales: [
    'customers:read',
    'quotations:read',
    'quotations:create',
    'sales_orders:read',
    'invoices:read',
  ],
  purchase: [
    'vendors:read',
    'purchase_orders:read',
    'purchase_orders:create',
    'goods_receipts:read',
  ],
  store_manager: [
    'inventory:read',
    'inventory:update',
    'warehouses:read',
    'goods_receipts:read',
  ],
  production_manager: [
    'manufacturing:read',
    'manufacturing:create',
    'manufacturing:update',
  ],
  quality_manager: [
    'quality:read',
    'quality:create',
    'quality:update',
    'tooling:read',
  ],
  viewer: PERMISSION_RESOURCES.map((r) => permissionKey(r, 'read')),
}
