import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import { LogOut, UserRound } from 'lucide-react'
import { useAuth } from '@/features/auth'
import { NAV_GROUPS } from '@/constants/navigation'
import { DisclaimerFooter } from '@/components/shared/DisclaimerFooter'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuBadge,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarTrigger,
} from '@/components/ui/sidebar'
import { cn } from '@/lib/utils'

export function AppShell() {
  const {
    company,
    profile,
    user,
    financialYear,
    roles,
    signOut,
    hasPermission,
  } = useAuth()
  const navigate = useNavigate()

  return (
    <SidebarProvider>
      <Sidebar collapsible="icon" className="border-r border-sidebar-border">
        <SidebarHeader className="gap-2 px-3 py-4">
          <Link to="/app" className="flex flex-col gap-0.5 px-1 group-data-[collapsible=icon]:hidden">
            <span className="text-[10px] font-medium tracking-[0.18em] text-muted-foreground uppercase">
              ERP
            </span>
            <span className="truncate text-sm font-semibold leading-tight">
              {company?.trade_name || company?.legal_name || 'Insha Allah Traders'}
            </span>
          </Link>
          {financialYear ? (
            <Badge variant="outline" className="w-fit group-data-[collapsible=icon]:hidden">
              FY {financialYear.code}
            </Badge>
          ) : null}
        </SidebarHeader>
        <SidebarContent>
          {NAV_GROUPS.map((group) => (
            <SidebarGroup key={group.label}>
              <SidebarGroupLabel>{group.label}</SidebarGroupLabel>
              <SidebarGroupContent>
                <SidebarMenu>
                  {group.items.map((item) => {
                    if (
                      item.permission &&
                      !hasPermission(
                        item.permission.resource,
                        item.permission.action,
                      )
                    ) {
                      return null
                    }
                    return (
                      <SidebarMenuItem key={item.href}>
                        <SidebarMenuButton asChild tooltip={item.title}>
                          <NavLink
                            to={item.href}
                            end={item.href === '/app'}
                            className={({ isActive }) =>
                              cn(isActive && 'bg-sidebar-accent text-sidebar-accent-foreground')
                            }
                          >
                            <item.icon />
                            <span>{item.title}</span>
                          </NavLink>
                        </SidebarMenuButton>
                        {item.phase > 1 ? (
                          <SidebarMenuBadge className="opacity-70">
                            P{item.phase}
                          </SidebarMenuBadge>
                        ) : null}
                      </SidebarMenuItem>
                    )
                  })}
                </SidebarMenu>
              </SidebarGroupContent>
            </SidebarGroup>
          ))}
        </SidebarContent>
        <SidebarFooter className="gap-2 p-3">
          <div className="rounded-lg bg-sidebar-accent/50 px-2 py-2 text-xs group-data-[collapsible=icon]:hidden">
            <p className="truncate font-medium">
              {profile?.full_name || user?.email || 'User'}
            </p>
            <p className="truncate text-muted-foreground">
              {roles.map((r) => r.name).join(', ') || 'No role'}
            </p>
          </div>
        </SidebarFooter>
      </Sidebar>

      <SidebarInset className="flex min-h-svh flex-col bg-[linear-gradient(180deg,oklch(0.975_0.006_250),oklch(0.985_0.004_250)_120px)]">
        <header className="sticky top-0 z-20 flex h-14 items-center gap-3 border-b border-border/80 bg-background/85 px-4 backdrop-blur-sm">
          <SidebarTrigger />
          <Separator orientation="vertical" className="h-5" />
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium">
              {company?.legal_name || 'Insha Allah Traders'}
            </p>
            <p className="truncate text-xs text-muted-foreground">
              {financialYear ? `Financial year ${financialYear.label}` : 'No FY selected'}
            </p>
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm">
                <UserRound />
                Account
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuLabel>
                {profile?.full_name || user?.email}
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => navigate('/app/profile')}>
                Profile
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => navigate('/app/settings/company')}>
                Company settings
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                onClick={() => {
                  void signOut()
                }}
              >
                <LogOut />
                Sign out
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </header>

        <main className="flex-1 px-4 py-6 md:px-6">
          <Outlet />
        </main>
        <DisclaimerFooter />
      </SidebarInset>
    </SidebarProvider>
  )
}
