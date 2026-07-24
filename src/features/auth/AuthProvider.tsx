import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import { permissionKey } from '@/constants/permissions'
import {
  fetchCompany,
  fetchUserPermissions,
  fetchUserRoles,
  getProfile,
  getUserCompanyIds,
  listFinancialYears,
  touchLastLogin,
} from '@/services'
import type {
  Company,
  FinancialYear,
  PermissionAction,
  Profile,
  Role,
  UserRole,
} from '@/types'

type AuthContextValue = {
  session: Session | null
  user: User | null
  profile: Profile | null
  company: Company | null
  companyIds: string[]
  roles: Role[]
  userRoles: UserRole[]
  permissions: Set<string>
  financialYear: FinancialYear | null
  loading: boolean
  isSuperAdmin: boolean
  hasPermission: (resource: string, action: PermissionAction | string) => boolean
  refresh: () => Promise<void>
  setActiveCompanyId: (companyId: string) => Promise<void>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | null>(null)

async function loadMembership(userId: string, preferredCompanyId?: string | null) {
  const profile = await getProfile(userId)
  const companyIds = await getUserCompanyIds()
  const companyId =
    (preferredCompanyId && companyIds.includes(preferredCompanyId)
      ? preferredCompanyId
      : null) ??
    (profile?.default_company_id &&
    companyIds.includes(profile.default_company_id)
      ? profile.default_company_id
      : null) ??
    companyIds[0] ??
    null

  if (!companyId) {
    return {
      profile,
      company: null as Company | null,
      companyIds,
      roles: [] as Role[],
      userRoles: [] as UserRole[],
      permissions: new Set<string>(),
      financialYear: null as FinancialYear | null,
      isSuperAdmin: false,
    }
  }

  const [company, userRoles, permRows, years] = await Promise.all([
    fetchCompany(companyId),
    fetchUserRoles(companyId, userId),
    fetchUserPermissions(companyId, userId),
    listFinancialYears(companyId),
  ])

  const roles = userRoles
    .map((ur) => ur.roles)
    .filter((r): r is Role => Boolean(r))
  const isSuperAdmin = roles.some((r) => r.code === 'super_admin')
  const permissions = new Set<string>()
  if (isSuperAdmin || permRows.some((p) => p.resource === '*')) {
    permissions.add('*')
  } else {
    for (const p of permRows) {
      permissions.add(permissionKey(p.resource, p.action))
    }
  }

  const financialYear =
    years.find((y) => y.is_current) ?? years[0] ?? null

  return {
    profile,
    company,
    companyIds,
    roles,
    userRoles,
    permissions,
    financialYear,
    isSuperAdmin,
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [company, setCompany] = useState<Company | null>(null)
  const [companyIds, setCompanyIds] = useState<string[]>([])
  const [roles, setRoles] = useState<Role[]>([])
  const [userRoles, setUserRoles] = useState<UserRole[]>([])
  const [permissions, setPermissions] = useState<Set<string>>(new Set())
  const [financialYear, setFinancialYear] = useState<FinancialYear | null>(null)
  const [isSuperAdmin, setIsSuperAdmin] = useState(false)
  const [loading, setLoading] = useState(true)
  const [activeCompanyId, setActiveCompanyIdState] = useState<string | null>(
    null,
  )

  const applyMembership = useCallback(
    async (userId: string, preferred?: string | null) => {
      const data = await loadMembership(userId, preferred ?? activeCompanyId)
      setProfile(data.profile)
      setCompany(data.company)
      setCompanyIds(data.companyIds)
      setRoles(data.roles)
      setUserRoles(data.userRoles)
      setPermissions(data.permissions)
      setFinancialYear(data.financialYear)
      setIsSuperAdmin(data.isSuperAdmin)
      setActiveCompanyIdState(data.company?.id ?? null)
    },
    [activeCompanyId],
  )

  const refresh = useCallback(async () => {
    const {
      data: { session: current },
    } = await supabase.auth.getSession()
    setSession(current)
    if (!current?.user) {
      setProfile(null)
      setCompany(null)
      setCompanyIds([])
      setRoles([])
      setUserRoles([])
      setPermissions(new Set())
      setFinancialYear(null)
      setIsSuperAdmin(false)
      return
    }
    await applyMembership(current.user.id)
  }, [applyMembership])

  useEffect(() => {
    let cancelled = false

    async function init() {
      setLoading(true)
      const {
        data: { session: initial },
      } = await supabase.auth.getSession()
      if (cancelled) return
      setSession(initial)
      if (initial?.user) {
        try {
          await applyMembership(initial.user.id)
          void touchLastLogin(initial.user.id)
        } catch (err) {
          console.error('Failed to load membership', err)
        }
      }
      if (!cancelled) setLoading(false)
    }

    void init()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, nextSession) => {
      setSession(nextSession)
      if (!nextSession?.user) {
        setProfile(null)
        setCompany(null)
        setCompanyIds([])
        setRoles([])
        setUserRoles([])
        setPermissions(new Set())
        setFinancialYear(null)
        setIsSuperAdmin(false)
        setLoading(false)
        return
      }

      void (async () => {
        setLoading(true)
        try {
          await applyMembership(nextSession.user.id)
          if (event === 'SIGNED_IN') {
            void touchLastLogin(nextSession.user.id)
          }
        } catch (err) {
          console.error('Failed to load membership', err)
        } finally {
          setLoading(false)
        }
      })()
    })

    return () => {
      cancelled = true
      subscription.unsubscribe()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- init once
  }, [])

  const setActiveCompanyId = useCallback(
    async (companyId: string) => {
      if (!session?.user) return
      setActiveCompanyIdState(companyId)
      setLoading(true)
      try {
        await applyMembership(session.user.id, companyId)
      } finally {
        setLoading(false)
      }
    },
    [applyMembership, session?.user],
  )

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
  }, [])

  const hasPermission = useCallback(
    (resource: string, action: PermissionAction | string) => {
      if (isSuperAdmin || permissions.has('*')) return true
      return permissions.has(permissionKey(resource, action))
    },
    [isSuperAdmin, permissions],
  )

  const value = useMemo<AuthContextValue>(
    () => ({
      session,
      user: session?.user ?? null,
      profile,
      company,
      companyIds,
      roles,
      userRoles,
      permissions,
      financialYear,
      loading,
      isSuperAdmin,
      hasPermission,
      refresh,
      setActiveCompanyId,
      signOut,
    }),
    [
      session,
      profile,
      company,
      companyIds,
      roles,
      userRoles,
      permissions,
      financialYear,
      loading,
      isSuperAdmin,
      hasPermission,
      refresh,
      setActiveCompanyId,
      signOut,
    ],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return ctx
}

export function usePermission(resource: string, action: PermissionAction | string) {
  const { hasPermission, loading } = useAuth()
  return { allowed: hasPermission(resource, action), loading }
}
