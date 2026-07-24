import { useCallback, useEffect, useState } from 'react'
import useEmblaCarousel from 'embla-carousel-react'
import Autoplay from 'embla-carousel-autoplay'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { HOME_CAROUSEL_SLIDES } from './homeContent'
import { ImagePlaceholder } from './ImagePlaceholder'

export function HomeCarousel() {
  const [selectedIndex, setSelectedIndex] = useState(0)
  const [emblaRef, emblaApi] = useEmblaCarousel({ loop: true, duration: 28 }, [
    Autoplay({ delay: 4500, stopOnInteraction: false, stopOnMouseEnter: true }),
  ])

  const onSelect = useCallback(() => {
    if (!emblaApi) return
    setSelectedIndex(emblaApi.selectedScrollSnap())
  }, [emblaApi])

  useEffect(() => {
    if (!emblaApi) return
    onSelect()
    emblaApi.on('select', onSelect)
    emblaApi.on('reInit', onSelect)
    return () => {
      emblaApi.off('select', onSelect)
      emblaApi.off('reInit', onSelect)
    }
  }, [emblaApi, onSelect])

  const scrollPrev = useCallback(() => emblaApi?.scrollPrev(), [emblaApi])
  const scrollNext = useCallback(() => emblaApi?.scrollNext(), [emblaApi])

  return (
    <section
      className="website-section-reveal border-t border-slate-300/70 bg-slate-100/80"
      aria-roledescription="carousel"
      aria-label="Facility and manufacturing work"
    >
      <div className="mx-auto max-w-6xl px-4 py-14 md:px-6 md:py-16">
        <header className="max-w-2xl">
          <p className="text-xs font-medium tracking-[0.18em] text-slate-500 uppercase">
            On the floor
          </p>
          <h2 className="mt-2 text-2xl font-semibold tracking-tight text-slate-900 md:text-3xl">
            Facility and work
          </h2>
          <p className="mt-3 text-base leading-relaxed text-slate-600">
            A look at press capacity, stampings, assemblies, and tooling —
            the work behind OEM and Tier supply.
          </p>
        </header>

        <div className="group relative mt-8">
          <div className="overflow-hidden border border-slate-400/50" ref={emblaRef}>
            <div className="flex touch-pan-y">
              {HOME_CAROUSEL_SLIDES.map((slide) => (
                <div
                  key={slide.src}
                  className="min-w-0 shrink-0 grow-0 basis-full"
                  role="group"
                  aria-roledescription="slide"
                >
                  <ImagePlaceholder
                    src={slide.src}
                    alt={slide.alt}
                    label={slide.caption}
                    className="aspect-[16/9] w-full md:aspect-[21/9]"
                  />
                  <p className="border-t border-slate-300/80 bg-slate-50 px-4 py-3 text-sm text-slate-700 md:px-5">
                    {slide.caption}
                  </p>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-4 flex items-center justify-between gap-4">
            <div className="flex gap-2" role="tablist" aria-label="Carousel slides">
              {HOME_CAROUSEL_SLIDES.map((slide, index) => (
                <button
                  key={slide.src}
                  type="button"
                  role="tab"
                  aria-selected={index === selectedIndex}
                  aria-label={`Go to slide ${index + 1}`}
                  className={cn(
                    'h-2.5 w-6 border border-slate-500/60 transition-colors',
                    index === selectedIndex
                      ? 'bg-slate-800'
                      : 'bg-slate-300 hover:bg-slate-400',
                  )}
                  onClick={() => emblaApi?.scrollTo(index)}
                />
              ))}
            </div>

            <div className="flex gap-2">
              <Button
                type="button"
                variant="outline"
                size="icon"
                className="size-9 rounded-none border-slate-400/70"
                aria-label="Previous slide"
                onClick={scrollPrev}
              >
                <ChevronLeft className="size-4" />
              </Button>
              <Button
                type="button"
                variant="outline"
                size="icon"
                className="size-9 rounded-none border-slate-400/70"
                aria-label="Next slide"
                onClick={scrollNext}
              >
                <ChevronRight className="size-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
