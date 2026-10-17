import type { LucideIcon } from 'lucide-react';

interface StatCardProps {
  label: string;
  value: number;
  icon: LucideIcon;
  hint: string;
  tone?: 'default' | 'highlight';
  badge?: string;
}

const TONES: Record<'default', { tile: string; icon: string }> = {
  default: {
    tile: 'bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100',
    icon: 'text-indigo-600',
  },
};

export function StatCard({
  label,
  value,
  icon: Icon,
  hint,
  tone = 'default',
  badge,
}: StatCardProps) {
  if (tone === 'highlight') {
    return (
      <div className="relative overflow-hidden rounded-2xl bg-linear-to-br from-indigo-600 to-violet-600 p-5 text-white shadow-lg shadow-indigo-600/25">
        <span
          className="absolute -right-8 -top-10 h-32 w-32 rounded-full bg-white/10"
          aria-hidden="true"
        />
        <span
          className="absolute -bottom-12 -left-6 h-28 w-28 rounded-full bg-white/5"
          aria-hidden="true"
        />
        <div className="relative flex items-start justify-between gap-3">
          <span className="grid h-11 w-11 place-items-center rounded-xl bg-white/15 ring-1 ring-white/25">
            <Icon className="h-5 w-5" />
          </span>
          {badge ? (
            <span className="rounded-full bg-white/15 px-2.5 py-1 text-[11px] font-semibold ring-1 ring-white/20">
              {badge}
            </span>
          ) : null}
        </div>
        <p className="relative mt-4 text-3xl font-bold leading-none tracking-tight">
          {value}
        </p>
        <p className="relative mt-1.5 text-sm font-medium text-white/85">
          {label}
        </p>
        <p className="relative mt-3 text-xs text-white/75">{hint}</p>
      </div>
    );
  }

  const toneStyles = TONES.default;
  return (
    <div className="rounded-2xl border border-slate-200/80 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
      <div className="flex items-start justify-between gap-3">
        <span
          className={`grid h-11 w-11 place-items-center rounded-xl ${toneStyles.tile}`}
        >
          <Icon className={`h-5 w-5 ${toneStyles.icon}`} />
        </span>
        {badge ? (
          <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600">
            {badge}
          </span>
        ) : null}
      </div>
      <p className="mt-4 text-3xl font-bold leading-none tracking-tight text-slate-900">
        {value}
      </p>
      <p className="mt-1.5 text-sm font-medium text-slate-600">{label}</p>
      <p className="mt-3 text-xs text-slate-400">{hint}</p>
    </div>
  );
}
