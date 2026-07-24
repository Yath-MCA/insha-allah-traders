import { lazy, Suspense } from 'react'
import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  CAPABILITY_COUNT,
  HOME_CAPABILITY_TEASER,
} from './capabilities'
import { HomeCarousel } from './HomeCarousel'
import { HomeImageCards } from './HomeImageCards'

const HeroMetalAccent = lazy(() =>
  import('./HeroMetalAccent').then((m) => ({ default: m.HeroMetalAccent })),
)

export function HomePage() {
  return (
    <>
      <section className="relative isolate min-h-[calc(100svh-4rem)] overflow-hidden">
        {/* Full-bleed industrial atmosphere */}
        <div
          className="absolute inset-0 -z-20 bg-[radial-gradient(ellipse_120%_80%_at_10%_20%,oklch(0.55_0.04_250_/0.22),transparent_55%),linear-gradient(125deg,oklch(0.28_0.025_255)_0%,oklch(0.38_0.03_250)_38%,oklch(0.48_0.025_230)_72%,oklch(0.42_0.02_250)_100%)]"
          aria-hidden
        />
        <div
          className="absolute inset-0 -z-10 opacity-[0.18] [background-image:linear-gradient(oklch(0.9_0.01_250_/0.35)_1px,transparent_1px),linear-gradient(90deg,oklch(0.9_0.01_250_/0.35)_1px,transparent_1px)] [background-size:48px_48px]"
          aria-hidden
        />
        <div
          className="absolute inset-0 -z-10 bg-[linear-gradient(90deg,oklch(0.22_0.02_255_/0.72)_0%,oklch(0.25_0.02_255_/0.45)_42%,transparent_78%)]"
          aria-hidden
        />

        <Suspense fallback={null}>
          <HeroMetalAccent />
        </Suspense>

        <div className="relative mx-auto flex min-h-[calc(100svh-4rem)] max-w-6xl flex-col justify-center px-4 py-16 md:px-6 md:py-20">
          <div className="website-hero-reveal max-w-xl text-slate-50">
            <p className="text-4xl font-semibold tracking-tight text-balance sm:text-5xl md:text-6xl">
              Insha Allah Traders
            </p>
            <h1 className="mt-5 text-xl font-medium tracking-tight text-slate-100 sm:text-2xl">
              Precision sheet-metal manufacturing for OEM and Tier supply
            </h1>
            <p className="mt-4 max-w-md text-base leading-relaxed text-slate-300">
              Stampings, assemblies, and press tooling from Tamil Nadu —
              built for industrial schedules and consistent quality.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Button
                asChild
                size="lg"
                className="bg-slate-100 text-slate-900 transition-transform hover:bg-white hover:scale-[1.02] active:scale-[0.98]"
              >
                <Link to="/contact">
                  Enquire
                  <ArrowRight className="size-4" />
                </Link>
              </Button>
              <Button
                asChild
                size="lg"
                variant="outline"
                className="border-slate-400/50 bg-transparent text-slate-100 transition-transform hover:bg-slate-50/10 hover:text-white hover:scale-[1.02] active:scale-[0.98]"
              >
                <Link to="/login">Staff Login</Link>
              </Button>
            </div>
            <p className="mt-10 max-w-md text-sm leading-relaxed text-slate-400">
              {HOME_CAPABILITY_TEASER}{' '}
              <Link
                to="/capabilities"
                className="font-medium text-slate-200 underline-offset-4 transition-colors hover:text-white hover:underline"
              >
                View all {CAPABILITY_COUNT} capabilities
              </Link>
            </p>
          </div>
        </div>
      </section>

      <HomeCarousel />
      <HomeImageCards />
    </>
  )
}
