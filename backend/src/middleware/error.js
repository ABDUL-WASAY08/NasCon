import { ApiError } from '../utils/ApiError.js'
import { env } from '../config/env.js'

// Errors thrown by passport-oauth2 when an OAuth handshake fails. These are
// configuration / client problems, not server faults, so we must not mask or
// misreport them as "Internal server error".
const OAUTH_ERROR_NAMES = new Set(['TokenError', 'AuthorizationError', 'InternalOAuthError'])

function isOAuthError(error) {
  return OAUTH_ERROR_NAMES.has(error?.name)
}

export function notFound(req, _res, next) {
  next(ApiError.notFound(`Route ${req.method} ${req.originalUrl} does not exist`, 'ROUTE_NOT_FOUND'))
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(error, _req, res, _next) {
  const oauth = isOAuthError(error)
  const rawStatus = error instanceof ApiError ? error.status : error.status || 500
  const status = oauth ? 400 : rawStatus
  const hideMessage = rawStatus >= 500 && env.isProd && !oauth

  const payload = {
    error: {
      message: hideMessage ? 'Internal server error' : error.message,
      code: error.code || 'INTERNAL_ERROR',
    },
  }
  if (error.issues) payload.error.issues = error.issues

  if (rawStatus >= 500 || oauth) console.error('[error]', error)

  res.status(status).json(payload)
}
