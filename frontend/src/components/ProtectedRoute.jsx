import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/auth-context.js'
import { atLeast } from '../lib/roles.js'
import RouteLoader from './RouteLoader.jsx'

/**
 * Client-side gate for protected console routes. The API enforces the same
 * rules server-side; this only decides what the browser should render.
 *
 * - `roles`    exact role match (e.g. admin-only)
 * - `minRole`  minimum role rank (e.g. manager and above)
 */
export default function ProtectedRoute({ children, roles, minRole }) {
  const { status, user } = useAuth()
  const location = useLocation()

  if (status === 'loading') return <RouteLoader />

  if (status !== 'authed') {
    const next = encodeURIComponent(location.pathname + location.search)
    return <Navigate to={`/auth?next=${next}`} replace />
  }

  if (roles && !roles.includes(user.role)) {
    return <Navigate to="/console?denied=1" replace />
  }

  if (minRole && !atLeast(user.role, minRole)) {
    return <Navigate to="/console?denied=1" replace />
  }

  return children
}
