import bcrypt from 'bcryptjs'
import { env } from '../config/env.js'
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/tokens.js'
import { ApiError } from '../utils/ApiError.js'
import { capabilitiesFor } from '../constants/roles.js'
import { User } from '../models/User.js'

const REFRESH_COOKIE = env.cookie.refreshName
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000

const cookieOptions = {
  httpOnly: true,
  secure: env.cookie.secure,
  sameSite: env.cookie.sameSite,
  path: '/',
  maxAge: SEVEN_DAYS_MS,
}

function setRefreshCookie(res, token) {
  res.cookie(REFRESH_COOKIE, token, cookieOptions)
}

export function clearRefreshCookie(res) {
  res.clearCookie(REFRESH_COOKIE, { ...cookieOptions, maxAge: undefined })
}

export function sessionPayload(user) {
  return { user: user.toJSON(), capabilities: capabilitiesFor(user.role) }
}

/** Issues an access token, rotates the stored refresh token, and sets the cookie. */
export async function establishSession(user, res) {
  const accessToken = signAccessToken(user)
  const refreshToken = signRefreshToken(user)

  user.refreshTokenHash = await bcrypt.hash(refreshToken, 10)
  user.lastLoginAt = new Date()
  await user.save()

  setRefreshCookie(res, refreshToken)
  return { accessToken, ...sessionPayload(user) }
}

/**
 * Verifies the refresh token from the request cookie and rotates the session.
 * Throws an ApiError when the token is missing, expired or revoked.
 */
export async function rotateSession(req, res) {
  const token = req.cookies?.[REFRESH_COOKIE]
  if (!token) throw ApiError.unauthorized('No active session', 'NO_REFRESH_TOKEN')

  let payload
  try {
    payload = verifyRefreshToken(token)
  } catch {
    throw ApiError.unauthorized('Session expired, please sign in again', 'SESSION_EXPIRED')
  }

  const user = await User.findById(payload.sub).select('+refreshTokenHash')
  if (!user || !user.refreshTokenHash) {
    throw ApiError.unauthorized('Session is no longer valid', 'SESSION_REVOKED')
  }

  const matches = await bcrypt.compare(token, user.refreshTokenHash)
  if (!matches) throw ApiError.unauthorized('Session was revoked', 'SESSION_REVOKED')

  return establishSession(user, res)
}

/** Revokes the stored refresh token for the current cookie, if any. */
export async function revokeSession(req) {
  const token = req.cookies?.[REFRESH_COOKIE]
  if (!token) return
  try {
    const payload = verifyRefreshToken(token)
    await User.findByIdAndUpdate(payload.sub, { $unset: { refreshTokenHash: 1 } })
  } catch {
    // Token already invalid — nothing to revoke.
  }
}

export { REFRESH_COOKIE }
