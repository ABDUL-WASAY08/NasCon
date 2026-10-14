import { useCallback, useEffect, useState } from 'react'
import { api } from '../../lib/api-client.js'
import { ROLE_LABEL } from '../../lib/roles.js'
import RouteLoader from '../../components/RouteLoader.jsx'
import StatCard from '../../components/StatCard.jsx'
import UserDirectory from '../../components/UserDirectory.jsx'

const fmtUptime = (seconds) => {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return `${h}h ${m}m`
}

export default function AdminDashboard({ user }) {
  const [overview, setOverview] = useState(null)
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [busyId, setBusyId] = useState(null)

  const load = useCallback(async () => {
    try {
      const [admin, list] = await Promise.all([api.adminOverview(), api.users()])
      setOverview(admin.overview)
      setUsers(list.users)
      setError('')
    } catch (err) {
      setError(err.message || 'Could not load the admin console.')
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

  const changeRole = async (target, role) => {
    setBusyId(target.id)
    setNotice('')
    const previous = users
    setUsers((list) => list.map((item) => (item.id === target.id ? { ...item, role } : item)))
    try {
      const updated = await api.updateRole(target.id, role)
      setUsers((list) => list.map((item) => (item.id === target.id ? updated.user : item)))
      setNotice(`${target.name} is now ${ROLE_LABEL[role]}.`)
      await load()
    } catch (err) {
      setUsers(previous)
      setNotice(err.message || 'Role update failed.')
    } finally {
      setBusyId(null)
    }
  }

  if (loading) return <RouteLoader label="Loading the admin console" />

  if (error) {
    return (
      <p className="rounded-md border border-danger/40 bg-danger-soft px-5 py-4 text-[0.9rem] text-danger" role="alert">
        {error}
      </p>
    )
  }

  const { platform, stats, admins, roleCapabilities } = overview

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <span className="eyebrow eyebrow--live">Administrator console</span>
        <div className="flex flex-wrap gap-2">
          <span className="chip chip--attention">Google-only access</span>
          <button type="button" className="btn btn--ghost btn--sm" onClick={load}>
            Reload
          </button>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Total users" value={stats.totalUsers} foot="Across the platform" />
        <StatCard label="Verified" value={stats.verifiedUsers} foot="Email-confirmed accounts" />
        <StatCard label="Google accounts" value={stats.googleUsers} foot="Signed in with Google" />
        <StatCard label="Administrators" value={stats.byRole.admin || 0} foot="Full platform access" />
      </div>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
        <section className="panel flex flex-col gap-4 p-6">
          <h2 className="text-[1.08rem]">Platform</h2>
          <dl className="kv">
            <div><dt className="mono">Name</dt><dd>{platform.name}</dd></div>
            <div><dt className="mono">API</dt><dd className="mono">{platform.api}</dd></div>
            <div><dt className="mono">Environment</dt><dd className="mono">{platform.environment}</dd></div>
            <div><dt className="mono">Database</dt><dd className="mono">{platform.database}</dd></div>
            <div><dt className="mono">Uptime</dt><dd className="mono">{fmtUptime(platform.uptimeSeconds)}</dd></div>
          </dl>
        </section>

        <section className="panel flex flex-col gap-4 p-6">
          <h2 className="text-[1.08rem]">Whitelisted administrators</h2>
          <p className="text-[0.82rem] text-muted">
            These emails are promoted to the administrator role on Google sign-in and cannot use a
            password.
          </p>
          <ul className="flex flex-col">
            {admins.map((email) => (
              <li key={email} className="border-t border-line py-3 font-mono text-[0.82rem] first:border-t-0">
                {email}
              </li>
            ))}
          </ul>
        </section>
      </div>

      <UserDirectory
        users={users}
        currentUserId={user.id}
        canEditRoles
        busyId={busyId}
        onChangeRole={changeRole}
        notice={notice}
      />

      <section className="panel flex flex-col gap-4 p-6">
        <h2 className="text-[1.08rem]">Role capabilities</h2>
        <p className="text-[0.82rem] text-muted">
          The capability contract the API enforces for each role, highest included.
        </p>
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {Object.entries(roleCapabilities).map(([role, caps]) => (
            <div key={role} className="rounded-md border border-line bg-inset p-4">
              <span className="mono text-[0.72rem] uppercase tracking-[0.08em] text-live">{role}</span>
              <ul className="mt-3 flex flex-col gap-2">
                {caps.map((cap) => (
                  <li key={cap} className="mono text-[0.72rem] text-muted">
                    {cap}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
