import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { toast } from 'sonner'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { updateProfile } from '@/services'
import { useAuth } from './AuthProvider'

const schema = z.object({
  full_name: z.string().min(1, 'Name is required'),
  phone: z.string().optional(),
})

type FormValues = z.infer<typeof schema>

export function ProfilePage() {
  const { user, profile, refresh } = useAuth()
  const [submitting, setSubmitting] = useState(false)
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    values: {
      full_name: profile?.full_name ?? '',
      phone: profile?.phone ?? '',
    },
  })

  async function onSubmit(values: FormValues) {
    if (!user) return
    setSubmitting(true)
    try {
      await updateProfile(user.id, {
        full_name: values.full_name,
        phone: values.phone || null,
      })
      await refresh()
      toast.success('Profile updated')
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Update failed')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div>
      <PageHeader
        title="Profile"
        description="Your account details for this ERP."
        crumbs={[
          { label: 'Home', href: '/' },
          { label: 'Profile' },
        ]}
      />
      <Card className="max-w-lg">
        <CardHeader>
          <CardTitle>Account</CardTitle>
          <CardDescription>{user?.email}</CardDescription>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={form.handleSubmit(onSubmit)}>
            <div className="space-y-2">
              <Label htmlFor="full_name">Full name</Label>
              <Input id="full_name" {...form.register('full_name')} />
              {form.formState.errors.full_name ? (
                <p className="text-xs text-destructive">
                  {form.formState.errors.full_name.message}
                </p>
              ) : null}
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">Phone</Label>
              <Input id="phone" {...form.register('phone')} />
            </div>
            <Button type="submit" disabled={submitting}>
              {submitting ? 'Saving…' : 'Save profile'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
