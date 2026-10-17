import type { Booking, BookingStats } from '../types';

export const USER_NAME = 'Abdul';
export const USER_EMAIL = 'abdul@bookease.app';

/** Local date `dayOffset` days from today, set to the given time. */
const at = (dayOffset: number, hour: number, minute = 0): Date => {
  const date = new Date();
  date.setHours(hour, minute, 0, 0);
  date.setDate(date.getDate() + dayOffset);
  return date;
};

/** Service catalogue used by the booking form. */
export const SERVICE_OPTIONS = [
  'Dental Checkup',
  'Car Service & Inspection',
  'Deep Tissue Massage',
  'Haircut & Styling',
  'Home Cleaning',
  'Physiotherapy Session',
  'Personal Training',
  'Photography Session',
  'Annual Health Screening',
  'Tax Consultation',
] as const;

/**
 * Seed data: 12 bookings in total — 3 upcoming and 9 completed — so the
 * summary cards read 12 / 3 / 9 out of the box.
 */
export const seedBookings = (): Booking[] => [
  // ── Upcoming ───────────────────────────────────────────────────────────
  {
    id: 'BK-2041',
    service: 'Dental Checkup',
    provider: 'Dr. Ayesha Khan',
    location: 'Smile Studio · Downtown',
    start: at(0, 15, 30),
    durationMins: 45,
    status: 'confirmed',
    price: 60,
  },
  {
    id: 'BK-2042',
    service: 'Car Service & Inspection',
    provider: 'Prime Auto Care',
    location: 'Prime Auto · Industrial Area',
    start: at(2, 9, 0),
    durationMins: 120,
    status: 'confirmed',
    price: 180,
  },
  {
    id: 'BK-2043',
    service: 'Deep Tissue Massage',
    provider: 'Serenity Spa',
    location: 'Serenity · Riverside',
    start: at(4, 18, 0),
    durationMins: 60,
    status: 'pending',
    price: 85,
  },

  // ── Completed ──────────────────────────────────────────────────────────
  {
    id: 'BK-2039',
    service: 'Haircut & Styling',
    provider: 'The Gentlemen’s Room',
    location: 'The Gentlemen’s Room · Mall Road',
    start: at(-3, 11, 0),
    durationMins: 45,
    status: 'completed',
    price: 35,
  },
  {
    id: 'BK-2036',
    service: 'Home Cleaning',
    provider: 'FreshNest Services',
    location: 'At your address',
    start: at(-6, 10, 0),
    durationMins: 180,
    status: 'completed',
    price: 120,
  },
  {
    id: 'BK-2033',
    service: 'Physiotherapy Session',
    provider: 'Dr. Bilal Ahmed',
    location: 'City Rehab Centre',
    start: at(-9, 16, 30),
    durationMins: 60,
    status: 'completed',
    price: 70,
  },
  {
    id: 'BK-2030',
    service: 'Annual Health Screening',
    provider: 'MediCare Labs',
    location: 'MediCare Labs · Block C',
    start: at(-13, 8, 30),
    durationMins: 90,
    status: 'completed',
    price: 145,
  },
  {
    id: 'BK-2027',
    service: 'Tax Consultation',
    provider: 'Hartley & Co.',
    location: 'Hartley & Co. · Business Bay',
    start: at(-17, 14, 0),
    durationMins: 60,
    status: 'completed',
    price: 95,
  },
  {
    id: 'BK-2024',
    service: 'Personal Training',
    provider: 'Coach Hamza',
    location: 'Iron House Gym',
    start: at(-21, 7, 0),
    durationMins: 60,
    status: 'completed',
    price: 40,
  },
  {
    id: 'BK-2021',
    service: 'Photography Session',
    provider: 'Studio Lumen',
    location: 'Studio Lumen · Old Town',
    start: at(-26, 17, 0),
    durationMins: 120,
    status: 'completed',
    price: 250,
  },
  {
    id: 'BK-2018',
    service: 'Dental Cleaning',
    provider: 'Dr. Ayesha Khan',
    location: 'Smile Studio · Downtown',
    start: at(-33, 12, 0),
    durationMins: 30,
    status: 'completed',
    price: 45,
  },
  {
    id: 'BK-2015',
    service: 'Car Brake Replacement',
    provider: 'Prime Auto Care',
    location: 'Prime Auto · Industrial Area',
    start: at(-41, 9, 30),
    durationMins: 150,
    status: 'completed',
    price: 210,
  },
];

export const computeStats = (bookings: Booking[]): BookingStats => ({
  total: bookings.length,
  upcoming: bookings.filter(
    (b) => b.status === 'confirmed' || b.status === 'pending',
  ).length,
  completed: bookings.filter((b) => b.status === 'completed').length,
  cancelled: bookings.filter((b) => b.status === 'cancelled').length,
});

/** The soonest upcoming appointment, if there is one. */
export const nextUpcoming = (bookings: Booking[]): Booking | undefined =>
  bookings
    .filter((b) => b.status === 'confirmed' || b.status === 'pending')
    .sort((a, b) => a.start.getTime() - b.start.getTime())[0];
