import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { CAPABILITY_GROUPS } from './capabilities'

export function CapabilitiesPage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-14 md:px-6 md:py-20">
      <header className="website-section-reveal max-w-2xl">
        <p className="text-xs font-medium tracking-[0.18em] text-slate-500 uppercase">
          Manufacturing catalogue
        </p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 md:text-4xl">
          Capabilities
        </h1>
        <p className="mt-3 text-base leading-relaxed text-slate-600">
          Full scope for OEM and Tier customers — stampings, assemblies,
          finishing, and in-house tooling development.
        </p>
      </header>

      <div className="mt-14 space-y-16">
        {CAPABILITY_GROUPS.map((group, gi) => (
          <section
            key={group.id}
            id={group.id}
            className="website-capability-block scroll-mt-24"
            style={{ animationDelay: `${gi * 80}ms` }}
          >
            <h2 className="border-b border-slate-300/80 pb-3 text-xl font-semibold tracking-tight text-slate-900">
              {group.title}
            </h2>
            <ol className="mt-6 grid gap-x-10 gap-y-3 sm:grid-cols-2">
              {group.items.map((item, i) => (
                <li
                  key={item}
                  className="flex gap-3 text-slate-700"
                >
                  <span className="w-7 shrink-0 tabular-nums text-sm font-medium text-slate-400">
                    {String(
                      CAPABILITY_GROUPS.slice(0, gi).reduce(
                        (n, g) => n + g.items.length,
                        0,
                      ) +
                        i +
                        1,
                    ).padStart(2, '0')}
                  </span>
                  <span className="text-base leading-snug">{item}</span>
                </li>
              ))}
            </ol>
          </section>
        ))}
      </div>

      <div className="mt-16 flex flex-wrap items-center gap-4 border-t border-slate-300/80 pt-10">
        <p className="text-sm text-slate-600">
          Discuss drawings, volumes, or tooling programs with our team.
        </p>
        <Button
          asChild
          className="bg-slate-800 transition-transform hover:bg-slate-900 hover:scale-[1.02]"
        >
          <Link to="/contact">
            Contact us
            <ArrowRight className="size-4" />
          </Link>
        </Button>
      </div>
    </div>
  )
}
