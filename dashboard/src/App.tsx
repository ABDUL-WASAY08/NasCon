import { useMemo, useState } from 'react';
import {
  CalendarCheck,
  CalendarClock,
  CheckCircle2,
  Clock,
} from 'lucide-react';

import { AiChatDrawer } from './components/AiChatDrawer';
import { Appointments } from './components/Appointments';
import { BookingModal, type BookingDraft } from './components/BookingModal';
import { Header } from './components/Header';
import { QuickActions } from './components/QuickActions';
import { RescheduleModal } from './components/RescheduleModal';
import { ScheduleModal } from './components/ScheduleModal';
import { StatCard } from './components/StatCard';
import { Toast } from './components/ui';
import { computeStats, nextUpcoming, seedBookings, USER_NAME } from './lib/data';
import { formatPrice, formatTime, relativeDay, toDateTime } from './lib/format';
import type { AppointmentFilter, Booking, BookingStatus } from './types';

const withStatus = (booking: Booking, status: BookingStatus): Booking => ({
  ...booking,
  status,
});

export default function App() {
  const [bookings, setBookings] = useState<Booking[]>(seedBookings);
  const [filter, setFilter] = useState<AppointmentFilter>('all');
  const [bookingOpen, setBookingOpen] = useState(false);
  const [rescheduleTarget, setRescheduleTarget] = useState<Booking | null>(null);
  const [chatOpen, setChatOpen] = useState(false);
  const [scheduleOpen, setScheduleOpen] = useState(false);
  const [toast, setToast] = useState<{ id: number; message: string } | null>(
    null,
  );

  const stats = useMemo(() => computeStats(bookings), [bookings]);
  const next = useMemo(() => nextUpcoming(bookings), [bookings]);
  const lifetimeValue = useMemo(
    () =>
      bookings
        .filter((booking) => booking.status === 'completed')
        .reduce((sum, booking) => sum + booking.price, 0),
    [bookings],
  );

  const notify = (message: string) =>
    setToast({ id: Date.now(), message });

  const handleCreate = (draft: BookingDraft) => {
    const booking: Booking = {
      id: `BK-${2060 + bookings.length}`,
      service: draft.service,
      provider: 'Awaiting assignment',
      location: draft.notes || 'Location confirmed by email',
      start: toDateTime(draft.date, draft.time),
      durationMins: 60,
      status: 'pending',
      price: 0,
    };
    setBookings((current) => [booking, ...current]);
    setBookingOpen(false);
    setFilter('upcoming');
    notify(`“${draft.service}” requested — we’ll confirm shortly.`);
  };

  const handleCancel = (booking: Booking) => {
    setBookings((current) =>
      current.map((item) =>
        item.id === booking.id ? withStatus(item, 'cancelled') : item,
      ),
    );
    notify(`Cancelled “${booking.service}”.`);
  };

  const handleReschedule = (id: string, date: string, time: string) => {
    setBookings((current) =>
      current.map((item) =>
        item.id === id
          ? { ...item, start: toDateTime(date, time), status: 'pending' }
          : item,
      ),
    );
    setRescheduleTarget(null);
    setFilter('upcoming');
    notify('Appointment moved — the provider has been notified.');
  };

  const upcomingHint = next
    ? `Next: ${relativeDay(next.start)} · ${formatTime(next.start)}`
    : 'Nothing scheduled';

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <Header
        notificationCount={stats.upcoming}
        onOpenNotifications={() =>
          notify(`${stats.upcoming} appointments need your attention.`)
        }
      />

      <main className="mx-auto max-w-7xl space-y-6 px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
        {/* Page heading */}
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 className="text-xl font-bold tracking-tight text-slate-900 sm:text-2xl">
              Dashboard
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Here’s an overview of your bookings, {USER_NAME}.
            </p>
          </div>
          {next ? (
            <p className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-600 shadow-sm">
              <Clock className="h-3.5 w-3.5 text-indigo-500" />
              Next appointment · {relativeDay(next.start)}{' '}
              {formatTime(next.start)}
            </p>
          ) : null}
        </div>

        {/* Stats */}
        <div className="grid gap-4 sm:grid-cols-3">
          <StatCard
            label="Total bookings"
            value={stats.total}
            icon={CalendarCheck}
            hint={`${stats.cancelled} cancelled · all services`}
            badge={`${stats.total} total`}
          />
          <StatCard
            tone="highlight"
            label="Upcoming appointments"
            value={stats.upcoming}
            icon={CalendarClock}
            hint={upcomingHint}
            badge="Next up"
          />
          <StatCard
            label="Completed bookings"
            value={stats.completed}
            icon={CheckCircle2}
            hint={`${formatPrice(lifetimeValue)} lifetime spend`}
            badge={`${stats.completed} done`}
          />
        </div>

        {/* Quick actions */}
        <QuickActions
          onBook={() => setBookingOpen(true)}
          onChat={() => setChatOpen(true)}
          onSchedule={() => setScheduleOpen(true)}
        />

        {/* Appointments */}
        <Appointments
          bookings={bookings}
          filter={filter}
          onFilterChange={setFilter}
          onCancel={handleCancel}
          onReschedule={setRescheduleTarget}
          onBookAgain={(booking) => {
            setBookingOpen(true);
            notify(`Starting a new booking like “${booking.service}”.`);
          }}
        />

        <p className="pb-2 text-center text-xs text-slate-400">
          BookEase · demo data resets on refresh
        </p>
      </main>

      <BookingModal
        open={bookingOpen}
        onClose={() => setBookingOpen(false)}
        onSubmit={handleCreate}
      />
      <RescheduleModal
        booking={rescheduleTarget}
        onClose={() => setRescheduleTarget(null)}
        onSubmit={handleReschedule}
      />
      <ScheduleModal
        open={scheduleOpen}
        onClose={() => setScheduleOpen(false)}
        bookings={bookings}
      />
      <AiChatDrawer open={chatOpen} onClose={() => setChatOpen(false)} />

      {toast ? (
        <Toast
          key={toast.id}
          message={toast.message}
          onDismiss={() => setToast(null)}
        />
      ) : null}
    </div>
  );
}
