export type BookingStatus = 'confirmed' | 'pending' | 'completed' | 'cancelled';

export interface Booking {
  id: string;
  service: string;
  provider: string;
  location: string;
  /** When the appointment starts. */
  start: Date;
  durationMins: number;
  status: BookingStatus;
  price: number;
}

/** The three numbers shown in the summary cards. */
export interface BookingStats {
  total: number;
  upcoming: number;
  completed: number;
  cancelled: number;
}

export type AppointmentFilter = 'all' | 'upcoming' | 'completed';
