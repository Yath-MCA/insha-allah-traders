import { useEffect, useState, type ReactNode } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { useAuth } from '@/features/auth'
import { PageHeader } from '@/components/shared/PageHeader'
import { LoadingState } from '@/components/shared/LoadingState'
import { ErrorState } from '@/components/shared/ErrorState'
import { EmptyState } from '@/components/shared/EmptyState'
import { DisclaimerFooter } from '@/components/shared/DisclaimerFooter'
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
import { BUSINESS_TYPES, INDIAN_STATES } from '@/constants/states'
import {
  createBankAccount,
  fetchCompanySettings,
  getCompanyAssetUrl,
  listBankAccounts,
  softDeleteBankAccount,
  updateBankAccount,
  updateCompany,
  updateCompanySettings,
  uploadCompanyAsset,
} from '@/services'
import type { BankAccount, IndianStateCode } from '@/types'
import {
  bankFormSchema,
  companyFormSchema,
  type BankFormValues,
  type CompanyFormValues,
} from './schemas'

export function CompanySettingsPage() {
  const { company, hasPermission, refresh } = useAuth()
  const queryClient = useQueryClient()
  const canUpdate = hasPermission('companies', 'update')
  const canUpdateSettings = hasPermission('company_settings', 'update')
  const canManageBanks = hasPermission('bank_accounts', 'create')

  const settingsQuery = useQuery({
    queryKey: ['company-settings', company?.id],
    enabled: Boolean(company?.id),
    queryFn: () => fetchCompanySettings(company!.id),
  })

  const banksQuery = useQuery({
    queryKey: ['bank-accounts', company?.id],
    enabled: Boolean(company?.id),
    queryFn: () => listBankAccounts(company!.id),
  })

  const [logoUrl, setLogoUrl] = useState<string | null>(null)
  const [signatureUrl, setSignatureUrl] = useState<string | null>(null)
  const [bankDialogOpen, setBankDialogOpen] = useState(false)
  const [editingBank, setEditingBank] = useState<BankAccount | null>(null)

  useEffect(() => {
    void (async () => {
      setLogoUrl(await getCompanyAssetUrl(company?.logo_path))
      setSignatureUrl(await getCompanyAssetUrl(company?.signature_path))
    })()
  }, [company?.logo_path, company?.signature_path])

  const form = useForm<CompanyFormValues>({
    resolver: zodResolver(companyFormSchema),
    values: {
      legal_name: company?.legal_name ?? '',
      trade_name: company?.trade_name ?? '',
      business_type: company?.business_type ?? 'partnership',
      gstin: company?.gstin ?? '',
      pan: company?.pan ?? '',
      tan: company?.tan ?? '',
      email: company?.email ?? '',
      phone: company?.phone ?? '',
      website: company?.website ?? '',
      address_line1: company?.address_line1 ?? '',
      address_line2: company?.address_line2 ?? '',
      city: company?.city ?? '',
      district: company?.district ?? '',
      state_code: company?.state_code ?? 'TN',
      pincode: company?.pincode ?? '',
      invoice_prefix: company?.invoice_prefix ?? 'IAT',
      invoice_terms: settingsQuery.data?.invoice_terms ?? '',
      invoice_notes: settingsQuery.data?.invoice_notes ?? '',
      default_payment_terms_days:
        settingsQuery.data?.default_payment_terms_days ?? 30,
      enable_gst: settingsQuery.data?.enable_gst ?? true,
    },
  })

  const saveMutation = useMutation({
    mutationFn: async (values: CompanyFormValues) => {
      if (!company) throw new Error('No company')
      await updateCompany(company.id, {
        legal_name: values.legal_name,
        trade_name: values.trade_name || null,
        business_type: values.business_type,
        gstin: values.gstin || null,
        pan: values.pan || null,
        tan: values.tan || null,
        email: values.email || null,
        phone: values.phone || null,
        website: values.website || null,
        address_line1: values.address_line1 || null,
        address_line2: values.address_line2 || null,
        city: values.city || null,
        district: values.district || null,
        state_code: (values.state_code as IndianStateCode) || null,
        pincode: values.pincode || null,
        invoice_prefix: values.invoice_prefix,
      })
      if (canUpdateSettings) {
        await updateCompanySettings(company.id, {
          invoice_terms: values.invoice_terms || null,
          invoice_notes: values.invoice_notes || null,
          default_payment_terms_days: values.default_payment_terms_days,
          enable_gst: values.enable_gst,
        })
      }
    },
    onSuccess: async () => {
      toast.success('Company settings saved')
      await refresh()
      void queryClient.invalidateQueries({ queryKey: ['company-settings'] })
    },
    onError: (err: Error) => toast.error(err.message),
  })

  async function onUpload(kind: 'logo' | 'signature', file: File | null) {
    if (!company || !file) return
    if (!canUpdateSettings) {
      toast.error('You do not have permission to upload assets')
      return
    }
    try {
      const path = await uploadCompanyAsset(company.id, kind, file)
      await updateCompany(
        company.id,
        kind === 'logo' ? { logo_path: path } : { signature_path: path },
      )
      await refresh()
      toast.success(`${kind === 'logo' ? 'Logo' : 'Signature'} uploaded`)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Upload failed')
    }
  }

  if (!company) {
    return (
      <ErrorState
        title="No company"
        message="Assign a company role before editing settings."
      />
    )
  }

  if (settingsQuery.isLoading) {
    return <LoadingState label="Loading company settings…" />
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Company settings"
        description="Legal identity, GST details, invoice defaults, and bank accounts."
        crumbs={[
          { label: 'Home', href: '/app' },
          { label: 'Settings' },
          { label: 'Company' },
        ]}
      />

      <form
        className="space-y-6"
        onSubmit={form.handleSubmit((v) => saveMutation.mutate(v))}
      >
        <Card>
          <CardHeader>
            <CardTitle>Identity</CardTitle>
            <CardDescription>
              Partnership firm master used on invoices and documents.
            </CardDescription>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <Field label="Legal name" error={form.formState.errors.legal_name?.message}>
              <Input disabled={!canUpdate} {...form.register('legal_name')} />
            </Field>
            <Field label="Trade name">
              <Input disabled={!canUpdate} {...form.register('trade_name')} />
            </Field>
            <Field label="Business type">
              <Select disabled={!canUpdate} {...form.register('business_type')}>
                {BUSINESS_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="Invoice prefix" error={form.formState.errors.invoice_prefix?.message}>
              <Input disabled={!canUpdate} {...form.register('invoice_prefix')} />
            </Field>
            <Field label="GSTIN" error={form.formState.errors.gstin?.message}>
              <Input
                disabled={!canUpdate}
                placeholder="33AAAAA0000A1Z5"
                {...form.register('gstin')}
              />
            </Field>
            <Field label="PAN" error={form.formState.errors.pan?.message}>
              <Input disabled={!canUpdate} {...form.register('pan')} />
            </Field>
            <Field label="TAN">
              <Input disabled={!canUpdate} {...form.register('tan')} />
            </Field>
            <Field label="Email" error={form.formState.errors.email?.message}>
              <Input disabled={!canUpdate} type="email" {...form.register('email')} />
            </Field>
            <Field label="Phone">
              <Input disabled={!canUpdate} {...form.register('phone')} />
            </Field>
            <Field label="Website">
              <Input disabled={!canUpdate} {...form.register('website')} />
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Address</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <Field label="Address line 1" className="sm:col-span-2">
              <Input disabled={!canUpdate} {...form.register('address_line1')} />
            </Field>
            <Field label="Address line 2" className="sm:col-span-2">
              <Input disabled={!canUpdate} {...form.register('address_line2')} />
            </Field>
            <Field label="City">
              <Input disabled={!canUpdate} {...form.register('city')} />
            </Field>
            <Field label="District">
              <Input disabled={!canUpdate} {...form.register('district')} />
            </Field>
            <Field label="State">
              <Select disabled={!canUpdate} {...form.register('state_code')}>
                {INDIAN_STATES.map((s) => (
                  <option key={s.code} value={s.code}>
                    {s.name} ({s.code})
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="PIN code">
              <Input disabled={!canUpdate} {...form.register('pincode')} />
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Invoice defaults</CardTitle>
          </CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <Field label="Payment terms (days)">
              <Input
                type="number"
                disabled={!canUpdateSettings}
                {...form.register('default_payment_terms_days', {
                  valueAsNumber: true,
                })}
              />
            </Field>
            <Field label="Enable GST">
              <label className="flex h-8 items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  disabled={!canUpdateSettings}
                  {...form.register('enable_gst')}
                />
                GST enabled on documents
              </label>
            </Field>
            <Field label="Invoice terms" className="sm:col-span-2">
              <Textarea
                disabled={!canUpdateSettings}
                rows={3}
                {...form.register('invoice_terms')}
              />
            </Field>
            <Field label="Invoice notes" className="sm:col-span-2">
              <Textarea
                disabled={!canUpdateSettings}
                rows={2}
                {...form.register('invoice_notes')}
              />
            </Field>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Logo & signature</CardTitle>
            <CardDescription>
              Stored in the private <code>company-assets</code> bucket under{' '}
              <code>{'{company_id}/'}</code>.
            </CardDescription>
          </CardHeader>
          <CardContent className="grid gap-6 sm:grid-cols-2">
            <AssetUpload
              label="Company logo"
              previewUrl={logoUrl}
              disabled={!canUpdateSettings}
              onFile={(f) => void onUpload('logo', f)}
            />
            <AssetUpload
              label="Authorized signature"
              previewUrl={signatureUrl}
              disabled={!canUpdateSettings}
              onFile={(f) => void onUpload('signature', f)}
            />
          </CardContent>
        </Card>

        {(canUpdate || canUpdateSettings) && (
          <Button type="submit" disabled={saveMutation.isPending}>
            {saveMutation.isPending ? 'Saving…' : 'Save company settings'}
          </Button>
        )}
      </form>

      <Card>
        <CardHeader className="flex flex-row items-start justify-between gap-3">
          <div>
            <CardTitle>Bank accounts</CardTitle>
            <CardDescription>
              Mark one account as primary for invoices.
            </CardDescription>
          </div>
          {canManageBanks ? (
            <Button
              type="button"
              size="sm"
              onClick={() => {
                setEditingBank(null)
                setBankDialogOpen(true)
              }}
            >
              Add account
            </Button>
          ) : null}
        </CardHeader>
        <CardContent>
          {banksQuery.isLoading ? (
            <LoadingState />
          ) : banksQuery.isError ? (
            <ErrorState
              message={(banksQuery.error as Error).message}
              onRetry={() => void banksQuery.refetch()}
            />
          ) : !banksQuery.data?.length ? (
            <EmptyState
              title="No bank accounts"
              description="Add at least one account for invoice footers."
            />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-border text-muted-foreground">
                  <tr>
                    <th className="py-2 pr-3 font-medium">Account</th>
                    <th className="py-2 pr-3 font-medium">Bank</th>
                    <th className="py-2 pr-3 font-medium">Number</th>
                    <th className="py-2 pr-3 font-medium">IFSC</th>
                    <th className="py-2 pr-3 font-medium">Flags</th>
                    <th className="py-2 font-medium" />
                  </tr>
                </thead>
                <tbody>
                  {banksQuery.data.map((bank) => (
                    <tr key={bank.id} className="border-b border-border/70">
                      <td className="py-2.5 pr-3">{bank.account_name}</td>
                      <td className="py-2.5 pr-3">{bank.bank_name}</td>
                      <td className="py-2.5 pr-3 font-mono text-xs">
                        {bank.account_number}
                      </td>
                      <td className="py-2.5 pr-3 font-mono text-xs">
                        {bank.ifsc_code ?? '—'}
                      </td>
                      <td className="py-2.5 pr-3">
                        <div className="flex flex-wrap gap-1">
                          {bank.is_primary ? (
                            <Badge>Primary</Badge>
                          ) : null}
                          {!bank.is_active ? (
                            <Badge variant="secondary">Inactive</Badge>
                          ) : null}
                        </div>
                      </td>
                      <td className="py-2.5 text-right">
                        {hasPermission('bank_accounts', 'update') ? (
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setEditingBank(bank)
                              setBankDialogOpen(true)
                            }}
                          >
                            Edit
                          </Button>
                        ) : null}
                        {hasPermission('bank_accounts', 'delete') ? (
                          <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              void (async () => {
                                try {
                                  await softDeleteBankAccount(bank.id, company.id)
                                  toast.success('Bank account removed')
                                  void queryClient.invalidateQueries({
                                    queryKey: ['bank-accounts'],
                                  })
                                } catch (err) {
                                  toast.error(
                                    err instanceof Error
                                      ? err.message
                                      : 'Delete failed',
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

      <BankAccountDialog
        open={bankDialogOpen}
        onOpenChange={setBankDialogOpen}
        companyId={company.id}
        bank={editingBank}
        onSaved={() => {
          void queryClient.invalidateQueries({ queryKey: ['bank-accounts'] })
        }}
      />

      <DisclaimerFooter className="rounded-lg border border-border bg-muted/40 px-4 py-3 text-xs text-muted-foreground" />
    </div>
  )
}

function Field({
  label,
  error,
  children,
  className,
}: {
  label: string
  error?: string
  children: ReactNode
  className?: string
}) {
  return (
    <div className={className ? `space-y-2 ${className}` : 'space-y-2'}>
      <Label>{label}</Label>
      {children}
      {error ? <p className="text-xs text-destructive">{error}</p> : null}
    </div>
  )
}

function AssetUpload({
  label,
  previewUrl,
  disabled,
  onFile,
}: {
  label: string
  previewUrl: string | null
  disabled?: boolean
  onFile: (file: File | null) => void
}) {
  return (
    <div className="space-y-2">
      <Label>{label}</Label>
      <div className="flex items-center gap-4">
        <div className="flex size-20 items-center justify-center overflow-hidden rounded-lg border border-border bg-muted">
          {previewUrl ? (
            <img
              src={previewUrl}
              alt={label}
              className="max-h-full max-w-full object-contain"
            />
          ) : (
            <span className="text-xs text-muted-foreground">None</span>
          )}
        </div>
        <Input
          type="file"
          accept="image/png,image/jpeg,image/webp,image/svg+xml"
          disabled={disabled}
          onChange={(e) => onFile(e.target.files?.[0] ?? null)}
        />
      </div>
    </div>
  )
}

function BankAccountDialog({
  open,
  onOpenChange,
  companyId,
  bank,
  onSaved,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  companyId: string
  bank: BankAccount | null
  onSaved: () => void
}) {
  const form = useForm<BankFormValues>({
    resolver: zodResolver(bankFormSchema),
    values: {
      account_name: bank?.account_name ?? '',
      bank_name: bank?.bank_name ?? '',
      branch_name: bank?.branch_name ?? '',
      account_number: bank?.account_number ?? '',
      ifsc_code: bank?.ifsc_code ?? '',
      upi_id: bank?.upi_id ?? '',
      is_primary: bank?.is_primary ?? false,
      is_active: bank?.is_active ?? true,
      notes: bank?.notes ?? '',
    },
  })

  const mutation = useMutation({
    mutationFn: async (values: BankFormValues) => {
      const payload = {
        company_id: companyId,
        account_name: values.account_name,
        bank_name: values.bank_name,
        branch_name: values.branch_name || null,
        account_number: values.account_number,
        ifsc_code: values.ifsc_code || null,
        upi_id: values.upi_id || null,
        is_primary: values.is_primary,
        is_active: values.is_active,
        notes: values.notes || null,
      }
      if (bank) {
        await updateBankAccount(bank.id, companyId, payload)
      } else {
        await createBankAccount(payload)
      }
    },
    onSuccess: () => {
      toast.success(bank ? 'Bank account updated' : 'Bank account added')
      onOpenChange(false)
      onSaved()
    },
    onError: (err: Error) => toast.error(err.message),
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{bank ? 'Edit bank account' : 'Add bank account'}</DialogTitle>
        </DialogHeader>
        <form
          className="space-y-3"
          onSubmit={form.handleSubmit((v) => mutation.mutate(v))}
        >
          <Field label="Account name" error={form.formState.errors.account_name?.message}>
            <Input {...form.register('account_name')} />
          </Field>
          <Field label="Bank name" error={form.formState.errors.bank_name?.message}>
            <Input {...form.register('bank_name')} />
          </Field>
          <Field label="Branch">
            <Input {...form.register('branch_name')} />
          </Field>
          <Field label="Account number" error={form.formState.errors.account_number?.message}>
            <Input {...form.register('account_number')} />
          </Field>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="IFSC">
              <Input {...form.register('ifsc_code')} />
            </Field>
            <Field label="UPI ID">
              <Input {...form.register('upi_id')} />
            </Field>
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" {...form.register('is_primary')} />
            Default for invoices
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" {...form.register('is_active')} />
            Active
          </label>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
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
