import { useMemo, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Logo from '../components/Logo.jsx'
import { api } from '../lib/api-client.js'
import { useAuth } from '../context/auth-context.js'
import { homeForRole } from '../lib/roles.js'

const SELF_SIGNUP_ROLES = [
  { value: '', label: 'Select a role' },
  { value: 'customer', label: 'Customer — book services' },
  { value: 'provider', label: 'Service provider / staff' },
]

const GOOGLE_ROLES = [
  { value: 'customer', label: 'Customer', hint: 'Book services' },
  { value: 'provider', label: 'Service provider', hint: 'Deliver services' },
]

const ACTIVITY = [
  { text: 'Booking BL-2041 confirmed', meta: 'booking-service', tone: 'live' },
  { text: 'Technician Imran K. assigned', meta: 'staff-service', tone: 'live' },
  { text: 'Chat thread opened with customer', meta: 'chat-service', tone: 'ai' },
  { text: 'Weekly report queued · 21:00', meta: 'report-worker', tone: 'plain' },
]

const ASSURANCES = [
  'JWT access tokens with rotating refresh sessions in an httpOnly cookie.',
  'Every protected action is authorized on the server, never in the client.',
  'Google sign-in is handled by Passport; the client secret never leaves the API.',
]

const EMPTY = { name: '', email: '', organization: '', role: '', password: '', confirm: '', terms: false }

function scorePassword(password) {
  if (!password) return 0
  let score = 0
  if (password.length >= 8) score += 1
  if (password.length >= 12) score += 1
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score += 1
  if (/\d/.test(password)) score += 1
  if (/[^A-Za-z0-9]/.test(password)) score += 1
  return Math.min(score, 4)
}

const STRENGTH = ['Too short', 'Weak', 'Fair', 'Good', 'Strong']

export default function Auth() {
  const [params, setParams] = useSearchParams()
  const rawMode = params.get('mode')
  const mode = rawMode === 'signup' || rawMode === 'reset' ? rawMode : 'signin'
  const nextParam = params.get('next')
  const deniedAlert = params.get('denied') ? 'You do not have access to that area.' : ''

  const navigate = useNavigate()
  const { signIn } = useAuth()

  const [form, setForm] = useState(EMPTY)
  const [errors, setErrors] = useState({})
  const [alert, setAlert] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const [resetNotice, setResetNotice] = useState(false)
  const [googleRole, setGoogleRole] = useState('customer')
  const [googleRoleChosen, setGoogleRoleChosen] = useState(false)
  const formRef = useRef(null)

  const setMode = (value) => {
    setErrors({})
    setAlert('')
    setResetNotice(false)
    setParams(value === 'signin' ? {} : { mode: value })
  }

  const strength = useMemo(() => scorePassword(form.password), [form.password])

  const update = (key) => (event) => {
    const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  const validate = () => {
    const found = {}
    const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)

    if (mode === 'reset') {
      if (!form.email.trim()) found.email = 'Enter the email on your account.'
      else if (!emailOk) found.email = 'That email address looks incomplete.'
      return found
    }

    if (mode === 'signup' && !form.name.trim()) found.name = 'Enter your full name.'
    if (!form.email.trim()) found.email = 'Enter your email address.'
    else if (!emailOk) found.email = 'That email address looks incomplete.'
    if (mode === 'signup' && !form.role) found.role = 'Choose the role you need.'
    if (!form.password) found.password = 'Enter your password.'
    else if (mode === 'signup' && form.password.length < 8) found.password = 'Use at least 8 characters.'

    if (mode === 'signup') {
      if (!form.confirm) found.confirm = 'Re-enter your password.'
      else if (form.confirm !== form.password) found.confirm = 'Passwords do not match.'
      if (!form.terms) found.terms = 'Accept the terms to create an account.'
    }

    return found
  }

  const applyServerError = (error) => {
    if (error.issues?.length) {
      const mapped = {}
      for (const issue of error.issues) mapped[issue.field] = issue.message
      setErrors(mapped)
      return
    }
    if (error.code === 'EMAIL_IN_USE') return setErrors({ email: 'An account with this email already exists.' })
    if (error.code === 'INVALID_CREDENTIALS') return setAlert('Invalid email or password.')
    if (error.code === 'GOOGLE_REQUIRED') return setAlert('Administrator accounts must sign in with Google.')
    if (error.status === 429 || error.code === 'RATE_LIMITED') {
      return setAlert('Too many attempts. Wait a moment and try again.')
    }
    setAlert(error.message || 'Something went wrong. Please try again.')
  }

  const handleSubmit = async (event) => {
    event.preventDefault()
    if (submitting) return
    setAlert('')

    const found = validate()
    setErrors(found)
    if (Object.keys(found).length > 0) {
      formRef.current?.querySelector('[aria-invalid="true"]')?.focus()
      return
    }

    if (mode === 'reset') {
      setResetNotice(true)
      return
    }

    setSubmitting(true)
    try {
      const payload =
        mode === 'signup'
          ? {
              name: form.name,
              email: form.email,
              password: form.password,
              role: form.role,
              organization: form.organization,
            }
          : { email: form.email, password: form.password }

      const session = mode === 'signup' ? await api.register(payload) : await api.login(payload)
      signIn(session)
      navigate(nextParam || homeForRole(session.user.role), { replace: true })
    } catch (error) {
      applyServerError(error)
    } finally {
      setSubmitting(false)
    }
  }

  const heading =
    mode === 'signup' ? 'Create your account' : mode === 'reset' ? 'Reset your password' : 'Welcome back'
  const subheading =
    mode === 'signup'
      ? 'One account covers every role in the workspace.'
      : mode === 'reset'
        ? 'Enter your email and we will look up your account.'
        : 'Sign in to the operations console.'

  const errorFor = (key) =>
    errors[key] ? (
      <span className="field__error" id={`${key}-error`}>
        <svg viewBox="0 0 16 16" width="13" height="13" aria-hidden="true">
          <circle cx="8" cy="8" r="7" fill="none" stroke="currentColor" strokeWidth="1.4" />
          <path d="M8 4.4v4.2M8 11.3h.01" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        </svg>
        {errors[key]}
      </span>
    ) : null

  const fieldProps = (key, extra = {}) => ({
    id: key,
    name: key,
    value: form[key],
    onChange: update(key),
    'aria-invalid': errors[key] ? 'true' : undefined,
    'aria-describedby': errors[key] ? `${key}-error` : undefined,
    ...extra,
  })

  return (
    <div className="grid min-h-svh lg:grid-cols-[minmax(0,1.05fr)_minmax(0,1fr)]">
      {/* brand aside */}
      <aside className="relative hidden flex-col justify-between border-e border-line p-10 lg:flex">
        <div className="flex items-center justify-between">
          <Link to="/" aria-label="NEXUS home">
            <Logo />
          </Link>
          <Link to="/" className="mono text-muted hover:text-ink">
            ← Back to site
          </Link>
        </div>

        <div className="flex max-w-[46ch] flex-col gap-5">
          <span className="eyebrow eyebrow--live">NEXUS console</span>
          <h2>Every request, from intake to report</h2>
          <p className="lede">
            Sign in and the whole platform opens: AI booking, staff assignment, live chat,
            operations dashboard and scheduled reporting.
          </p>
          <ul className="flex flex-col gap-3">
            {ASSURANCES.map((item) => (
              <li key={item} className="flex items-start gap-3 text-[0.9rem] text-muted">
                <span className="mt-0.5 grid h-5 w-5 flex-none place-items-center rounded-full bg-live">
                  <svg viewBox="0 0 12 12" width="10" height="10" aria-hidden="true">
                    <path
                      d="M2.5 6.4 5 8.8 9.6 3.4"
                      fill="none"
                      stroke="var(--color-inkdee)"
                      strokeWidth="1.9"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </span>
                {item}
              </li>
            ))}
          </ul>
        </div>

        <div className="flex flex-col gap-3" aria-hidden="true">
          <div className="mono flex items-center gap-2 text-faint">
            <span className="dot dot--pulse text-live" />
            live activity
          </div>
          <ul className="flex flex-col gap-2">
            {ACTIVITY.map((row) => (
              <li key={row.text} className="flex items-center gap-3 text-[0.84rem]">
                <span
                  className={`dot ${
                    row.tone === 'ai' ? 'text-ai' : row.tone === 'plain' ? 'text-faint' : 'text-live'
                  }`}
                />
                <span className="text-muted">{row.text}</span>
                <span className="mono ms-auto text-faint">{row.meta}</span>
              </li>
            ))}
          </ul>
        </div>
      </aside>

      {/* form */}
      <main className="flex items-center justify-center bg-canvas/40 px-5 py-10">
        <div className="w-full max-w-[440px]">
          <div className="mb-6 flex items-center justify-between lg:hidden">
            <Link to="/" aria-label="NEXUS home">
              <Logo />
            </Link>
            <Link to="/" className="mono text-muted hover:text-ink">
              ← Back
            </Link>
          </div>

          {resetNotice ? (
            <div className="panel flex flex-col gap-4 p-8 text-center">
              <span className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-live">
                <svg viewBox="0 0 24 24" width="26" height="26" aria-hidden="true">
                  <path
                    d="M5 12.8 10 17.5 19 6.5"
                    fill="none"
                    stroke="var(--color-inkdee)"
                    strokeWidth="2.4"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </span>
              <h2>Password reset</h2>
              <p className="lede mx-auto">
                Self-service reset needs an email provider, which isn&apos;t connected in this
                build. An administrator can reset the password for <strong className="text-ink">{form.email}</strong> from
                the console.
              </p>
              <button type="button" className="btn btn--primary btn--block" onClick={() => setMode('signin')}>
                Back to sign in
              </button>
            </div>
          ) : (
            <div className="panel flex flex-col gap-5 p-8">
              <div role="tablist" aria-label="Authentication mode" className="grid grid-cols-2 gap-1 rounded-sm border border-line p-1">
                {['signin', 'signup'].map((value) => (
                  <button
                    key={value}
                    type="button"
                    role="tab"
                    aria-selected={mode === value}
                    className={`rounded-xs px-3 py-2 text-[0.88rem] font-semibold transition-colors ${
                      mode === value ? 'bg-surface-3 text-ink' : 'text-muted hover:text-ink'
                    }`}
                    onClick={() => setMode(value)}
                  >
                    {value === 'signin' ? 'Sign in' : 'Create account'}
                  </button>
                ))}
              </div>

              <div className="flex flex-col gap-2">
                <h1 className="text-[clamp(1.5rem,3vw,1.9rem)]">{heading}</h1>
                <p className="lede">{subheading}</p>
              </div>

              {mode !== 'reset' && (
                <>
                  <div className="field">
                    <span className="text-[0.82rem] font-semibold text-muted">Continue with Google as</span>
                    <div className="grid grid-cols-2 gap-2" role="radiogroup" aria-label="Google account role">
                      {GOOGLE_ROLES.map((option) => {
                        const active = googleRoleChosen && googleRole === option.value
                        return (
                          <button
                            key={option.value}
                            type="button"
                            role="radio"
                            aria-checked={active}
                            onClick={() => {
                              setGoogleRole(option.value)
                              setGoogleRoleChosen(true)
                            }}
                            className={`flex flex-col items-start gap-0.5 rounded-sm border px-3 py-2.5 text-left transition-colors ${
                              active
                                ? 'border-live-line bg-live-soft'
                                : 'border-line-strong bg-inset hover:border-faint'
                            }`}
                          >
                            <span className="text-[0.86rem] font-semibold text-ink">{option.label}</span>
                            <span className="mono text-[0.68rem] text-faint">{option.hint}</span>
                          </button>
                        )
                      })}
                    </div>
                    <span className="field__hint">
                      Choose a role for a new account. Existing accounts keep their role, and
                      officialtaha004@gmail.com is always the administrator.
                    </span>
                  </div>

                  <a
                    href={api.googleUrl(googleRoleChosen ? googleRole : undefined)}
                    className="btn btn--ghost btn--block"
                  >
                    <svg viewBox="0 0 18 18" width="18" height="18" aria-hidden="true">
                      <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.91c1.7-1.57 2.69-3.88 2.69-6.62Z" />
                      <path fill="#34A853" d="M9 18c2.43 0 4.47-.8 5.96-2.18l-2.91-2.26c-.8.54-1.84.86-3.05.86-2.34 0-4.32-1.58-5.03-3.7H.96v2.33A9 9 0 0 0 9 18Z" />
                      <path fill="#FBBC05" d="M3.97 10.72a5.4 5.4 0 0 1 0-3.44V4.95H.96a9 9 0 0 0 0 8.1l3.01-2.33Z" />
                      <path fill="#EA4335" d="M9 3.58c1.32 0 2.5.45 3.44 1.35l2.58-2.58C13.46.9 11.43 0 9 0A9 9 0 0 0 .96 4.95l3.01 2.33C4.68 5.16 6.66 3.58 9 3.58Z" />
                    </svg>
                    Continue with Google
                  </a>
                  <div className="relative text-center">
                    <span className="absolute inset-x-0 top-1/2 h-px bg-line" aria-hidden="true" />
                    <span className="relative bg-surface-1 px-3 font-mono text-[0.72rem] text-faint">or use your email</span>
                  </div>
                </>
              )}

              <form ref={formRef} onSubmit={handleSubmit} noValidate className="flex flex-col gap-4">
                {(alert || deniedAlert) && (
                  <p
                    className="rounded-sm border border-danger/40 bg-danger-soft px-4 py-3 text-[0.84rem] text-danger"
                    role="alert"
                  >
                    {alert || deniedAlert}
                  </p>
                )}

                {mode === 'signup' && (
                  <div className="field">
                    <label htmlFor="name">Full name</label>
                    <input className="field__input" type="text" autoComplete="name" placeholder="Ayesha Rahman" {...fieldProps('name')} />
                    {errorFor('name')}
                  </div>
                )}

                <div className="field">
                  <label htmlFor="email">Email address</label>
                  <input className="field__input" type="email" autoComplete="email" placeholder="you@company.com" {...fieldProps('email')} />
                  {errorFor('email')}
                </div>

                {mode === 'signup' && (
                  <div className="grid gap-4 sm:grid-cols-2">
                    <div className="field">
                      <label htmlFor="organization">Organization (optional)</label>
                      <input className="field__input" type="text" autoComplete="organization" placeholder="Northline Services" {...fieldProps('organization')} />
                    </div>
                    <div className="field">
                      <label htmlFor="role">I&apos;m joining as</label>
                      <select className="field__input" {...fieldProps('role')}>
                        {SELF_SIGNUP_ROLES.map((role) => (
                          <option key={role.value} value={role.value} disabled={role.value === ''}>
                            {role.label}
                          </option>
                        ))}
                      </select>
                      {errorFor('role')}
                    </div>
                  </div>
                )}

                {mode !== 'reset' && (
                  <div className="field">
                    <label htmlFor="password">Password</label>
                    <div className="relative">
                      <input
                        className="field__input pe-12"
                        type={showPassword ? 'text' : 'password'}
                        autoComplete={mode === 'signup' ? 'new-password' : 'current-password'}
                        placeholder={mode === 'signup' ? 'At least 8 characters' : 'Your password'}
                        {...fieldProps('password')}
                      />
                      <button
                        type="button"
                        className="absolute end-3 top-1/2 -translate-y-1/2 text-muted hover:text-ink"
                        aria-pressed={showPassword}
                        aria-label={showPassword ? 'Hide password' : 'Show password'}
                        onClick={() => setShowPassword((value) => !value)}
                      >
                        <svg viewBox="0 0 20 20" width="18" height="18" aria-hidden="true">
                          <path d="M1.8 10S4.6 4.8 10 4.8 18.2 10 18.2 10 15.4 15.2 10 15.2 1.8 10 1.8 10Z" fill="none" stroke="currentColor" strokeWidth="1.3" />
                          <circle cx="10" cy="10" r="2.4" fill="none" stroke="currentColor" strokeWidth="1.3" />
                          {showPassword && <path d="M3 3 17 17" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />}
                        </svg>
                      </button>
                    </div>
                    {errorFor('password')}
                    {mode === 'signup' && form.password && (
                      <div className="flex items-center gap-3">
                        <span className="flex gap-1" aria-hidden="true">
                          {[0, 1, 2, 3].map((segment) => (
                            <i key={segment} className={`h-1 w-6 rounded-full ${segment < strength ? 'bg-live' : 'bg-line-strong'}`} />
                          ))}
                        </span>
                        <span className="mono text-[0.74rem] text-faint">{STRENGTH[strength]}</span>
                      </div>
                    )}
                  </div>
                )}

                {mode === 'signup' && (
                  <div className="field">
                    <label htmlFor="confirm">Confirm password</label>
                    <input
                      className="field__input"
                      type={showPassword ? 'text' : 'password'}
                      autoComplete="new-password"
                      placeholder="Repeat your password"
                      {...fieldProps('confirm')}
                    />
                    {errorFor('confirm')}
                  </div>
                )}

                {mode === 'signin' && (
                  <div className="flex items-center justify-between">
                    <span className="mono text-[0.74rem] text-faint">Sessions rotate on every refresh</span>
                    <button type="button" className="text-[0.82rem] font-medium text-live hover:underline" onClick={() => setMode('reset')}>
                      Forgot password?
                    </button>
                  </div>
                )}

                {mode === 'signup' && (
                  <div className="field">
                    <label className="flex items-start gap-2.5 text-[0.84rem] text-muted">
                      <input
                        type="checkbox"
                        className="mt-0.5"
                        checked={form.terms}
                        onChange={update('terms')}
                        aria-invalid={errors.terms ? 'true' : undefined}
                        aria-describedby={errors.terms ? 'terms-error' : undefined}
                      />
                      <span>I agree to the platform terms and to the data-handling policy.</span>
                    </label>
                    {errors.terms && (
                      <span className="field__error" id="terms-error">
                        {errors.terms}
                      </span>
                    )}
                  </div>
                )}

                <button type="submit" className="btn btn--primary btn--block" disabled={submitting} aria-busy={submitting}>
                  {submitting
                    ? mode === 'signup'
                      ? 'Creating account…'
                      : 'Signing in…'
                    : mode === 'signup'
                      ? 'Create account'
                      : mode === 'reset'
                        ? 'Continue'
                        : 'Sign in'}
                </button>

                <p className="text-center text-[0.86rem] text-muted">
                  {mode === 'signin' ? (
                    <>
                      New to NEXUS?{' '}
                      <button type="button" className="font-medium text-live hover:underline" onClick={() => setMode('signup')}>
                        Create an account
                      </button>
                    </>
                  ) : (
                    <>
                      Already have an account?{' '}
                      <button type="button" className="font-medium text-live hover:underline" onClick={() => setMode('signin')}>
                        Sign in
                      </button>
                    </>
                  )}
                </p>
              </form>

              <p className="mono text-center text-[0.72rem] text-faint">
                Admin: officialtaha004@gmail.com · Google only · Demo: manager@nexus.dev
              </p>
            </div>
          )}
        </div>
      </main>
    </div>
  )
}
