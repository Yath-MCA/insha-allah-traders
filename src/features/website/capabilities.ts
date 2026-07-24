export type CapabilityGroup = {
  id: string
  title: string
  items: string[]
}

/** Canonical manufacturing catalogue — keep Home teaser + Capabilities in sync. */
export const CAPABILITY_GROUPS: CapabilityGroup[] = [
  {
    id: 'stampings',
    title: 'Stampings and components',
    items: [
      'Sheet metal stampings',
      'Pressed components',
      'Fabricated sheet metal components',
      'Engine parts',
      'Front-end structure parts',
      'Automotive body parts',
      'Cylinders',
    ],
  },
  {
    id: 'assemblies',
    title: 'Assemblies and finishing',
    items: [
      'Sheet metal assemblies',
      'Welded assemblies',
      'Riveted assemblies',
      'Coated components',
    ],
  },
  {
    id: 'tooling',
    title: 'Tooling and development',
    items: [
      'Press tools',
      'Dies',
      'Jigs',
      'Fixtures',
      'Tool design and development',
    ],
  },
]

export const ALL_CAPABILITIES = CAPABILITY_GROUPS.flatMap((g) => g.items)

export const CAPABILITY_COUNT = ALL_CAPABILITIES.length

/** Short teaser labels for the home page (not the full catalogue). */
export const HOME_CAPABILITY_TEASER =
  'Sheet metal stampings, pressed components, welded assemblies, and press tooling for OEM and Tier supply.'
