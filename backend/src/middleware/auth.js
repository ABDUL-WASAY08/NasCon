import { verifyAccessToken } from '../utils/tokens.js'
import { ApiError } from '../utils/ApiError.js'
import { User } from '../models/User.js'
import { ROLE_RANK, hasCapability } from '../constants/roles.js'

/**
 * Authenticates the request from the `Authorization: Bearer <token>` header and
 * attaches the current user document to `req.user`. This is the only place the
 * API trusts to establish identity.
 */
export async function requireAuth(req, _res, next) {
  try {
    const header = req.headers.authorization || ''
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : null
    if (!token) throw ApiError.unauthorized('Missing access token', 'NO_TOKEN')

    const payload = verifyAccessToken(token)
    const user = await User.findById(payload.sub)
    if (!user) throw ApiError.unauthorized('Account no longer exists', 'ACCOUNT_GONE')

    req.user = user
    next()
  } catch (error) {
    if (error instanceof ApiError) return next(error)
    if (error?.name === 'TokenExpiredError') {
      return next(ApiError.unauthorized('Access token expired', 'TOKEN_EXPIRED'))
    }
    next(ApiError.unauthorized('Invalid access token', 'INVALID_TOKEN'))
  }
}

/**
 * Allows the request only when the authenticated user holds one of the exact
 * roles listed. Must run after `requireAuth`.
 */
export function authorize(...roles) {
  return (req, _res, next) => {
    if (!req.user) return next(ApiError.unauthorized('Not authenticated', 'NOT_AUTHENTICATED'))
    if (!roles.includes(req.user.role)) {
      return next(
        ApiError.forbidden(`This action requires: ${roles.join(' or ')}`, 'ROLE_REQUIRED'),
      )
    }
    next()
  }
}

/**
 * Allows the request only when the authenticated user's role ranks at or above
 * the given minimum (customer < provider < manager < admin).
 */
export function authorizeMin(role) {
  return (req, _res, next) => {
    if (!req.user) return next(ApiError.unauthorized('Not authenticated', 'NOT_AUTHENTICATED'))
    const have = ROLE_RANK[req.user.role] || 0
    const need = ROLE_RANK[role] || 0
    if (have < need) {
      return next(ApiError.forbidden(`Requires ${role} access or higher`, 'ROLE_REQUIRED'))
    }
    next()
  }
}

/**
 * Allows the request only when the authenticated user's role grants the named
 * capability. This keeps authorization checks aligned with the capability
 * contract instead of hard-coded role lists.
 */
export function requireCapability(capability) {
  return (req, _res, next) => {
    if (!req.user) return next(ApiError.unauthorized('Not authenticated', 'NOT_AUTHENTICATED'))
    if (!hasCapability(req.user.role, capability)) {
      return next(ApiError.forbidden(`Missing capability: ${capability}`, 'CAPABILITY_REQUIRED'))
    }
    next()
  }
}
