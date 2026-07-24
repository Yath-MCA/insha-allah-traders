import type { ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { LoadingState } from '@/components/shared/LoadingState'
import { ErrorState } from '@/components/shared/ErrorState'
import { useAuth } from './AuthProvider'

export function RequirePermission({
  resource,
  action,
  children,
}: {
  resource: string
  action: string
  children: ReactNode
}) {
  const { hasPermission, loading, company } = useAuth()

  if (loading) {
    return <LoadingState label="Checking permissions…" />
  }

  if (!company) {
    return (
      <ErrorState
        title="No company assigned"
        message="Your account is signed in but has no company membership. Ask a Super Admin to attach a role (see supabase/README.md)."
      />
    )
  }

  if (!hasPermission(resource, action)) {
    return <Navigate to="/" replace />
  }

  return children
}
