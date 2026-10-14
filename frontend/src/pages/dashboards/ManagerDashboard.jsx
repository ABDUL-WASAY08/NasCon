import { useCallback, useEffect, useState } from 'react'
import { api } from '../../lib/api-client.js'
import RouteLoader from '../../components/RouteLoader.jsx'
import StatCard from '../../components/StatCard.jsx'
import UserDirectory from '../../components/UserDirectory.jsx'

export default function ManagerDashboard({ user }) {
  const [summary, setSummary] = useState(null)
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const load = useCallback(async () => {
    try {
      const [dash, list] = await Promise.all([api.dashboard(), api.users()])
      setSummary(dash.summary)
      setUsers(list.users)
      setError('')
    } catch (err) {
      setError(err.message || 'Could not load the console.')
    }
  }, [])

  useEffect(() => {
    let active = true
    ;(async () => {
      await load()
      if (active) setLoading(false)
    })()
    return () => {
      active = false
    }
  }, [load])

  const reload = async () => {
    setLoading(true)
    await load()
    setLoading(false)
  }

  if (loading) return <RouteLoader label="Loading your console" />

  const stats = summary?.stats

  return (
    <div className="flex flex-col gap-5">
      {error && (
        <p className="rounded-md border border-danger/40 bg-danger-soft px-5 py-4 text-[0.9rem] text-danger" role="alert">
          {error}
        </p>
      )}

      <div className="flex flex-wrap items-center justify-between gap-3">
        <span className="eyebrow">Operations overview</span>
        <button type="button" className="btn btn--ghost btn--sm" onClick={reload}>
          Reload console
        </button>
      </div>

      {stats && (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard label="Total users" value={stats.totalUsers} foot="Across the whole platform" />
          <StatCard label="Verified" value={stats.verifiedUsers} foot="Email-confirmed accounts" />
          <StatCard
            label="Staff & leads"
            value={(stats.byRole.provider || 0) + (stats.byRole.manager || 0)}
            foot={`${stats.byRole.provider || 0} providers · ${stats.byRole.manager || 0} managers`}
          />
          <StatCard
            label="Customers"
            value={stats.byRole.customer || 0}
            foot={`${stats.byRole.admin || 0} administrators`}
          />
        </div>
      )}

      <UserDirectory users={users} currentUserId={user.id} canEditRoles={false} />
    </div>
  )
}
