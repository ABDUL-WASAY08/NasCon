import { CalendarClock, Inbox, MapPin, RotateCcw } from 'lucide-react';

import type { AppointmentFilter, Booking } from '../types';
import {
  formatDuration,
  formatTime,
  isUpcoming,
  relativeDay,
} from '../lib/format';
import { Button, Panel, StatusBadge } from './ui';

const FILTERS: ReadonlyArray<{ id: AppointmentFilter; label: string }> = [
  { id: 'all', label: 'All' },
  { id: 'upcoming', label: 'Upcoming' },
  { id: 'completed', label: 'Completed' },
];

interface AppointmentsProps {
  bookings: Booking[];
  filter: AppointmentFilter;
  onFilterChange: (filter: AppointmentFilter) => void;
  onCancel: (booking: Booking) => void;
  onReschedule: (booking: Booking) => void;
  onBookAgain: (booking: Booking) => void;
}

/** Upcoming first (soonest to latest), then past bookings (most recent first). */
const sortByRelevance = (bookings: Booking[]): Booking[] =>
  [...bookings].sort((a, b) => {
    const aUpcoming = isUpcoming(a) ? 0 : 1;
    const bUpcoming = isUpcoming(b) ? 0 : 1;
    if (aUpcoming !== bUpcoming) return aUpcoming - bUpcoming;
    return aUpcoming === 0
      ? a.start.getTime() - b.start.getTime()
      : b.start.getTime() - a.start.getTime();
  });

export function Appointments({
  bookings,
  filter,
  onFilterChange,
  onCancel,
  onReschedule,
  onBookAgain,
}: AppointmentsProps) {
  const counts: Record<AppointmentFilter, number> = {
    all: bookings.length,
    upcoming: bookings.filter(isUpcoming).length,
    completed: bookings.filter((b) => b.status === 'completed').length,
  };

  const visible = sortByRelevance(bookings).filter((booking) => {
    if (filter === 'upcoming') return isUpcoming(booking);
    if (filter === 'completed') return booking.status === 'completed';
    return true;
  });

  return (
    <Panel>
      {/* Card header */}
      <div className="flex flex-col gap-3 border-b border-slate-100 px-5 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
        <div className="flex items-center gap-2.5">
          <span className="grid h-9 w-9 place-items-center rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100">
            <CalendarClock className="h-4 w-4" />
          </span>
          <div>
            <h2 className="text-base font-semibold tracking-tight text-slate-900">
              Appointments
            </h2>
            <p className="text-xs text-slate-500">
              {counts.upcoming} upcoming · {counts.completed} completed
            </p>
          </div>
        </div>

        {/* Filter */}
        <div
          role="tablist"
          aria-label="Filter appointments"
          className="inline-flex rounded-xl bg-slate-100 p-1"
        >
          {FILTERS.map(({ id, label }) => {
            const active = filter === id;
            return (
              <button
                key={id}
                type="button"
                role="tab"
                aria-selected={active}
                onClick={() => onFilterChange(id)}
                className={`rounded-lg px-3 py-1.5 text-xs font-semibold transition focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40 ${
                  active
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-700'
                }`}
              >
                {label}
                <span className="ml-1.5 text-slate-400">{counts[id]}</span>
              </button>
            );
          })}
        </div>
      </div>

      {visible.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-2 px-6 py-14 text-center">
          <span className="grid h-12 w-12 place-items-center rounded-2xl bg-slate-100 text-slate-400">
            <Inbox className="h-6 w-6" />
          </span>
          <p className="text-sm font-semibold text-slate-700">
            Nothing here yet
          </p>
          <p className="max-w-xs text-sm text-slate-500">
            No appointments match this filter. Try another tab or book a new
            service.
          </p>
        </div>
      ) : (
        <>
          {/* Desktop table */}
          <div className="hidden md:block">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-100 text-[11px] uppercase tracking-wider text-slate-500">
                  <th scope="col" className="px-6 py-3 font-semibold">
                    Service
                  </th>
                  <th scope="col" className="px-6 py-3 font-semibold">
                    Date &amp; time
                  </th>
                  <th scope="col" className="px-6 py-3 font-semibold">
                    Status
                  </th>
                  <th scope="col" className="px-6 py-3 text-right font-semibold">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {visible.map((booking) => (
                  <tr
                    key={booking.id}
                    className="transition hover:bg-slate-50/70"
                  >
                    <td className="px-6 py-4">
                      <p className="font-semibold text-slate-900">
                        {booking.service}
                      </p>
                      <p className="mt-0.5 text-xs text-slate-500">
                        {booking.provider} · {booking.location}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <p className="font-medium text-slate-800">
                        {relativeDay(booking.start)}
                      </p>
                      <p className="mt-0.5 text-xs text-slate-500">
                        {formatTime(booking.start)} ·{' '}
                        {formatDuration(booking.durationMins)}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <StatusBadge status={booking.status} />
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex justify-end gap-2">
                        {isUpcoming(booking) ? (
                          <>
                            <Button
                              variant="outline"
                              className="px-3 py-1.5 text-xs"
                              onClick={() => onReschedule(booking)}
                            >
                              Reschedule
                            </Button>
                            <Button
                              variant="danger"
                              className="px-3 py-1.5 text-xs"
                              onClick={() => onCancel(booking)}
                            >
                              Cancel
                            </Button>
                          </>
                        ) : (
                          <Button
                            variant="ghost"
                            className="px-3 py-1.5 text-xs"
                            onClick={() => onBookAgain(booking)}
                          >
                            <RotateCcw className="h-3.5 w-3.5" />
                            Book again
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobile cards */}
          <ul className="divide-y divide-slate-100 md:hidden">
            {visible.map((booking) => (
              <li key={booking.id} className="px-5 py-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-semibold text-slate-900">
                      {booking.service}
                    </p>
                    <p className="mt-0.5 truncate text-xs text-slate-500">
                      {booking.provider}
                    </p>
                  </div>
                  <StatusBadge status={booking.status} />
                </div>

                <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1.5 text-xs text-slate-500">
                  <span className="inline-flex items-center gap-1.5">
                    <CalendarClock className="h-3.5 w-3.5" />
                    {relativeDay(booking.start)} · {formatTime(booking.start)}
                  </span>
                  <span className="inline-flex items-center gap-1.5">
                    <MapPin className="h-3.5 w-3.5" />
                    {booking.location}
                  </span>
                </div>

                <div className="mt-3 flex gap-2">
                  {isUpcoming(booking) ? (
                    <>
                      <Button
                        variant="outline"
                        className="flex-1 px-3 py-2 text-xs"
                        onClick={() => onReschedule(booking)}
                      >
                        Reschedule
                      </Button>
                      <Button
                        variant="danger"
                        className="flex-1 px-3 py-2 text-xs"
                        onClick={() => onCancel(booking)}
                      >
                        Cancel
                      </Button>
                    </>
                  ) : (
                    <Button
                      variant="outline"
                      className="w-full px-3 py-2 text-xs"
                      onClick={() => onBookAgain(booking)}
                    >
                      <RotateCcw className="h-3.5 w-3.5" />
                      Book again
                    </Button>
                  )}
                </div>
              </li>
            ))}
          </ul>
        </>
      )}
    </Panel>
  );
}
