export default function StatCard({ label, value, foot, small = false }) {
  return (
    <article className="panel flex flex-col gap-2 p-6">
      <span className="font-mono text-[0.7rem] uppercase tracking-[0.1em] text-faint">{label}</span>
      <strong
        className={`font-display font-semibold text-ink ${
          small ? 'text-[1.15rem] leading-snug' : 'text-[2rem] leading-none'
        }`}
      >
        {value}
      </strong>
      {foot && <span className="text-[0.78rem] text-muted">{foot}</span>}
    </article>
  )
}
