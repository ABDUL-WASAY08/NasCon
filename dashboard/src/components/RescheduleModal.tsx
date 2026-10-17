import { useEffect, useState, type FormEvent } from 'react';

import type { Booking } from '../types';
import { formatDateTime } from '../lib/format';
import { inputClass, labelClass } from '../lib/styles';
import { Button, Modal } from './ui';

interface RescheduleModalProps {
  booking: Booking | null;
  onClose: () => void;
  onSubmit: (id: string, date: string, time: string) => void;
}

const pad = (n: number) => String(n).padStart(2, '0');
const dateValue = (d: Date) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const timeValue = (d: Date) => `${pad(d.getHours())}:${pad(d.getMinutes())}`;

export function RescheduleModal({
  booking,
  onClose,
  onSubmit,
}: RescheduleModalProps) {
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (!booking) return;
    setDate(dateValue(booking.start));
    setTime(timeValue(booking.start));
    setError('');
  }, [booking]);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!booking) return;
    if (!date || !time) {
      setError('Choose a new date and time.');
      return;
    }
    onSubmit(booking.id, date, time);
  };

  return (
    <Modal
      open={booking !== null}
      onClose={onClose}
      title="Reschedule appointment"
      description={
        booking
          ? `${booking.service} — currently ${formatDateTime(booking.start)}`
          : undefined
      }
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Keep as is
          </Button>
          <Button type="submit" form="reschedule-form">
            Save new time
          </Button>
        </>
      }
    >
      <form id="reschedule-form" onSubmit={handleSubmit} className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className={labelClass} htmlFor="reschedule-date">
              New date
            </label>
            <input
              id="reschedule-date"
              type="date"
              className={inputClass}
              value={date}
              onChange={(event) => setDate(event.target.value)}
            />
          </div>
          <div>
            <label className={labelClass} htmlFor="reschedule-time">
              New time
            </label>
            <input
              id="reschedule-time"
              type="time"
              className={inputClass}
              value={time}
              onChange={(event) => setTime(event.target.value)}
            />
          </div>
        </div>

        {error ? (
          <p
            role="alert"
            className="rounded-xl bg-rose-50 px-3.5 py-2.5 text-sm font-medium text-rose-700 ring-1 ring-rose-200"
          >
            {error}
          </p>
        ) : null}

        <p className="rounded-xl bg-slate-50 px-3.5 py-3 text-xs text-slate-500 ring-1 ring-slate-100">
          The provider will be notified of the change. Free rescheduling up to
          24 hours before the appointment.
        </p>
      </form>
    </Modal>
  );
}
