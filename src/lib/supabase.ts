import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn(
    'Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY. Copy .env.example to .env.local and fill in your Supabase project values.',
  )
}

/**
 * Browser Supabase client — uses the anon key only.
 * Never import or embed the service role key in the frontend.
 */
export const supabase = createClient(
  supabaseUrl ?? '',
  supabaseAnonKey ?? '',
)
