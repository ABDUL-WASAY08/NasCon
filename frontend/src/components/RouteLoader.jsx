export default function RouteLoader({ label = 'Checking your session' }) {
  return (
    <div
      className="flex flex-1 flex-col items-center justify-center gap-4 min-h-[60svh] text-faint"
      role="status"
      aria-live="polite"
    >
      <span
        className="h-6 w-6 rounded-full border-2 border-line-strong border-t-live animate-spin"
        aria-hidden="true"
      />
      <span className="mono">{label}…</span>
    </div>
  )
}
