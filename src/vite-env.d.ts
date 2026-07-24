/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_ANON_KEY: string
  readonly VITE_PUBLIC_PHONE?: string
  readonly VITE_PUBLIC_EMAIL?: string
  readonly VITE_PUBLIC_ADDRESS?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
