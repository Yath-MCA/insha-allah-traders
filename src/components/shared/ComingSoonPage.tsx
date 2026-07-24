import { Link } from 'react-router-dom'
import { Construction } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

/** Empty state for modules scheduled after Phase 1. */
export function ComingSoonPage({
  title,
  phase,
  description,
}: {
  title: string
  phase: number
  description?: string
}) {
  return (
    <Card className="max-w-lg border-dashed">
      <CardHeader>
        <div className="mb-2 flex size-10 items-center justify-center rounded-lg bg-muted">
          <Construction className="size-5 text-muted-foreground" />
        </div>
        <CardTitle>{title}</CardTitle>
        <CardDescription>
          {description ??
            `This module ships in Phase ${phase}. Schema and RLS are already in place.`}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <p className="mb-4 text-sm text-muted-foreground">
          Coming in Phase {phase}
        </p>
        <Button asChild variant="outline">
          <Link to="/app">Back to dashboard</Link>
        </Button>
      </CardContent>
    </Card>
  )
}
