import { useMemo, useState, type ReactNode } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { useAuth } from '@/features/auth'
import { PageHeader } from '@/components/shared/PageHeader'
import { LoadingState } from '@/components/shared/LoadingState'
import { ErrorState } from '@/components/shared/ErrorState'
import { EmptyState } from '@/components/shared/EmptyState'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  assignUserRole,
  deactivateUserRole,
  listCompanyUsers,
  listRoles,
} from '@/services'

const assignSchema = z.object({
  user_id: z.string().uuid('Enter the Auth user UUID'),
  role_id: z.string().uuid('Select a role'),
})

type AssignValues = z.infer<typeof assignSchema>

export function UsersPage() {
  const { company, hasPermission, isSuperAdmin } = useAuth()
  const queryClient = useQueryClient()
  const [open, setOpen] = useState(false)
  const canAssign =
    isSuperAdmin ||
    hasPermission('users', 'create') ||
    hasPermission('users', 'update')

  const usersQuery = useQuery({
    queryKey: ['company-users', company?.id],
    enabled: Boolean(company?.id),
    queryFn: () => listCompanyUsers(company!.id),
  })

  const rolesQuery = useQuery({
    queryKey: ['roles'],
    queryFn: listRoles,
  })

  const grouped = useMemo(() => {
    const map = new Map<
      string,
      {
        userId: string
        email: string | null
        fullName: string | null
        roles: { assignmentId: string; roleName: string; roleCode: string }[]
      }
    >()
    for (const row of usersQuery.data ?? []) {
      if (!row.is_active) continue
      const key = row.user_id
      const existing = map.get(key) ?? {
        userId: row.user_id,
        email: row.profiles?.email ?? null,
        fullName: row.profiles?.full_name ?? null,
        roles: [],
      }
      if (row.roles) {
        existing.roles.push({
          assignmentId: row.id,
          roleName: row.roles.name,
          roleCode: row.roles.code,
        })
      }
      map.set(key, existing)
    }
    return [...map.values()]
  }, [usersQuery.data])

  if (!company) {
    return <ErrorState title="No company" message="Assign a company membership first." />
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Users & roles"
        description="List company members and assign roles (admin / super_admin)."
        crumbs={[
          { label: 'Home', href: '/app' },
          { label: 'Settings' },
          { label: 'Users' },
        ]}
        actions={
          canAssign ? (
            <Button type="button" onClick={() => setOpen(true)}>
              Assign role
            </Button>
          ) : null
        }
      />

      <Card>
        <CardHeader>
          <CardTitle>Members</CardTitle>
          <CardDescription>
            Create Auth users in the Supabase dashboard (or signup), then assign
            a role here using their user UUID. First Super Admin: see{' '}
            <code>supabase/README.md</code>.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {usersQuery.isLoading ? (
            <LoadingState />
          ) : usersQuery.isError ? (
            <ErrorState
              message={(usersQuery.error as Error).message}
              onRetry={() => void usersQuery.refetch()}
            />
          ) : !grouped.length ? (
            <EmptyState
              title="No members yet"
              description="Bootstrap Super Admin via SQL, then assign additional roles here."
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-border text-muted-foreground">
                  <tr>
                    <th className="py-2 pr-3 font-medium">User</th>
                    <th className="py-2 pr-3 font-medium">Roles</th>
                    <th className="py-2 font-medium" />
                  </tr>
                </thead>
                <tbody>
                  {grouped.map((u) => (
                    <tr key={u.userId} className="border-b border-border/70 align-top">
                      <td className="py-2.5 pr-3">
                        <div className="font-medium">
                          {u.fullName || u.email || 'User'}
                        </div>
                        <div className="text-xs text-muted-foreground">{u.email}</div>
                        <div className="mt-1 font-mono text-[11px] text-muted-foreground">
                          {u.userId}
                        </div>
                      </td>
                      <td className="py-2.5 pr-3">
                        <div className="flex flex-wrap gap-1">
                          {u.roles.map((r) => (
                            <Badge key={r.assignmentId} variant="secondary">
                              {r.roleName}
                            </Badge>
                          ))}
                        </div>
                      </td>
                      <td className="py-2.5 text-right">
                        {hasPermission('users', 'delete') ||
                        hasPermission('users', 'update')
                          ? u.roles.map((r) => (
                              <Button
                                key={r.assignmentId}
                                type="button"
                                variant="ghost"
                                size="sm"
                                onClick={() => {
                                  void (async () => {
                                    try {
                                      await deactivateUserRole(r.assignmentId)
                                      toast.success(`Removed ${r.roleName}`)
                                      void queryClient.invalidateQueries({
                                        queryKey: ['company-users'],
                                      })
                                    } catch (err) {
                                      toast.error(
                                        err instanceof Error
                                          ? err.message
                                          : 'Remove failed',
                                      )
                                    }
                                  })()
                                }}
                              >
                                Remove {r.roleName}
                              </Button>
                            ))
                          : null}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      <AssignRoleDialog
        open={open}
        onOpenChange={setOpen}
        companyId={company.id}
        roleOptions={rolesQuery.data ?? []}
        onSaved={() => {
          void queryClient.invalidateQueries({ queryKey: ['company-users'] })
        }}
      />
    </div>
  )
}

function Field({
  label,
  error,
  children,
}: {
  label: string
  error?: string
  children: ReactNode
}) {
  return (
    <div className="space-y-2">
      <Label>{label}</Label>
      {children}
      {error ? <p className="text-xs text-destructive">{error}</p> : null}
    </div>
  )
}

function AssignRoleDialog({
  open,
  onOpenChange,
  companyId,
  roleOptions,
  onSaved,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  companyId: string
  roleOptions: { id: string; name: string; code: string }[]
  onSaved: () => void
}) {
  const form = useForm<AssignValues>({
    resolver: zodResolver(assignSchema),
    defaultValues: { user_id: '', role_id: '' },
  })

  const mutation = useMutation({
    mutationFn: async (values: AssignValues) => {
      await assignUserRole({
        user_id: values.user_id,
        company_id: companyId,
        role_id: values.role_id,
      })
    },
    onSuccess: () => {
      toast.success('Role assigned')
      form.reset()
      onOpenChange(false)
      onSaved()
    },
    onError: (err: Error) => toast.error(err.message),
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Assign role</DialogTitle>
        </DialogHeader>
        <form
          className="space-y-3"
          onSubmit={form.handleSubmit((v) => mutation.mutate(v))}
        >
          <Field
            label="Auth user UUID"
            error={form.formState.errors.user_id?.message}
          >
            <Input
              placeholder="From Supabase Auth → Users"
              {...form.register('user_id')}
            />
          </Field>
          <Field label="Role" error={form.formState.errors.role_id?.message}>
            <Select {...form.register('role_id')}>
              <option value="">Select role…</option>
              {roleOptions.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name} ({r.code})
                </option>
              ))}
            </Select>
          </Field>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? 'Saving…' : 'Assign'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
