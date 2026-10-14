import { useEffect, useState } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import Logo from './Logo.jsx'
import { useAuth } from '../context/auth-context.js'
import { homeForRole } from '../lib/roles.js'

const BASE_NAV = [
  { to: '/', label: 'Home', end: true },
  { to: '/#platform', label: 'Platform' },
  { to: '/#workflow', label: 'Workflow' },
  { to: '/about', label: 'About' },
]

export default function SiteHeader() {
  const [open, setOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)
  const { status, user, signOut } = useAuth()
  const navigate = useNavigate()

  const authed = status === 'authed'
  const consolePath = authed ? homeForRole(user.role) : '/console'
  const nav = authed
    ? [...BASE_NAV, { to: consolePath, label: user.role === 'admin' ? 'Admin console' : 'Console' }]
    : BASE_NAV

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    if (!open) return undefined
    const onKey = (event) => {
      if (event.key === 'Escape') setOpen(false)
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [open])

  const handleSignOut = async () => {
    setOpen(false)
    await signOut()
    navigate('/')
  }

  const linkClass = ({ isActive }) =>
    `rounded-sm px-3 py-2 text-[0.9rem] font-medium transition-colors hover:bg-surface-2 hover:text-ink ${
      isActive ? 'text-ink' : 'text-muted'
    }`

  return (
    <header
      className={`sticky top-0 z-50 border-b transition-colors ${
        scrolled
          ? 'border-line bg-canvas/80 backdrop-blur-md'
          : 'border-transparent bg-transparent'
      }`}
    >
      <div className="container flex h-[68px] items-center gap-6">
        <Link to="/" className="inline-flex items-center rounded-sm" aria-label="NEXUS home">
          <Logo />
        </Link>

        <nav className="hidden lg:flex items-center gap-1 lg:ms-6" aria-label="Primary">
          {nav.map((item) =>
            item.to.includes('#') ? (
              <Link key={item.label} to={item.to} className="rounded-sm px-3 py-2 text-[0.9rem] font-medium text-muted transition-colors hover:bg-surface-2 hover:text-ink">
                {item.label}
              </Link>
            ) : (
              <NavLink key={item.label} to={item.to} end={item.end} className={linkClass}>
                {item.label}
              </NavLink>
            ),
          )}
        </nav>

        <div className="ms-auto hidden lg:flex items-center gap-3">
          {authed ? (
            <>
              <Link
                to={consolePath}
                className="inline-flex items-center gap-2 rounded-pill border border-line bg-surface-1 py-[5px] pe-3 ps-[5px] transition-colors hover:border-live-line hover:bg-surface-2"
                aria-label="Open your console"
              >
                <span className="grid h-7 w-7 place-items-center rounded-full bg-surface-3 font-mono text-[0.7rem] font-medium text-live">
                  {user.initials || user.name.slice(0, 2).toUpperCase()}
                </span>
                <span className="text-[0.86rem] font-semibold">{user.name.split(' ')[0]}</span>
              </Link>
              <button type="button" className="btn btn--ghost btn--sm" onClick={handleSignOut}>
                Sign out
              </button>
            </>
          ) : (
            <>
              <Link to="/auth" className="px-1 py-2 text-[0.9rem] font-medium text-muted transition-colors hover:text-ink">
                Sign in
              </Link>
              <Link to="/auth?mode=signup" className="btn btn--primary btn--sm">
                Open console
              </Link>
            </>
          )}
        </div>

        <button
          type="button"
          className="ms-auto inline-flex h-11 w-11 items-center justify-center rounded-sm border border-line-strong bg-surface-1 lg:hidden"
          aria-expanded={open}
          aria-controls="mobile-nav"
          onClick={() => setOpen((value) => !value)}
        >
          <span className="sr-only">{open ? 'Close menu' : 'Open menu'}</span>
          <span className="flex w-[18px] flex-col gap-[5px]" aria-hidden="true">
            <i
              className={`block h-0.5 rounded bg-ink transition-transform ${
                open ? 'translate-y-1 rotate-45' : ''
              }`}
            />
            <i
              className={`block h-0.5 rounded bg-ink transition-transform ${
                open ? '-translate-y-1 -rotate-45' : ''
              }`}
            />
          </span>
        </button>
      </div>

      {open && (
        <div id="mobile-nav" className="border-t border-line bg-canvas/95 backdrop-blur-md lg:hidden">
          <nav className="container flex flex-col py-4" aria-label="Mobile">
            {nav.map((item) => (
              <Link
                key={item.label}
                to={item.to}
                className="border-b border-line py-3.5 text-[1.05rem] font-medium text-ink"
                onClick={() => setOpen(false)}
              >
                {item.label}
              </Link>
            ))}
          </nav>
          <div className="container mt-5 flex flex-col gap-3 pb-6">
            {authed ? (
              <>
                <Link to={consolePath} className="btn btn--ghost btn--block" onClick={() => setOpen(false)}>
                  {user.role === 'admin' ? 'Admin console' : 'Open console'}
                </Link>
                <button type="button" className="btn btn--primary btn--block" onClick={handleSignOut}>
                  Sign out
                </button>
              </>
            ) : (
              <>
                <Link to="/auth" className="btn btn--ghost btn--block" onClick={() => setOpen(false)}>
                  Sign in
                </Link>
                <Link
                  to="/auth?mode=signup"
                  className="btn btn--primary btn--block"
                  onClick={() => setOpen(false)}
                >
                  Open console
                </Link>
              </>
            )}
          </div>
        </div>
      )}
    </header>
  )
}
