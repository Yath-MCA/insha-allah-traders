import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AppShell } from '@/components/layout/AppShell'
import { ComingSoonPage } from '@/components/shared/ComingSoonPage'
import {
  ForgotPasswordPage,
  LoginPage,
  ProfilePage,
  RequireAuth,
  RequirePermission,
  ResetPasswordPage,
} from '@/features/auth'
import {
  CompanySettingsPage,
  FinancialYearPage,
  PartnersPage,
  UsersPage,
} from '@/features/company'
import { HomePage as DashboardPage } from '@/features/dashboard/HomePage'
import { AuditLogsPage } from '@/features/audit/AuditLogsPage'
import {
  AboutPage,
  CapabilitiesPage,
  ContactPage,
  HomePage as WebsiteHomePage,
  WebsiteLayout,
} from '@/features/website'

function Soon({ title, phase }: { title: string; phase: number }) {
  return <ComingSoonPage title={title} phase={phase} />
}

export function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public company website */}
        <Route element={<WebsiteLayout />}>
          <Route index element={<WebsiteHomePage />} />
          <Route path="capabilities" element={<CapabilitiesPage />} />
          <Route path="about" element={<AboutPage />} />
          <Route path="contact" element={<ContactPage />} />
        </Route>

        {/* ERP auth entry (outside /app shell) */}
        <Route path="/login" element={<LoginPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />

        {/* Authenticated ERP */}
        <Route path="/app" element={<RequireAuth />}>
          <Route element={<AppShell />}>
            <Route index element={<DashboardPage />} />
            <Route path="profile" element={<ProfilePage />} />

            <Route
              path="settings/company"
              element={
                <RequirePermission resource="companies" action="read">
                  <CompanySettingsPage />
                </RequirePermission>
              }
            />
            <Route
              path="settings/partners"
              element={
                <RequirePermission resource="partners" action="read">
                  <PartnersPage />
                </RequirePermission>
              }
            />
            <Route
              path="settings/users"
              element={
                <RequirePermission resource="users" action="read">
                  <UsersPage />
                </RequirePermission>
              }
            />
            <Route
              path="settings/financial-year"
              element={
                <RequirePermission resource="financial_years" action="read">
                  <FinancialYearPage />
                </RequirePermission>
              }
            />
            <Route
              path="audit-logs"
              element={
                <RequirePermission resource="audit_logs" action="read">
                  <AuditLogsPage />
                </RequirePermission>
              }
            />

            {/* Phase 2+ stubs — full IA */}
            <Route path="customers" element={<Soon title="Customers" phase={2} />} />
            <Route path="vendors" element={<Soon title="Vendors" phase={2} />} />
            <Route path="products" element={<Soon title="Products" phase={2} />} />
            <Route path="gst-rates" element={<Soon title="GST rates" phase={2} />} />

            <Route
              path="sales/quotations"
              element={<Soon title="Quotations" phase={3} />}
            />
            <Route
              path="sales/orders"
              element={<Soon title="Sales orders" phase={3} />}
            />
            <Route
              path="sales/delivery-challans"
              element={<Soon title="Delivery challans" phase={3} />}
            />
            <Route
              path="sales/invoices"
              element={<Soon title="Invoices" phase={3} />}
            />
            <Route
              path="sales/payments"
              element={<Soon title="Payments received" phase={3} />}
            />

            <Route
              path="purchase/orders"
              element={<Soon title="Purchase orders" phase={4} />}
            />
            <Route
              path="purchase/grn"
              element={<Soon title="Goods receipts" phase={4} />}
            />
            <Route
              path="purchase/invoices"
              element={<Soon title="Purchase invoices" phase={4} />}
            />
            <Route
              path="purchase/expenses"
              element={<Soon title="Expenses" phase={4} />}
            />
            <Route
              path="purchase/payments"
              element={<Soon title="Vendor payments" phase={4} />}
            />

            <Route path="inventory" element={<Soon title="Stock ledger" phase={5} />} />
            <Route
              path="inventory/warehouses"
              element={<Soon title="Warehouses" phase={5} />}
            />

            <Route
              path="manufacturing/bom"
              element={<Soon title="BOM & routes" phase={6} />}
            />
            <Route
              path="manufacturing/work-orders"
              element={<Soon title="Work orders" phase={6} />}
            />

            <Route path="tooling" element={<Soon title="Tooling" phase={7} />} />
            <Route path="quality" element={<Soon title="Quality / NCR" phase={7} />} />
            <Route path="reports" element={<Soon title="Reports" phase={8} />} />

            <Route path="*" element={<Navigate to="/app" replace />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
