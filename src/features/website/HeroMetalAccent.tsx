import { Suspense, useRef } from 'react'
import { Canvas, useFrame } from '@react-three/fiber'
import type { Group } from 'three'

function StampedPanel() {
  const group = useRef<Group>(null)

  useFrame((_, delta) => {
    if (!group.current) return
    group.current.rotation.y += delta * 0.18
    group.current.rotation.x = Math.sin(Date.now() * 0.0004) * 0.12 + 0.35
  })

  return (
    <group ref={group}>
      <mesh castShadow receiveShadow>
        <boxGeometry args={[2.4, 1.55, 0.08]} />
        <meshStandardMaterial
          color="#6b7280"
          metalness={0.82}
          roughness={0.28}
        />
      </mesh>
      <mesh position={[0, 0, 0.05]}>
        <boxGeometry args={[1.6, 0.06, 0.02]} />
        <meshStandardMaterial color="#9ca3af" metalness={0.9} roughness={0.2} />
      </mesh>
      <mesh position={[0, 0.35, 0.05]}>
        <boxGeometry args={[1.2, 0.04, 0.015]} />
        <meshStandardMaterial color="#94a3b8" metalness={0.85} roughness={0.25} />
      </mesh>
      <mesh position={[0, -0.35, 0.05]}>
        <boxGeometry args={[1.2, 0.04, 0.015]} />
        <meshStandardMaterial color="#94a3b8" metalness={0.85} roughness={0.25} />
      </mesh>
    </group>
  )
}

function Scene() {
  return (
    <>
      <ambientLight intensity={0.55} />
      <directionalLight position={[4, 5, 3]} intensity={1.35} />
      <directionalLight position={[-3, -1, -2]} intensity={0.35} color="#cbd5e1" />
      <StampedPanel />
    </>
  )
}

/** Lightweight WebGL accent — abstract stamped sheet-metal panel for the hero only. */
export function HeroMetalAccent() {
  return (
    <div
      className="pointer-events-none absolute inset-0 -z-0 opacity-90"
      aria-hidden
    >
      <div className="absolute inset-y-0 right-0 w-full max-w-xl md:max-w-2xl lg:max-w-3xl">
        <Suspense fallback={null}>
          <Canvas
            dpr={[1, 1.5]}
            camera={{ position: [0, 0, 4.2], fov: 38 }}
            gl={{ antialias: true, alpha: true, powerPreference: 'low-power' }}
            style={{ background: 'transparent' }}
          >
            <Scene />
          </Canvas>
        </Suspense>
      </div>
    </div>
  )
}
