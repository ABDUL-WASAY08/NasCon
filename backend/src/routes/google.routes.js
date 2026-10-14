import { Router } from 'express'
import passport from '../config/passport.js'
import { env } from '../config/env.js'
import { SELF_SIGNUP_ROLES } from '../constants/roles.js'
import { establishSession } from '../services/auth.service.js'

const router = Router()

function callbackRedirect(status, reason) {
  const params = new URLSearchParams({ status })
  if (reason) params.set('reason', reason)
  return `${env.clientUrl}/auth/callback?${params.toString()}`
}

// Step 1 — bounce the user to Google. The role the visitor picked on the sign-in
// screen (customer or service provider) rides along as the OAuth `state` so the
// callback can apply it. Administrators are matched by email and always win.
router.get('/google', (req, res, next) => {
  if (!env.google.clientId || !env.google.clientSecret) {
    console.error('[google-oauth] credentials are not configured')
    return res.redirect(callbackRedirect('error', 'not_configured'))
  }

  const requestedRole = SELF_SIGNUP_ROLES.includes(req.query.role) ? req.query.role : null

  return passport.authenticate('google', {
    scope: ['profile', 'email'],
    session: false,
    prompt: 'select_account',
    ...(requestedRole ? { state: requestedRole } : {}),
  })(req, res, next)
})

// Step 2 — Google redirects back here (must match GOOGLE_CALLBACK_URL exactly).
// Use a custom callback so OAuth failures are sent back to the app as a friendly
// error instead of dumping a raw JSON 500 page.
router.get('/google/callback', (req, res, next) => {
  // Google can bounce straight back with an error and no code (e.g. access_denied
  // when the consent screen is in testing mode and the account is not a test user).
  if (req.query.error) {
    console.warn(
      '[google-oauth] Google returned an error:',
      req.query.error,
      req.query.error_description || '',
    )
    return res.redirect(callbackRedirect('error', String(req.query.error)))
  }

  return passport.authenticate('google', { session: false }, async (err, user, info) => {
    if (err) {
      console.error('[google-oauth] failed:', err.message, '| code:', err.code)
      return res.redirect(callbackRedirect('error', err.message || 'oauth_failed'))
    }
    if (!user) {
      console.warn('[google-oauth] no user returned:', info)
      return res.redirect(callbackRedirect('error', info?.message || 'no_user'))
    }
    try {
      await establishSession(user, res)
      return res.redirect(callbackRedirect('success'))
    } catch (sessionError) {
      console.error('[google-oauth] session establishment failed:', sessionError.message)
      return res.redirect(callbackRedirect('error', 'session_failed'))
    }
  })(req, res, next)
})

export default router
