import { useState, type ReactNode } from 'react'
import { useForm } from 'react-hook-form'
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
import { Textarea } from '@/components/ui/textarea'
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
  createPartner,
  listPartners,
  softDeletePartner,
  updatePartner,
} from '@/services'
import type { Partner } from '@/types'
import { partnerFormSchema, type PartnerFormValues } from './schemas'

export function PartnersPage() {
  const { company, hasPermission } = useAuth()
  const queryClient = useQueryClient()
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Partner | null>(null)

  const query = useQuery({
    queryKey: ['partners', company?.id],
    enabled: Boolean(company?.id),
    queryFn: () => listPartners(company!.id),
  })

  if (!company) {
    return <ErrorState title="No company" message="Assign a company membership first." />
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Partners"
        description="Firm partners / owners. Full Aadhaar is not stored (no Aadhaar column in schema)."
        crumbs={[
          { label: 'Home', href: '/' },
          { label: 'Settings' },
          { label: 'Partners' },
        ]}
        actions={
          hasPermission('partners', 'create') ? (
            <Button
              type="button"
              onClick={() => {
                setEditing(null)
                setOpen(true)
              }}
            >
              Add partner
            </Button>
          ) : null
        }
      />

      <Card>
        <CardHeader>
          <CardTitle>Partner list</CardTitle>
          <CardDescription>Share % is informational for internal records.</CardDescription>
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
            <EmptyState title="No partners yet" description="Add partners of the firm." />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-border text-muted-foreground">
                  <tr>
                    <th className="py-2 pr-3 font-medium">Name</th>
                    <th className="py-2 pr-3 font-medium">PAN</th>
                    <th className="py-2 pr-3 font-medium">Share %</th>
                    <th className="py-2 pr-3 font-medium">Status</th>
                    <th className="py-2 font-medium" />
                  </tr>
                </thead>
                <tbody>
                  {query.data.map((p) => (
                    <tr key={p.id} className="border-b border-border/70">
                      <td className="py-2.5 pr-3">
                        <div className="font-medium">{p.full_name}</div>
                        <div className="text-xs text-muted-foreground">
                          {p.email || p.phone || '—'}
                        </div>
                      </td>
                      <td className="py-2.5 pr-3 font-mono text-xs">{p.pan ?? '—'}</td>
                      <td className="py-2.5 pr-3">
                        {p.share_percent != null ? `${p.share_percent}%` : '—'}
                      </td>
                      <td className="py-2.5 pr-3">
                        <Badge variant={p.status === 'active' ? 'default' : 'secondary'}>
                          {p.status}
                        </Badge>
                      </td>
                      <td className="py-2.5 text-right">
                        {hasPermission('partners', 'update') ? (
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setEditing(p)
                              setOpen(true)
                            }}
                          >
                            Edit
                          </Button>
                        ) : null}
                        {hasPermission('partners', 'delete') ? (
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              void (async () => {
                                try {
                                  await softDeletePartner(p.id, company.id)
                                  toast.success('Partner removed')
                                  void queryClient.invalidateQueries({
                                    queryKey: ['partners'],
                                  })
                                } catch (err) {
                                  toast.error(
                                    err instanceof Error ? err.message : 'Delete failed',
                                  )
                                }
                              })()
                            }}
                          >
                            Remove
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

      <PartnerDialog
        open={open}
        onOpenChange={setOpen}
        companyId={company.id}
        partner={editing}
        onSaved={() => {
          void queryClient.invalidateQueries({ queryKey: ['partners'] })
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

function PartnerDialog({
  open,
  onOpenChange,
  companyId,
  partner,
  onSaved,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  companyId: string
  partner: Partner | null
  onSaved: () => void
}) {
  const form = useForm<PartnerFormValues>({
    resolver: zodResolver(partnerFormSchema),
    values: {
      full_name: partner?.full_name ?? '',
      pan: partner?.pan ?? '',
      email: partner?.email ?? '',
      phone: partner?.phone ?? '',
      share_percent: partner?.share_percent ?? null,
      status: partner?.status ?? 'active',
      address: partner?.address ?? '',
      notes: partner?.notes ?? '',
    },
  })

  const mutation = useMutation({
    mutationFn: async (values: PartnerFormValues) => {
      const payload = {
        company_id: companyId,
        full_name: values.full_name,
        pan: values.pan || null,
        email: values.email || null,
        phone: values.phone || null,
        share_percent: values.share_percent ?? null,
        status: values.status,
        address: values.address || null,
        notes: values.notes || null,
        user_id: partner?.user_id ?? null,
      }
      if (partner) {
        await updatePartner(partner.id, companyId, payload)
      } else {
        await createPartner(payload)
      }
    },
    onSuccess: () => {
      toast.success(partner ? 'Partner updated' : 'Partner added')
      onOpenChange(false)
      onSaved()
    },
    onError: (err: Error) => toast.error(err.message),
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{partner ? 'Edit partner' : 'Add partner'}</DialogTitle>
        </DialogHeader>
        <form
          className="space-y-3"
          onSubmit={form.handleSubmit((v) => mutation.mutate(v))}
        >
          <Field label="Full name" error={form.formState.errors.full_name?.message}>
            <Input {...form.register('full_name')} />
          </Field>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="PAN" error={form.formState.errors.pan?.message}>
              <Input {...form.register('pan')} />
            </Field>
            <Field label="Share %">
              <Input
                type="number"
                step="0.01"
                {...form.register('share_percent', {
                  setValueAs: (v) =>
                    v === '' || v == null ? null : Number(v),
                })}
              />
            </Field>
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Email" error={form.formState.errors.email?.message}>
              <Input type="email" {...form.register('email')} />
            </Field>
            <Field label="Phone">
              <Input {...form.register('phone')} />
            </Field>
          </div>
          <Field label="Status">
            <Select {...form.register('status')}>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
            </Select>
          </Field>
          <Field label="Address">
            <Textarea rows={2} {...form.register('address')} />
          </Field>
          <Field label="Notes">
            <Textarea rows={2} {...form.register('notes')} />
          </Field>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? 'Saving…' : 'Save'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
