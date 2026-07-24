export function DisclaimerFooter({ className }: { className?: string }) {
  return (
    <p
      className={
        className ??
        'border-t border-border px-4 py-3 text-center text-xs text-muted-foreground'
      }
    >
      This ERP assists bookkeeping and GST-aware invoicing. It is not a
      substitute for a Chartered Accountant or tax professional. GST rates are
      configurable by your admin — there is no GST filing API in this product.
    </p>
  )
}
