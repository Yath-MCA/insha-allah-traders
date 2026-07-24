import { Link } from 'react-router-dom'
import { Mail, MapPin, Phone } from 'lucide-react'
import { Button } from '@/components/ui/button'

const phone =
  import.meta.env.VITE_PUBLIC_PHONE?.trim() || '+91 XXXXX XXXXX'
const email =
  import.meta.env.VITE_PUBLIC_EMAIL?.trim() || 'enquiries@example.com'
const address =
  import.meta.env.VITE_PUBLIC_ADDRESS?.trim() ||
  'Tamil Nadu, India (address to be confirmed)'

export function ContactPage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-14 md:px-6 md:py-20">
      <header className="website-section-reveal max-w-2xl">
        <p className="text-xs font-medium tracking-[0.18em] text-slate-500 uppercase">
          Reach us
        </p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 md:text-4xl">
          Contact
        </h1>
        <p className="mt-3 text-base leading-relaxed text-slate-600">
          For RFQs, drawings, and capability discussions — use the details
          below. Staff ERP access is separate via Staff Login.
        </p>
      </header>

      <div className="website-section-reveal mt-12 grid max-w-2xl gap-8">
        <div className="flex gap-4">
          <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-slate-200/80 text-slate-700">
            <Phone className="size-5" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Phone</p>
            <a
              href={phone.startsWith('+') || phone.startsWith('0') ? `tel:${phone.replace(/\s/g, '')}` : undefined}
              className="mt-0.5 block text-lg font-medium text-slate-900"
            >
              {phone}
            </a>
          </div>
        </div>

        <div className="flex gap-4">
          <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-slate-200/80 text-slate-700">
            <Mail className="size-5" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Email</p>
            <a
              href={`mailto:${email}`}
              className="mt-0.5 block text-lg font-medium text-slate-900 underline-offset-4 hover:underline"
            >
              {email}
            </a>
          </div>
        </div>

        <div className="flex gap-4">
          <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-slate-200/80 text-slate-700">
            <MapPin className="size-5" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Address</p>
            <p className="mt-0.5 text-lg font-medium text-slate-900">{address}</p>
          </div>
        </div>
      </div>

      <div className="mt-14 flex flex-wrap gap-3 border-t border-slate-300/80 pt-10">
        <Button asChild variant="outline">
          <Link to="/capabilities">Browse capabilities</Link>
        </Button>
        <Button
          asChild
          className="bg-slate-800 transition-transform hover:bg-slate-900 hover:scale-[1.02]"
        >
          <Link to="/login">Staff Login</Link>
        </Button>
      </div>
    </div>
  )
}
