import { useState } from 'react'
import { Link, NavLink, Outlet } from 'react-router-dom'
import { Menu, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

const NAV = [
  { to: '/', label: 'Home', end: true },
  { to: '/capabilities', label: 'Capabilities' },
  { to: '/about', label: 'About' },
  { to: '/contact', label: 'Contact' },
] as const

export function WebsiteLayout() {
  const [open, setOpen] = useState(false)

  return (
    <div className="flex min-h-svh flex-col bg-[linear-gradient(165deg,oklch(0.97_0.008_250)_0%,oklch(0.94_0.012_245)_42%,oklch(0.985_0.004_250)_100%)] text-foreground">
      <header className="sticky top-0 z-40 border-b border-slate-300/60 bg-[oklch(0.97_0.006_250_/0.88)] backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 md:px-6">
          <Link to="/" className="min-w-0">
            <span className="block truncate text-lg font-semibold tracking-tight text-slate-900 md:text-xl">
              Insha Allah Traders
            </span>
            <span className="hidden text-[11px] tracking-[0.14em] text-slate-500 uppercase sm:block">
              Sheet metal manufacturing
            </span>
          </Link>

          <nav className="hidden items-center gap-1 md:flex" aria-label="Primary">
            {NAV.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={'end' in item ? item.end : false}
                className={({ isActive }) =>
                  cn(
                    'rounded-md px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-200/60 hover:text-slate-900',
                    isActive && 'bg-slate-200/80 text-slate-900',
                  )
                }
              >
                {item.label}
              </NavLink>
            ))}
            <Button
              asChild
              size="sm"
              className="ml-2 bg-slate-800 text-slate-50 transition-transform hover:bg-slate-900 hover:scale-[1.02] active:scale-[0.98]"
            >
              <Link to="/login">Staff Login</Link>
            </Button>
          </nav>

          <Button
            type="button"
            variant="outline"
            size="icon"
            className="md:hidden"
            aria-label={open ? 'Close menu' : 'Open menu'}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X /> : <Menu />}
          </Button>
        </div>

        {open ? (
          <nav
            className="border-t border-slate-300/60 px-4 py-3 md:hidden"
            aria-label="Mobile"
          >
            <div className="flex flex-col gap-1">
              {NAV.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={'end' in item ? item.end : false}
                  onClick={() => setOpen(false)}
                  className={({ isActive }) =>
                    cn(
                      'rounded-md px-3 py-2.5 text-sm font-medium text-slate-700',
                      isActive && 'bg-slate-200/80',
                    )
                  }
                >
                  {item.label}
                </NavLink>
              ))}
              <Button asChild className="mt-2 bg-slate-800 hover:bg-slate-900">
                <Link to="/login" onClick={() => setOpen(false)}>
                  Staff Login
                </Link>
              </Button>
            </div>
          </nav>
        ) : null}
      </header>

      <main className="flex-1">
        <Outlet />
      </main>

      <footer className="border-t border-slate-300/70 bg-slate-900 text-slate-300">
        <div className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-10 md:flex-row md:items-start md:justify-between md:px-6">
          <div>
            <p className="text-lg font-semibold text-slate-50">
              Insha Allah Traders
            </p>
            <p className="mt-1 max-w-sm text-sm text-slate-400">
              Partnership firm manufacturing sheet-metal stampings, assemblies,
              and press tooling for industrial customers in Tamil Nadu.
            </p>
          </div>
          <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
            <Link to="/capabilities" className="hover:text-slate-100">
              Capabilities
            </Link>
            <Link to="/about" className="hover:text-slate-100">
              About
            </Link>
            <Link to="/contact" className="hover:text-slate-100">
              Contact
            </Link>
            <Link to="/login" className="hover:text-slate-100">
              Staff Login
            </Link>
          </div>
        </div>
        <div className="border-t border-slate-700/80 py-4 text-center text-xs text-slate-500">
          © {new Date().getFullYear()} Insha Allah Traders. All rights reserved.
        </div>
      </footer>
    </div>
  )
}
