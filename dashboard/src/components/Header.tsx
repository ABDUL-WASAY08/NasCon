import { useEffect, useRef, useState } from 'react';
import {
  Bell,
  CalendarCheck,
  ChevronDown,
  LogOut,
  Settings,
  User,
  type LucideIcon,
} from 'lucide-react';

import { USER_EMAIL, USER_NAME } from '../lib/data';

const INITIALS = USER_NAME.slice(0, 2).toUpperCase();

function MenuItem({
  icon: Icon,
  label,
  tone = 'default',
  onClick,
}: {
  icon: LucideIcon;
  label: string;
  tone?: 'default' | 'danger';
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      role="menuitem"
      onClick={onClick}
      className={`flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-sm font-medium transition focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40 ${
        tone === 'danger'
          ? 'text-rose-600 hover:bg-rose-50'
          : 'text-slate-700 hover:bg-slate-100'
      }`}
    >
      <Icon className="h-4 w-4" />
      {label}
    </button>
  );
}

export function Header({
  notificationCount,
  onOpenNotifications,
}: {
  notificationCount: number;
  onOpenNotifications: () => void;
}) {
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Close the avatar menu on outside click or Escape.
  useEffect(() => {
    if (!menuOpen) return;
    const onPointerDown = (event: MouseEvent) => {
      if (!menuRef.current?.contains(event.target as Node)) setMenuOpen(false);
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setMenuOpen(false);
    };
    document.addEventListener('mousedown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [menuOpen]);

  return (
    <header className="sticky top-0 z-30 border-b border-slate-200/80 bg-white/85 backdrop-blur">
      <div className="mx-auto flex max-w-7xl items-center gap-3 px-4 py-3 sm:px-6 lg:px-8">
        {/* Brand + greeting */}
        <div className="flex min-w-0 items-center gap-3">
          <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-linear-to-br from-indigo-600 to-violet-600 text-white shadow-sm">
            <CalendarCheck className="h-5 w-5" />
          </span>
          <div className="min-w-0">
            <p className="truncate text-base font-bold leading-tight tracking-tight text-slate-900">
              BookEase
            </p>
            <p className="truncate text-xs leading-tight text-slate-500">
              Welcome back, {USER_NAME}! <span aria-hidden="true">👋</span>
            </p>
          </div>
        </div>

        <div className="ml-auto flex items-center gap-1.5 sm:gap-2">
          {/* Notifications */}
          <button
            type="button"
            onClick={onOpenNotifications}
            aria-label={`Notifications, ${notificationCount} unread`}
            className="relative rounded-xl p-2.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40"
          >
            <Bell className="h-5 w-5" />
            {notificationCount > 0 ? (
              <span className="absolute right-1.5 top-1.5 grid h-4 min-w-4 place-items-center rounded-full bg-rose-500 px-1 text-[10px] font-bold leading-none text-white ring-2 ring-white">
                {notificationCount}
              </span>
            ) : null}
          </button>

          {/* Profile */}
          <div className="relative" ref={menuRef}>
            <button
              type="button"
              onClick={() => setMenuOpen((open) => !open)}
              aria-haspopup="menu"
              aria-expanded={menuOpen}
              className="flex items-center gap-2 rounded-xl p-1 pr-2 transition hover:bg-slate-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/40"
            >
              <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-linear-to-br from-slate-700 to-slate-900 text-xs font-bold text-white">
                {INITIALS}
              </span>
              <span className="hidden text-left sm:block">
                <span className="block text-sm font-semibold leading-tight text-slate-800">
                  {USER_NAME}
                </span>
                <span className="block text-[11px] leading-tight text-slate-500">
                  Client
                </span>
              </span>
              <ChevronDown
                className={`hidden h-4 w-4 text-slate-400 transition-transform duration-200 sm:block ${
                  menuOpen ? 'rotate-180' : ''
                }`}
              />
            </button>

            {menuOpen ? (
              <div
                role="menu"
                className="animate-menu-in absolute right-0 top-full z-40 mt-2 w-60 overflow-hidden rounded-2xl border border-slate-200 bg-white p-1.5 shadow-xl"
              >
                <div className="px-3 py-2">
                  <p className="truncate text-sm font-semibold text-slate-900">
                    {USER_NAME}
                  </p>
                  <p className="truncate text-xs text-slate-500">{USER_EMAIL}</p>
                </div>
                <div className="my-1 h-px bg-slate-100" />
                <MenuItem
                  icon={User}
                  label="Your profile"
                  onClick={() => setMenuOpen(false)}
                />
                <MenuItem
                  icon={Settings}
                  label="Settings"
                  onClick={() => setMenuOpen(false)}
                />
                <div className="my-1 h-px bg-slate-100" />
                <MenuItem
                  icon={LogOut}
                  label="Sign out"
                  tone="danger"
                  onClick={() => setMenuOpen(false)}
                />
              </div>
            ) : null}
          </div>
        </div>
      </div>
    </header>
  );
}
