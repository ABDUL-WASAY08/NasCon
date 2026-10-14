import { Link } from 'react-router-dom'
import Logo from './Logo.jsx'

const COLUMNS = [
  {
    title: 'Platform',
    links: [
      { label: 'Modules', to: '/#modules' },
      { label: 'Workflow', to: '/#workflow' },
      { label: 'Reports', to: '/#reports' },
      { label: 'Live console', to: '/#platform' },
    ],
  },
  {
    title: 'System',
    links: [
      { label: 'Architecture', to: '/about#architecture' },
      { label: 'Services', to: '/about#services' },
      { label: 'Security', to: '/about#security' },
      { label: 'Roadmap', to: '/about#roadmap' },
    ],
  },
  {
    title: 'Access',
    links: [
      { label: 'Sign in', to: '/auth' },
      { label: 'Create account', to: '/auth?mode=signup' },
      { label: 'About NEXUS', to: '/about' },
    ],
  },
]

export default function SiteFooter() {
  return (
    <footer className="mt-auto border-t border-line bg-gradient-to-b from-transparent to-surface-1/70 pt-16">
      <div className="container grid gap-16 pb-16 md:grid-cols-[minmax(0,1.4fr)_minmax(0,2fr)]">
        <div className="flex max-w-[34ch] flex-col gap-4">
          <Logo />
          <p className="text-[0.92rem] leading-relaxed text-muted">
            AI-powered service operations. Booking, staff coordination, live chat, automated
            reporting and analytics in one system.
          </p>
          <span className="chip chip--live self-start">
            <span className="dot dot--pulse" aria-hidden="true" />
            Live operations online
          </span>
        </div>

        <div className="grid grid-cols-2 gap-6 sm:grid-cols-3">
          {COLUMNS.map((column) => (
            <div key={column.title}>
              <h2 className="mb-4 font-mono text-[0.72rem] font-medium uppercase tracking-[0.14em] text-faint">
                {column.title}
              </h2>
              <ul className="flex flex-col gap-3">
                {column.links.map((link) => (
                  <li key={link.label}>
                    <Link
                      to={link.to}
                      className="text-[0.92rem] text-muted transition-colors hover:text-live"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>

      <div className="container flex flex-wrap justify-between gap-4 border-t border-line py-6 text-faint">
        <p className="mono">© {new Date().getFullYear()} NEXUS platform</p>
        <p className="mono">React · Node.js · MongoDB · Redis · Nginx · Socket.IO</p>
      </div>
    </footer>
  )
}
