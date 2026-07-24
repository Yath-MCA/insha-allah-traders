import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'

export function AboutPage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-14 md:px-6 md:py-20">
      <header className="website-section-reveal max-w-2xl">
        <p className="text-xs font-medium tracking-[0.18em] text-slate-500 uppercase">
          Company
        </p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 md:text-4xl">
          About Insha Allah Traders
        </h1>
        <p className="mt-3 text-base leading-relaxed text-slate-600">
          A partnership firm focused on sheet-metal stampings, assemblies, and
          press tooling for industrial customers across Tamil Nadu.
        </p>
      </header>

      <div className="website-section-reveal mt-12 max-w-3xl space-y-6 text-base leading-relaxed text-slate-700">
        <p>
          We supply OEM and Tier programmes with stamped and fabricated
          components, welded and riveted assemblies, coated parts, and the press
          tools, dies, jigs, and fixtures that keep production repeatable.
        </p>
        <p>
          Operations are rooted in Tamil Nadu&apos;s manufacturing corridor —
          close to automotive and engineering demand, with schedules and quality
          expectations that match industrial supply chains.
        </p>
        <p>
          Company legal, GST, and bank details for transactions are managed
          inside our staff ERP. This site is the public face of our
          manufacturing capability.
        </p>
      </div>

      <div className="mt-12 flex flex-wrap gap-3">
        <Button asChild className="bg-slate-800 hover:bg-slate-900">
          <Link to="/capabilities">View capabilities</Link>
        </Button>
        <Button asChild variant="outline">
          <Link to="/contact">Get in touch</Link>
        </Button>
      </div>
    </div>
  )
}
