import type { LucideIcon } from 'lucide-react'
import {
  BarChart3,
  ClipboardList,
  Factory,
  FileText,
  Hammer,
  LayoutDashboard,
  Package,
  Settings,
  ShoppingCart,
  Shield,
  Users,
  Warehouse,
  Wrench,
} from 'lucide-react'

export type NavItem = {
  title: string
  href: string
  icon: LucideIcon
  /** Phase that delivers this module UI (1 = live) */
  phase: number
  /** Optional permission gate for highlighting / future filtering */
  permission?: { resource: string; action: string }
}

export type NavGroup = {
  label: string
  items: NavItem[]
}

/** Full IA under /app — Phase 1 routes work; later phases show Coming Soon. */
export const NAV_GROUPS: NavGroup[] = [
  {
    label: 'Overview',
    items: [
      { title: 'Dashboard', href: '/app', icon: LayoutDashboard, phase: 1 },
    ],
  },
  {
    label: 'Masters',
    items: [
      { title: 'Customers', href: '/app/customers', icon: Users, phase: 2 },
      { title: 'Vendors', href: '/app/vendors', icon: Users, phase: 2 },
      { title: 'Products', href: '/app/products', icon: Package, phase: 2 },
      { title: 'GST rates', href: '/app/gst-rates', icon: FileText, phase: 2 },
    ],
  },
  {
    label: 'Sales',
    items: [
      { title: 'Quotations', href: '/app/sales/quotations', icon: FileText, phase: 3 },
      { title: 'Sales orders', href: '/app/sales/orders', icon: ShoppingCart, phase: 3 },
      { title: 'Delivery challans', href: '/app/sales/delivery-challans', icon: ClipboardList, phase: 3 },
      { title: 'Invoices', href: '/app/sales/invoices', icon: FileText, phase: 3 },
      { title: 'Payments received', href: '/app/sales/payments', icon: FileText, phase: 3 },
    ],
  },
  {
    label: 'Purchase',
    items: [
      { title: 'Purchase orders', href: '/app/purchase/orders', icon: ShoppingCart, phase: 4 },
      { title: 'Goods receipts', href: '/app/purchase/grn', icon: ClipboardList, phase: 4 },
      { title: 'Purchase invoices', href: '/app/purchase/invoices', icon: FileText, phase: 4 },
      { title: 'Expenses', href: '/app/purchase/expenses', icon: FileText, phase: 4 },
      { title: 'Vendor payments', href: '/app/purchase/payments', icon: FileText, phase: 4 },
    ],
  },
  {
    label: 'Inventory',
    items: [
      { title: 'Stock ledger', href: '/app/inventory', icon: Warehouse, phase: 5 },
      { title: 'Warehouses', href: '/app/inventory/warehouses', icon: Warehouse, phase: 5 },
    ],
  },
  {
    label: 'Manufacturing',
    items: [
      { title: 'BOM & routes', href: '/app/manufacturing/bom', icon: Factory, phase: 6 },
      { title: 'Work orders', href: '/app/manufacturing/work-orders', icon: Hammer, phase: 6 },
    ],
  },
  {
    label: 'Quality & tooling',
    items: [
      { title: 'Tooling', href: '/app/tooling', icon: Wrench, phase: 7 },
      { title: 'Quality / NCR', href: '/app/quality', icon: Shield, phase: 7 },
    ],
  },
  {
    label: 'Reports',
    items: [
      { title: 'Reports', href: '/app/reports', icon: BarChart3, phase: 8 },
      {
        title: 'Audit logs',
        href: '/app/audit-logs',
        icon: ClipboardList,
        phase: 1,
        permission: { resource: 'audit_logs', action: 'read' },
      },
    ],
  },
  {
    label: 'Settings',
    items: [
      {
        title: 'Company',
        href: '/app/settings/company',
        icon: Settings,
        phase: 1,
        permission: { resource: 'companies', action: 'read' },
      },
      {
        title: 'Partners',
        href: '/app/settings/partners',
        icon: Users,
        phase: 1,
        permission: { resource: 'partners', action: 'read' },
      },
      {
        title: 'Users & roles',
        href: '/app/settings/users',
        icon: Users,
        phase: 1,
        permission: { resource: 'users', action: 'read' },
      },
      {
        title: 'Financial year',
        href: '/app/settings/financial-year',
        icon: FileText,
        phase: 1,
        permission: { resource: 'financial_years', action: 'read' },
      },
      { title: 'Profile', href: '/app/profile', icon: Users, phase: 1 },
    ],
  },
]
