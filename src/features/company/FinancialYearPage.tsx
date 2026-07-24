import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { useAuth } from '@/features/auth'
import { PageHeader } from '@/components/shared/PageHeader'
import { LoadingState } from '@/components/shared/LoadingState'
import { ErrorState } from '@/components/shared/ErrorState'
import { EmptyState } from '@/components/shared/EmptyState'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { formatDateDDMMYYYY } from '@/lib/formatters'
import {
  ensureFinancialYear,
  listFinancialYears,
  setCurrentFinancialYear,
} from '@/services'

export function FinancialYearPage() {
  const { company, hasPermission, refresh } = useAuth()
  const queryClient = useQueryClient()
  const canUpdate = hasPermission('financial_years', 'update')
  const canCreate = hasPermission('financial_years', 'create')

  const query = useQuery({
    queryKey: ['financial-years', company?.id],
    enabled: Boolean(company?.id),
    queryFn: () => listFinancialYears(company!.id),
  })

  const setCurrent = useMutation({
    mutationFn: async (fyId: string) => {
      if (!company) throw new Error('No company')
      await setCurrentFinancialYear(company.id, fyId)
    },
    onSuccess: async () => {
      toast.success('Current financial year updated')
      await refresh()
      void queryClient.invalidateQueries({ queryKey: ['financial-years'] })
    },
    onError: (err: Error) => toast.error(err.message),
  })

  const ensureCurrent = useMutation({
    mutationFn: async () => {
      if (!company) throw new Error('No company')
      return ensureFinancialYear(company.id)
    },
    onSuccess: async () => {
      toast.success('Financial year ensured for today (IST)')
      void queryClient.invalidateQueries({ queryKey: ['financial-years'] })
      await refresh()
    },
    onError: (err: Error) => toast.error(err.message),
  })

  if (!company) {
    return <ErrorState title="No company" message="Assign a company membership first." />
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Financial year"
        description="Indian FY runs 1 Apr – 31 Mar (Asia/Kolkata)."
        crumbs={[
          { label: 'Home', href: '/app' },
          { label: 'Settings' },
          { label: 'Financial year' },
        ]}
        actions={
          canCreate ? (
            <Button
              type="button"
              variant="outline"
              disabled={ensureCurrent.isPending}
              onClick={() => ensureCurrent.mutate()}
            >
              Ensure current FY
            </Button>
          ) : null
        }
      />

      <Card>
        <CardHeader>
          <CardTitle>Years</CardTitle>
          <CardDescription>
            Selecting current FY drives document numbering prefixes.
          </CardDescription>
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
              title="No financial years"
              description="Use Ensure current FY or run seed.sql."
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-border text-muted-foreground">
                  <tr>
                    <th className="py-2 pr-3 font-medium">Label</th>
                    <th className="py-2 pr-3 font-medium">Code</th>
                    <th className="py-2 pr-3 font-medium">Period</th>
                    <th className="py-2 pr-3 font-medium">Status</th>
                    <th className="py-2 font-medium" />
                  </tr>
                </thead>
                <tbody>
                  {query.data.map((fy) => (
                    <tr key={fy.id} className="border-b border-border/70">
                      <td className="py-2.5 pr-3 font-medium">{fy.label}</td>
                      <td className="py-2.5 pr-3 font-mono text-xs">{fy.code}</td>
                      <td className="py-2.5 pr-3">
                        {formatDateDDMMYYYY(fy.start_date)} –{' '}
                        {formatDateDDMMYYYY(fy.end_date)}
                      </td>
                      <td className="py-2.5 pr-3">
                        <div className="flex flex-wrap gap-1">
                          {fy.is_current ? <Badge>Current</Badge> : null}
                          {fy.is_closed ? (
                            <Badge variant="secondary">Closed</Badge>
                          ) : (
                            <Badge variant="outline">Open</Badge>
                          )}
                        </div>
                      </td>
                      <td className="py-2.5 text-right">
                        {canUpdate && !fy.is_current && !fy.is_closed ? (
                          <Button
                            type="button"
                            size="sm"
                            variant="outline"
                            disabled={setCurrent.isPending}
                            onClick={() => setCurrent.mutate(fy.id)}
                          >
                            Set current
                          </Button>
                        ) : null}
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
