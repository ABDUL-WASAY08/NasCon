import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Logo from '../components/Logo.jsx'
import RouteLoader from '../components/RouteLoader.jsx'
import { useAuth } from '../context/auth-context.js'
import { homeForRole } from '../lib/roles.js'

const REASONS = {
  access_denied:
    'Google blocked this sign-in. If your OAuth consent screen is still in "Testing", add your Google account as a test user in Google Cloud Console, or publish the app.',
  redirect_uri_mismatch:
    'The redirect URI does not match Google Cloud Console. It must be exactly http://localhost:5000/auth/google/callback.',
  invalid_client:
    'Google rejected the client credentials (invalid_client). Check GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in backend/.env.',
  invalid_grant:
    'The Google authorization code was rejected (invalid_grant). This usually means the callback URL or client secret changed. Try again.',
  not_configured: 'Google OAuth is not configured on the server (missing client ID or secret).',
  db_unavailable:
    'Google signed you in, but the server could not reach MongoDB to load your account. Add this machine\u2019s public IP to Network Access in your MongoDB Atlas cluster, then try again.',
  session_failed: 'Signed in with Google, but the server could not start a session.',
  no_user: 'Google returned no account details.',
}

export default function AuthCallback() {
  const [params] = useSearchParams()
  const status = params.get('status')
  const reason = params.get('reason')
  const next = params.get('next')
  const { refresh } = useAuth()
  const navigate = useNavigate()
  const started = useRef(false)

  const [error, setError] = useState(() => {
    if (status !== 'error') return ''
    return REASONS[reason] || `Google sign-in failed${reason ? ` (${reason})` : ''}.`
  })

  useEffect(() => {
    if (status === 'error' || started.current) return
    started.current = true
    refresh().then((session) => {
      if (session) navigate(next || homeForRole(session.user.role), { replace: true })
      else setError('We could not establish a session. Please try again.')
    })
  }, [status, refresh, navigate, next])

  return (
    <div className="flex min-h-svh flex-col items-center justify-center gap-8 p-6">
      <Link to="/" aria-label="NEXUS home">
        <Logo />
      </Link>

      <div className="panel flex w-full max-w-[440px] flex-col gap-4 p-8">
        {error ? (
          <>
            <span className="eyebrow">Sign-in failed</span>
            <h1 className="text-[clamp(1.5rem,3vw,1.9rem)]">We couldn&apos;t sign you in</h1>
            <p className="lede">{error}</p>
            {reason && (
              <p className="mono break-words rounded-sm border border-line bg-inset px-3 py-2 text-[0.74rem] text-faint">
                reason: {reason}
              </p>
            )}
            <div className="mt-2 flex flex-col gap-3">
              <Link to="/auth" className="btn btn--primary btn--block">
                Back to sign in
              </Link>
              <Link to="/auth?mode=signup" className="btn btn--ghost btn--block">
                Use email instead
              </Link>
            </div>
          </>
        ) : (
          <RouteLoader label="Completing Google sign-in" />
        )}
      </div>
    </div>
  )
}
