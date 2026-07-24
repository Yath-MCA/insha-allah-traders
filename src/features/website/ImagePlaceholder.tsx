import { useState } from 'react'
import { cn } from '@/lib/utils'

type ImagePlaceholderProps = {
  src: string
  alt: string
  label: string
  className?: string
  imgClassName?: string
}

function PlaceholderPanel({
  label,
  className,
}: {
  label: string
  className?: string
}) {
  return (
    <div
      className={cn(
        'relative flex size-full items-center justify-center bg-[linear-gradient(135deg,oklch(0.38_0.025_250)_0%,oklch(0.48_0.03_245)_42%,oklch(0.34_0.02_255)_100%)]',
        className,
      )}
      aria-hidden
    >
      <div className="absolute inset-0 opacity-[0.14] [background-image:linear-gradient(oklch(0.9_0.01_250_/0.4)_1px,transparent_1px),linear-gradient(90deg,oklch(0.9_0.01_250_/0.4)_1px,transparent_1px)] [background-size:40px_40px]" />
      <span className="relative px-4 text-center text-sm font-medium tracking-wide text-slate-200/90 md:text-base">
        {label}
      </span>
    </div>
  )
}

function resolveCandidates(src: string): string[] {
  if (src.endsWith('.jpg')) {
    return [src, src.replace(/\.jpg$/i, '.svg')]
  }
  return [src]
}

/**
 * Prefers `/website/*.jpg` when present; falls back to matching `.svg`
 * placeholders, then a CSS metal panel.
 */
export function ImagePlaceholder({
  src,
  alt,
  label,
  className,
  imgClassName,
}: ImagePlaceholderProps) {
  const candidates = resolveCandidates(src)
  const [index, setIndex] = useState(0)
  const [failed, setFailed] = useState(false)
  const [loaded, setLoaded] = useState(false)
  const currentSrc = candidates[index]

  return (
    <div className={cn('relative overflow-hidden bg-slate-700', className)}>
      {!loaded || failed ? <PlaceholderPanel label={label} /> : null}
      {!failed && currentSrc ? (
        <img
          key={currentSrc}
          src={currentSrc}
          alt={alt}
          className={cn(
            'size-full object-cover transition-opacity duration-300',
            loaded ? 'opacity-100' : 'absolute inset-0 opacity-0',
            imgClassName,
          )}
          onLoad={() => setLoaded(true)}
          onError={() => {
            const next = index + 1
            if (next < candidates.length) {
              setIndex(next)
              setLoaded(false)
            } else {
              setFailed(true)
            }
          }}
        />
      ) : null}
    </div>
  )
}
