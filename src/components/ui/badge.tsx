import type { ComponentProps } from 'react'
import { cn } from '@/lib/utils'

function Badge({
  className,
  variant = 'default',
  ...props
}: ComponentProps<'span'> & {
  variant?: 'default' | 'secondary' | 'outline' | 'destructive'
}) {
  return (
    <span
      data-slot="badge"
      className={cn(
        'inline-flex items-center rounded-md border px-1.5 py-0.5 text-xs font-medium',
        variant === 'default' &&
          'border-transparent bg-primary text-primary-foreground',
        variant === 'secondary' &&
          'border-transparent bg-secondary text-secondary-foreground',
        variant === 'outline' && 'border-border text-foreground',
        variant === 'destructive' &&
          'border-transparent bg-destructive/15 text-destructive',
        className,
      )}
      {...props}
    />
  )
}

export { Badge }
