import { Link } from 'react-router-dom'
import {
  Building2,
  CalendarRange,
  FileText,
  Settings,
  Users,
} from 'lucide-react'
import { useAuth } from '@/features/auth'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { formatDateDDMMYYYY } from '@/lib/formatters'

export function HomePage() {
  const { company, profile, user, financialYear, roles, hasPermission } =
    useAuth()

  const kpis = [
    {
      title: 'Company',
      value: company?.trade_name || company?.legal_name || '—',
      hint: company?.state_code ? `State ${company.state_code}` : 'Set GSTIN in settings',
      icon: Building2,
    },
    {
      title: 'Financial year',
      value: financialYear?.code ?? '—',
      hint: financialYear
        ? `${formatDateDDMMYYYY(financialYear.start_date)} – ${formatDateDDMMYYYY(financialYear.end_date)}`
        : 'Configure FY in settings',
      icon: CalendarRange,
    },
    {
      title: 'Signed in',
      value: profile?.full_name || user?.email || '—',
      hint: roles.map((r) => r.name).join(', ') || 'No role assigned',
      icon: Users,
    },
    {
      title: 'Invoice prefix',
      value: company?.invoice_prefix ?? '—',
      hint: 'Example: IAT/2026-27/INV/0001',
      icon: FileText,
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Phase 1 foundation — operational modules unlock in later phases."
      />

      {!company ? (
        <Card className="border-dashed">
          <CardHeader>
            <CardTitle>No company membership</CardTitle>
            <CardDescription>
              Your Auth user exists, but no <code>user_roles</code> row is
              attached. Follow the Super Admin bootstrap in{' '}
              <code>supabase/README.md</code>.
            </CardDescription>
          </CardHeader>
        </Card>
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {kpis.map((kpi) => (
          <Card key={kpi.title}>
            <CardHeader className="flex flex-row items-start justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                {kpi.title}
              </CardTitle>
              <kpi.icon className="size-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <p className="truncate text-xl font-semibold tracking-tight">
                {kpi.value}
              </p>
              <p className="mt-1 text-xs text-muted-foreground">{kpi.hint}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Quick actions</CardTitle>
          <CardDescription>Phase 1 settings and audit.</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          {hasPermission('companies', 'read') ? (
            <Button asChild variant="outline">
              <Link to="/settings/company">
                <Settings />
                Company settings
              </Link>
            </Button>
          ) : null}
          {hasPermission('partners', 'read') ? (
            <Button asChild variant="outline">
              <Link to="/settings/partners">Partners</Link>
            </Button>
          ) : null}
          {hasPermission('users', 'read') ? (
            <Button asChild variant="outline">
              <Link to="/settings/users">Users & roles</Link>
            </Button>
          ) : null}
          {hasPermission('financial_years', 'read') ? (
            <Button asChild variant="outline">
              <Link to="/settings/financial-year">Financial year</Link>
            </Button>
          ) : null}
          {hasPermission('audit_logs', 'read') ? (
            <Button asChild variant="outline">
              <Link to="/audit-logs">Audit logs</Link>
            </Button>
          ) : null}
          <Button asChild variant="ghost">
            <Link to="/profile">Profile</Link>
          </Button>
        </CardContent>
      </Card>

      <div className="grid gap-4 sm:grid-cols-3">
        {['Sales', 'Purchase', 'Inventory'].map((label) => (
          <Card key={label} className="border-dashed bg-muted/20">
            <CardHeader>
              <CardTitle className="text-base">{label}</CardTitle>
              <CardDescription>KPI stub — live metrics in later phases.</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-2xl font-semibold tabular-nums text-muted-foreground">
                —
              </p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
