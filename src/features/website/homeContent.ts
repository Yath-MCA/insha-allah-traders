export type HomeCarouselSlide = {
  src: string
  alt: string
  caption: string
}

export type HomeImageCard = {
  src: string
  title: string
  description: string
  href: string
  label: string
}

/** Facility / capability / trust slides — replace JPGs in public/website/ without code changes. */
export const HOME_CAROUSEL_SLIDES: HomeCarouselSlide[] = [
  {
    src: '/website/carousel-01.jpg',
    alt: 'Press bay and facility floor',
    caption: 'Facility and press bay — production capacity for industrial schedules',
  },
  {
    src: '/website/carousel-02.jpg',
    alt: 'Sheet metal stampings and pressed components',
    caption: 'Stampings and components for OEM and Tier programmes',
  },
  {
    src: '/website/carousel-03.jpg',
    alt: 'Welded sheet metal assembly',
    caption: 'Assemblies and finishing — welded, riveted, and coated work',
  },
  {
    src: '/website/carousel-04.jpg',
    alt: 'Tool room with press die',
    caption: 'Partnership firm · Tamil Nadu manufacturing for OEM and Tier supply',
  },
]

export const HOME_IMAGE_CARDS: HomeImageCard[] = [
  {
    src: '/website/card-stampings.jpg',
    title: 'Stampings and components',
    description:
      'Sheet metal stampings, pressed parts, and fabricated components.',
    href: '/capabilities#stampings',
    label: 'Stampings and components',
  },
  {
    src: '/website/card-assemblies.jpg',
    title: 'Assemblies and finishing',
    description: 'Welded and riveted assemblies with coated components.',
    href: '/capabilities#assemblies',
    label: 'Assemblies and finishing',
  },
  {
    src: '/website/card-tooling.jpg',
    title: 'Tooling and development',
    description: 'Press tools, dies, jigs, fixtures, and tool design.',
    href: '/capabilities#tooling',
    label: 'Tooling and development',
  },
]

export const HOME_TRUST_STRIP = [
  'Partnership firm',
  'Tamil Nadu',
  'Sheet metal & tooling',
] as const
