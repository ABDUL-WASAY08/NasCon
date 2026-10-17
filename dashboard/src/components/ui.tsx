import type { ButtonHTMLAttributes, ReactNode } from 'react';
import { X } from 'lucide-react';

import type { BookingStatus } from '../types';
import { STATUS_META } from '../lib/format';
import { useEscapeKey, useLockBodyScroll } from '../lib/hooks';

/* ── Button ───────────────────────────────────────────────────────────── */

export type ButtonVariant =
  | 'primary'
  | 'secondary'
  | 'outline'
  | 'ghost'
  | 'danger';

const BUTTON_VARIANTS: Record<ButtonVariant, string> = {
  primary:
    'bg-indigo-600 text-white shadow-sm hover:bg-indigo-700 focus-visible:ring-indigo-500/40',
  secondary:
    'bg-slate-900 text-white shadow-sm hover:bg-slate-800 focus-visible:ring-slate-900/30',
  outline:
    'bg-white text-slate-700 ring-1 ring-slate-200 hover:bg-slate-50 focus-visible:ring-indigo-500/30',
  ghost:
    'text-slate-600 hover:bg-slate-100 focus-visible:ring-slate-400/30',
  danger:
    'bg-white text-rose-600 ring-1 ring-rose-200 hover:bg-rose-50 focus-visible:ring-rose-500/30',
};

export function Button({
  variant = 'primary',
  className = '',
  type = 'button',
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: ButtonVariant }) {
  return (
    <button
      type={type}
      className={`inline-flex items-center justify-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold transition focus:outline-none focus-visible:ring-2 disabled:cursor-not-allowed disabled:opacity-50 ${BUTTON_VARIANTS[variant]} ${className}`}
      {...rest}
    />
  );
}

/* ── Status badge ─────────────────────────────────────────────────────── */

export function StatusBadge({ status }: { status: BookingStatus }) {
  const meta = STATUS_META[status];
  return (
    <span
      className={`inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-medium ${meta.pill}`}
    >
      <span
        className={`h-1.5 w-1.5 rounded-full ${meta.dot}`}
        aria-hidden="true"
      />
      {meta.label}
    </span>
  );
}

/* ── Panel ────────────────────────────────────────────────────────────── */

export function Panel({
  className = '',
  children,
}: {
  className?: string;
  children: ReactNode;
}) {
  return (
    <section
      className={`rounded-2xl border border-slate-200/80 bg-white shadow-sm ${className}`}
    >
      {children}
    </section>
  );
}

/* ── Modal ────────────────────────────────────────────────────────────── */

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  footer?: ReactNode;
}

/**
 * Centred dialog on desktop, bottom sheet on mobile — one component, one
 * entrance animation that suits both.
 */
export function Modal({
  open,
  onClose,
  title,
  description,
  children,
  footer,
}: ModalProps) {
  useLockBodyScroll(open);
  useEscapeKey(open, onClose);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center sm:p-4">
      <div
        className="animate-overlay-in absolute inset-0 bg-slate-900/50 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className="animate-panel-in relative flex max-h-[92vh] w-full flex-col overflow-hidden rounded-t-3xl bg-white shadow-xl sm:max-w-lg sm:rounded-2xl"
      >
        <header className="flex items-start justify-between gap-4 border-b border-slate-100 px-6 py-5">
          <div className="min-w-0">
            <h2 className="text-lg font-semibold tracking-tight text-slate-900">
              {title}
            </h2>
            {description ? (
              <p className="mt-1 text-sm text-slate-500">{description}</p>
            ) : null}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="-mr-1 shrink-0 rounded-lg p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40"
          >
            <X className="h-5 w-5" />
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto px-6 py-5">
          {children}
        </div>

        {footer ? (
          <footer className="flex flex-wrap justify-end gap-3 border-t border-slate-100 bg-slate-50/70 px-6 py-4">
            {footer}
          </footer>
        ) : null}
      </div>
    </div>
  );
}

/* ── Drawer ───────────────────────────────────────────────────────────── */

interface DrawerProps {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  headerIcon?: ReactNode;
  children: ReactNode;
  footer?: ReactNode;
}

/** Right-hand panel, full width on phones. */
export function Drawer({
  open,
  onClose,
  title,
  subtitle,
  headerIcon,
  children,
  footer,
}: DrawerProps) {
  useLockBodyScroll(open);
  useEscapeKey(open, onClose);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50">
      <div
        className="animate-overlay-in absolute inset-0 bg-slate-900/50 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className="animate-drawer-in absolute right-0 top-0 flex h-full w-full flex-col bg-white shadow-xl sm:max-w-md"
      >
        <header className="flex items-center gap-3 border-b border-slate-100 px-5 py-4">
          {headerIcon}
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-base font-semibold tracking-tight text-slate-900">
              {title}
            </h2>
            {subtitle ? (
              <p className="truncate text-xs text-slate-500">{subtitle}</p>
            ) : null}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close"
            className="shrink-0 rounded-lg p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40"
          >
            <X className="h-5 w-5" />
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto">{children}</div>

        {footer ? (
          <footer className="border-t border-slate-100 bg-white px-5 py-4">
            {footer}
          </footer>
        ) : null}
      </div>
    </div>
  );
}

/* ── Toast ────────────────────────────────────────────────────────────── */

export function Toast({
  message,
  tone = 'success',
  onDismiss,
}: {
  message: string;
  tone?: 'success' | 'info';
  onDismiss: () => void;
}) {
  const accent =
    tone === 'success'
      ? 'border-emerald-200 bg-emerald-50 text-emerald-800'
      : 'border-indigo-200 bg-indigo-50 text-indigo-800';

  return (
    <div
      role="status"
      className="animate-panel-in pointer-events-auto fixed bottom-4 left-4 right-4 z-[60] sm:left-auto sm:right-6 sm:w-80"
    >
      <div
        className={`flex items-start gap-3 rounded-2xl border px-4 py-3 text-sm font-medium shadow-lg ${accent}`}
      >
        <span className="min-w-0 flex-1">{message}</span>
        <button
          type="button"
          onClick={onDismiss}
          aria-label="Dismiss notification"
          className="shrink-0 rounded-md p-0.5 transition hover:bg-black/5 focus:outline-none focus-visible:ring-2 focus-visible:ring-current"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
