import { Link } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'
import { HOME_IMAGE_CARDS, HOME_TRUST_STRIP } from './homeContent'
import { ImagePlaceholder } from './ImagePlaceholder'

export function HomeImageCards() {
  return (
    <section className="website-section-reveal border-t border-slate-300/70 bg-white">
      <div className="mx-auto max-w-6xl px-4 py-14 md:px-6 md:py-16">
        <header className="max-w-2xl">
          <p className="text-xs font-medium tracking-[0.18em] text-slate-500 uppercase">
            Capabilities
          </p>
          <h2 className="mt-2 text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
            What we manufacture
          </h2>
          <p className="mt-3 text-base leading-relaxed text-slate-600">
            Three focus areas spanning stampings, assemblies, and in-house
            tooling development.
          </p>
        </header>

        <ul className="mt-10 grid gap-6 md:grid-cols-3">
          {HOME_IMAGE_CARDS.map((card) => (
            <li key={card.href}>
              <Link
                to={card.href}
                className="group block border border-slate-300/80 transition-transform hover:scale-[1.01] active:scale-[0.99] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-slate-700"
              >
                <ImagePlaceholder
                  src={card.src}
                  alt={card.title}
                  label={card.label}
                  className="aspect-[4/3] w-full"
                  imgClassName="transition-transform duration-500 group-hover:scale-[1.04]"
                />
                <div className="border-t border-slate-300/80 bg-slate-50 px-4 py-4 md:px-5">
                  <h3 className="text-lg font-semibold tracking-tight text-slate-900">
                    {card.title}
                  </h3>
                  <p className="mt-1.5 text-sm leading-relaxed text-slate-600">
                    {card.description}
                  </p>
                  <span className="mt-3 inline-flex items-center gap-1.5 text-sm font-medium text-slate-800">
                    View capabilities
                    <ArrowRight className="size-3.5 transition-transform group-hover:translate-x-0.5" />
                  </span>
                </div>
              </Link>
            </li>
          ))}
        </ul>

        <p className="mt-12 border-t border-slate-300/70 pt-8 text-center text-sm tracking-wide text-slate-500">
          {HOME_TRUST_STRIP.join(' · ')}
        </p>
      </div>
    </section>
  )
}
