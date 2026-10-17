import type { Booking, BookingStatus } from '../types';

const dayFmt = new Intl.DateTimeFormat('en-GB', {
  weekday: 'short',
  day: 'numeric',
  month: 'short',
});

const timeFmt = new Intl.DateTimeFormat('en-US', {
  hour: 'numeric',
  minute: '2-digit',
  hour12: true,
});

const priceFmt = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
  maximumFractionDigits: 0,
});

export const formatDay = (date: Date): string => dayFmt.format(date);

export const formatTime = (date: Date): string => timeFmt.format(date);

export const formatDateTime = (date: Date): string =>
  `${formatDay(date)} · ${formatTime(date)}`;

export const formatPrice = (value: number): string => priceFmt.format(value);

export const formatDuration = (mins: number): string => {
  if (mins < 60) return `${mins} min`;
  const hours = Math.floor(mins / 60);
  const rest = mins % 60;
  return rest === 0 ? `${hours} hr` : `${hours} hr ${rest} min`;
};

const startOfDay = (date: Date): number =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();

/** "Today" / "Tomorrow" / "Yesterday", falling back to a short date. */
export const relativeDay = (date: Date): string => {
  const days = Math.round(
    (startOfDay(date) - startOfDay(new Date())) / 86_400_000,
  );
  if (days === 0) return 'Today';
  if (days === 1) return 'Tomorrow';
  if (days === -1) return 'Yesterday';
  return formatDay(date);
};

export const isUpcoming = (booking: Booking): boolean =>
  booking.status === 'confirmed' || booking.status === 'pending';

export interface StatusMeta {
  label: string;
  /** Pill classes. */
  pill: string;
  /** Dot classes. */
  dot: string;
}

export const STATUS_META: Record<BookingStatus, StatusMeta> = {
  confirmed: {
    label: 'Confirmed',
    pill: 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200',
    dot: 'bg-emerald-500',
  },
  pending: {
    label: 'Pending',
    pill: 'bg-amber-50 text-amber-700 ring-1 ring-amber-200',
    dot: 'bg-amber-500',
  },
  completed: {
    label: 'Completed',
    pill: 'bg-slate-100 text-slate-600 ring-1 ring-slate-200',
    dot: 'bg-slate-400',
  },
  cancelled: {
    label: 'Cancelled',
    pill: 'bg-rose-50 text-rose-700 ring-1 ring-rose-200',
    dot: 'bg-rose-500',
  },
};

/** Combines a `yyyy-mm-dd` input value and an `hh:mm` input value. */
export const toDateTime = (date: string, time: string): Date => {
  const [year, month, day] = date.split('-').map(Number);
  const [hour, minute] = time.split(':').map(Number);
  return new Date(year, month - 1, day, hour, minute, 0, 0);
};

/** The `yyyy-mm-dd` value for a date input. */
export const toDateInput = (date: Date): string => {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
};

/** The `hh:mm` value for a time input. */
export const toTimeInput = (date: Date): string => {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
};
