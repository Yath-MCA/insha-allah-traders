import { useQuery } from '@tanstack/react-query'
import { useAuth } from '@/features/auth'
import { PageHeader } from '@/components/shared/PageHeader'
import { LoadingState } from '@/components/shared/LoadingState'
import { ErrorState } from '@/components/shared/ErrorState'
import { EmptyState } from '@/components/shared/EmptyState'
import { Badge } from '@/components/ui/badge'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { formatDateTimeIST } from '@/lib/formatters'
import { listAuditLogs } from '@/services'

export function AuditLogsPage() {
  const { company } = useAuth()

  const query = useQuery({
    queryKey: ['audit-logs', company?.id],
    enabled: Boolean(company?.id),
    queryFn: () => listAuditLogs(company!.id, 150),
  })

  if (!company) {
    return (
      <ErrorState
        title="No company"
        message="Assign a company membership to view audit logs."
      />
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Audit logs"
        description="Read-only trail written by database triggers on master and financial tables."
        crumbs={[
          { label: 'Home', href: '/app' },
          { label: 'Audit logs' },
        ]}
      />

      <Card>
        <CardHeader>
          <CardTitle>Recent activity</CardTitle>
          <CardDescription>Latest 150 events for this company.</CardDescription>
        </CardHeader>
        <CardContent>
          {query.isLoading ? (
            <LoadingState />
          ) : query.isError ? (
            <ErrorState
              message={(query.error as Error).message}
              onRetry={() => void query.refetch()}
            />
          ) : !query.data?.length ? (
            <EmptyState
              title="No audit events yet"
              description="Changes to audited tables will appear here."
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-border text-muted-foreground">
                  <tr>
                    <th className="py-2 pr-3 font-medium">When (IST)</th>
                    <th className="py-2 pr-3 font-medium">Action</th>
                    <th className="py-2 pr-3 font-medium">Table</th>
                    <th className="py-2 pr-3 font-medium">Record</th>
                    <th className="py-2 font-medium">User</th>
                  </tr>
                </thead>
                <tbody>
                  {query.data.map((row) => (
                    <tr key={row.id} className="border-b border-border/70 align-top">
                      <td className="py-2.5 pr-3 whitespace-nowrap">
                        {formatDateTimeIST(row.created_at)}
                      </td>
                      <td className="py-2.5 pr-3">
                        <Badge variant="outline">{row.action}</Badge>
                      </td>
                      <td className="py-2.5 pr-3 font-mono text-xs">
                        {row.table_name}
                      </td>
                      <td className="py-2.5 pr-3 font-mono text-[11px] text-muted-foreground">
                        {row.record_id ?? '—'}
                      </td>
                      <td className="py-2.5">
                        {row.profiles?.full_name ||
                          row.profiles?.email ||
                          row.user_id ||
                          '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
