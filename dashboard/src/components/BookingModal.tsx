import { useEffect, useState, type FormEvent } from 'react';

import { SERVICE_OPTIONS } from '../lib/data';
import { inputClass, labelClass } from '../lib/styles';
import { Button, Modal } from './ui';

export interface BookingDraft {
  service: string;
  date: string;
  time: string;
  notes: string;
}

/** Today as a `yyyy-mm-dd` value, in local time. */
const todayValue = (): string => {
  const today = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${today.getFullYear()}-${pad(today.getMonth() + 1)}-${pad(today.getDate())}`;
};

interface BookingModalProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (draft: BookingDraft) => void;
}

export function BookingModal({ open, onClose, onSubmit }: BookingModalProps) {
  const [service, setService] = useState<string>(SERVICE_OPTIONS[0]);
  const [date, setDate] = useState('');
  const [time, setTime] = useState('10:00');
  const [notes, setNotes] = useState('');
  const [error, setError] = useState('');

  // Reset the form each time it is opened.
  useEffect(() => {
    if (!open) return;
    setService(SERVICE_OPTIONS[0]);
    setDate(todayValue());
    setTime('10:00');
    setNotes('');
    setError('');
  }, [open]);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!date || !time) {
      setError('Choose a date and a time for your appointment.');
      return;
    }
    onSubmit({ service, date, time, notes: notes.trim() });
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Book a new service"
      description="Pick a service and a slot — we will confirm it shortly."
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" form="booking-form">
            Confirm booking
          </Button>
        </>
      }
    >
      <form id="booking-form" onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className={labelClass} htmlFor="booking-service">
            Service
          </label>
          <select
            id="booking-service"
            className={inputClass}
            value={service}
            onChange={(event) => setService(event.target.value)}
          >
            {SERVICE_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className={labelClass} htmlFor="booking-date">
              Date
            </label>
            <input
              id="booking-date"
              type="date"
              className={inputClass}
              value={date}
              min={todayValue()}
              onChange={(event) => setDate(event.target.value)}
            />
          </div>
          <div>
            <label className={labelClass} htmlFor="booking-time">
              Time
            </label>
            <input
              id="booking-time"
              type="time"
              className={inputClass}
              value={time}
              onChange={(event) => setTime(event.target.value)}
            />
          </div>
        </div>

        <div>
          <label className={labelClass} htmlFor="booking-notes">
            Notes <span className="font-normal text-slate-400">(optional)</span>
          </label>
          <textarea
            id="booking-notes"
            rows={3}
            className={`${inputClass} resize-none`}
            placeholder="Anything the provider should know?"
            value={notes}
            onChange={(event) => setNotes(event.target.value)}
          />
        </div>

        {error ? (
          <p
            role="alert"
            className="rounded-xl bg-rose-50 px-3.5 py-2.5 text-sm font-medium text-rose-700 ring-1 ring-rose-200"
          >
            {error}
          </p>
        ) : null}
      </form>
    </Modal>
  );
}
