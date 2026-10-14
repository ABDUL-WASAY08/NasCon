import { Link, useSearchParams } from 'react-router-dom'
import { useAuth } from '../context/auth-context.js'
import RoleBadge from '../components/RoleBadge.jsx'
import UserAvatar from '../components/UserAvatar.jsx'
import CustomerDashboard from './dashboards/CustomerDashboard.jsx'
import ProviderDashboard from './dashboards/ProviderDashboard.jsx'
import ManagerDashboard from './dashboards/ManagerDashboard.jsx'
import AdminDashboard from './dashboards/AdminDashboard.jsx'

const DASHBOARDS = {
  customer: CustomerDashboard,
  provider: ProviderDashboard,
  manager: ManagerDashboard,
  admin: AdminDashboard,
}

export default function Console() {
  const { user, signOut } = useAuth()
  const [params] = useSearchParams()
  const denied = params.get('denied') === '1'
  const Dashboard = DASHBOARDS[user.role] || CustomerDashboard

  return (
    <section className="container py-10 pb-20 md:py-14">
      <div className="flex flex-col gap-8">
        {denied && (
          <p
            className="rounded-md border border-attention/35 bg-attention-soft px-5 py-4 text-[0.9rem] text-attention"
            role="alert"
          >
            That area needs a higher role than yours. You were redirected to your console.
          </p>
        )}

        <header className="flex flex-wrap items-start justify-between gap-5">
          <div className="flex items-center gap-4">
            <UserAvatar user={user} size={52} />
            <div>
              <span className="eyebrow eyebrow--live">Operations console</span>
              <h1 className="mt-0.5 text-[clamp(1.5rem,3vw,2rem)]">
                Welcome back, {user.name.split(' ')[0]}
              </h1>
              <div className="mt-2 flex flex-wrap items-center gap-3 text-[0.8rem] text-muted">
                <RoleBadge role={user.role} />
                <span className="mono">{user.email}</span>
                {user.organization && <span className="mono">· {user.organization}</span>}
              </div>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <button type="button" className="btn btn--ghost btn--sm" onClick={signOut}>
              Sign out
            </button>
          </div>
        </header>

        <Dashboard user={user} />

        <div className="flex flex-wrap items-center gap-3 border-t border-line pt-4 font-mono text-[0.72rem] text-faint">
          <span>Access is enforced on the API. Hiding a control here is not the security boundary.</span>
          <Link to="/about" className="text-live hover:underline">
            View architecture
          </Link>
        </div>
      </div>
    </section>
  )
}
