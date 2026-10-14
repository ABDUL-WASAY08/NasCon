export default function Logo({ size = 30, withWordmark = true }) {
  return (
    <span className="inline-flex items-center gap-2.5" aria-label="NEXUS">
      <svg
        width={size}
        height={size}
        viewBox="0 0 64 64"
        role="img"
        aria-hidden="true"
        focusable="false"
      >
        <rect width="64" height="64" rx="15" fill="var(--color-surface-3)" />
        <g fill="none" stroke="var(--color-live)" strokeWidth="2.4" strokeLinecap="round">
          <path d="M20 20 L44 44 M44 20 L20 44" opacity="0.6" />
          <path d="M32 13 L32 51" opacity="0.32" />
          <path d="M13 32 L51 32" opacity="0.32" />
        </g>
        <g fill="var(--color-live)">
          <circle cx="32" cy="32" r="6.5" />
          <circle cx="20" cy="20" r="3.4" opacity="0.9" />
          <circle cx="44" cy="20" r="3.4" opacity="0.9" />
          <circle cx="20" cy="44" r="3.4" opacity="0.9" />
          <circle cx="44" cy="44" r="3.4" opacity="0.9" />
        </g>
      </svg>
      {withWordmark && (
        <span className="font-display text-[1.06rem] font-bold tracking-[0.14em] text-ink">
          NEXUS
        </span>
      )}
    </span>
  )
}
