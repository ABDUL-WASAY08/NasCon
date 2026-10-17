import { CalendarDays, Clock } from 'lucide-react';

import type { Booking } from '../types';
import {
  formatDuration,
  formatTime,
  isUpcoming,
  relativeDay,
} from '../lib/format';
import { Modal, StatusBadge } from './ui';

const WEEK_LENGTH = 7;

const sameDay = (a: Date, b: Date): boolean =>
  a.getFullYear() === b.getFullYear() &&
  a.getMonth() === b.getMonth() &&
  a.getDate() === b.getDate();

export function ScheduleModal({
  open,
  onClose,
  bookings,
}: {
  open: boolean;
  onClose: () => void;
  bookings: Booking[];
}) {
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const days = Array.from({ length: WEEK_LENGTH }, (_, index) => {
    const day = new Date(startOfToday);
    day.setDate(day.getDate() + index);
    return day;
  });

  const upcoming = bookings.filter(isUpcoming);

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Your schedule"
      description="The next 7 days at a glance."
    >
      <ol className="space-y-3">
        {days.map((day) => {
          const onThisDay = upcoming
            .filter((booking) => sameDay(booking.start, day))
            .sort((a, b) => a.start.getTime() - b.start.getTime());

          return (
            <li
              key={day.toISOString()}
              className="rounded-2xl border border-slate-200/80 bg-white p-4 shadow-sm"
            >
              <div className="flex items-center justify-between gap-3">
                <p className="text-sm font-semibold text-slate-900">
                  {relativeDay(day)}
                </p>
                <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-500">
                  {onThisDay.length}{' '}
                  {onThisDay.length === 1 ? 'booking' : 'bookings'}
                </span>
              </div>

              {onThisDay.length === 0 ? (
                <p className="mt-2 flex items-center gap-1.5 text-xs text-slate-400">
                  <CalendarDays className="h-3.5 w-3.5" />
                  No appointments scheduled
                </p>
              ) : (
                <ul className="mt-3 space-y-2">
                  {onThisDay.map((booking) => (
                    <li
                      key={booking.id}
                      className="flex items-center justify-between gap-3 rounded-xl bg-slate-50 px-3.5 py-2.5"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-slate-800">
                          {booking.service}
                        </p>
                        <p className="mt-0.5 flex items-center gap-1.5 text-xs text-slate-500">
                          <Clock className="h-3.5 w-3.5" />
                          {formatTime(booking.start)} ·{' '}
                          {formatDuration(booking.durationMins)}
                        </p>
                      </div>
                      <StatusBadge status={booking.status} />
                    </li>
                  ))}
                </ul>
              )}
            </li>
          );
        })}
      </ol>
    </Modal>
  );
}
