import { useEffect, useState } from 'react'
import { api } from '../../lib/api-client.js'
import { useAuth } from '../../context/auth-context.js'
import { ROLE_LABEL } from '../../lib/roles.js'
import RouteLoader from '../../components/RouteLoader.jsx'
import StatCard from '../../components/StatCard.jsx'

const fmtDate = (value) =>
  value ? new Date(value).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' }) : '—'

const fmtDateTime = (value) =>
  value
    ? new Date(value).toLocaleString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      })
    : '—'

const MODULES = [
  'Service catalog & booking',
  'AI booking assistant',
  'Booking-linked chat',
  'Weekly WhatsApp report',
]

export default function CustomerDashboard({ user }) {
  const { capabilities } = useAuth()
  const [summary, setSummary] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    api
      .dashboard()
      .then((data) => active && setSummary(data.summary))
      .catch((err) => active && setError(err.message))
    return () => {
      active = false
    }
  }, [])

  if (!summary) {
    return error ? (
      <p className="rounded-md border border-danger/40 bg-danger-soft px-5 py-4 text-[0.9rem] text-danger">
        {error}
      </p>
    ) : (
      <RouteLoader label="Loading your console" />
    )
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Signed in as" value={ROLE_LABEL[user.role]} foot={user.email} small />
        <StatCard label="Member since" value={fmtDate(summary.session.memberSince)} foot="Account created" small />
        <StatCard label="Last sign-in" value={fmtDateTime(summary.session.lastLoginAt)} foot="Tracked per session" small />
        <StatCard
          label="Sign-in method"
          value={summary.session.provider === 'google' ? 'Google' : 'Email & password'}
          foot={summary.session.emailVerified ? 'Email verified' : 'Email not verified'}
          small
        />
      </div>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.15fr)]">
        <section className="panel flex flex-col gap-4 p-6">
          <h2 className="text-[1.08rem]">Profile</h2>
          <dl className="kv">
            <div><dt className="mono">Name</dt><dd>{user.name}</dd></div>
            <div><dt className="mono">Email</dt><dd>{user.email}</dd></div>
            <div><dt className="mono">Role</dt><dd>{ROLE_LABEL[user.role]}</dd></div>
            <div><dt className="mono">Organization</dt><dd>{user.organization || '—'}</dd></div>
          </dl>
        </section>

        <section className="panel flex flex-col gap-4 p-6">
          <h2 className="text-[1.08rem]">Role permissions</h2>
          <p className="text-[0.82rem] text-muted">
            Granted by the server for the <strong className="text-ink">{ROLE_LABEL[user.role]}</strong> role.
          </p>
          <ul className="flex flex-wrap gap-2">
            {capabilities.map((cap) => (
              <li
                key={cap}
                className="mono rounded-pill border border-line bg-inset px-2.5 py-1 text-[0.72rem] text-muted"
              >
                {cap}
              </li>
            ))}
          </ul>
        </section>

        <section className="panel flex flex-col gap-4 p-6 lg:col-span-2">
          <h2 className="text-[1.08rem]">Your workspace</h2>
          <p className="text-[0.82rem] text-muted">
            Booking, chat and reporting modules are the next build phase. Your console will light up
            as each service lands.
          </p>
          <ul className="flex flex-col">
            {MODULES.map((item) => (
              <li
                key={item}
                className="grid grid-cols-[10px_1fr_auto] items-center gap-3 border-t border-line py-3 text-[0.9rem] first:border-t-0"
              >
                <span className="h-[7px] w-[7px] rounded-full bg-faint" aria-hidden="true" />
                <span>{item}</span>
                <span className="chip">planned</span>
              </li>
            ))}
          </ul>
        </section>
      </div>
    </div>
  )
}
