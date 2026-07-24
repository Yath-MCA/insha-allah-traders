/** IANA timezone for all business date/time display */
export const IST_TIMEZONE = 'Asia/Kolkata'

function toDate(value: Date | string | number): Date {
  if (value instanceof Date) return value
  return new Date(value)
}

/** Format amount as Indian Rupees (e.g. ₹1,23,456.78) */
export function formatINR(
  amount: number,
  options?: { minimumFractionDigits?: number; maximumFractionDigits?: number },
): string {
  const {
    minimumFractionDigits = 2,
    maximumFractionDigits = 2,
  } = options ?? {}

  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits,
    maximumFractionDigits,
  }).format(amount)
}

/** Parts of a date/time in Asia/Kolkata */
export function getISTParts(value: Date | string | number = new Date()) {
  const date = toDate(value)
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: IST_TIMEZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date)

  const get = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((p) => p.type === type)?.value ?? '00'

  return {
    day: get('day'),
    month: get('month'),
    year: get('year'),
    hour: get('hour'),
    minute: get('minute'),
    second: get('second'),
  }
}

/** Format a date as DD/MM/YYYY in Asia/Kolkata */
export function formatDateDDMMYYYY(value: Date | string | number): string {
  const { day, month, year } = getISTParts(value)
  return `${day}/${month}/${year}`
}

/** Format date+time as DD/MM/YYYY HH:mm in Asia/Kolkata */
export function formatDateTimeIST(value: Date | string | number): string {
  const { day, month, year, hour, minute } = getISTParts(value)
  return `${day}/${month}/${year} ${hour}:${minute}`
}

/**
 * Convert an instant to a Date whose local getters approximate IST wall-clock.
 * Prefer formatDateDDMMYYYY / formatDateTimeIST for display.
 */
export function toIST(value: Date | string | number): Date {
  const { year, month, day, hour, minute, second } = getISTParts(value)
  return new Date(
    Number(year),
    Number(month) - 1,
    Number(day),
    Number(hour),
    Number(minute),
    Number(second),
  )
}

/** Current instant expressed as an IST wall-clock Date */
export function nowIST(): Date {
  return toIST(new Date())
}

/**
 * Indian financial year label for a given date (Apr 1 – Mar 31 IST).
 * Example: 15 Jun 2026 → "2026-27"
 */
export function getFinancialYearLabel(
  value: Date | string | number = new Date(),
): string {
  const { year, month } = getISTParts(value)
  const y = Number(year)
  const m = Number(month)
  const startYear = m >= 4 ? y : y - 1
  const endYearShort = String(startYear + 1).slice(-2)
  return `${startYear}-${endYearShort}`
}
