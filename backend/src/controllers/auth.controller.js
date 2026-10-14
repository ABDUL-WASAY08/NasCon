import bcrypt from 'bcryptjs'
import { User } from '../models/User.js'
import { SELF_SIGNUP_ROLES, DEFAULT_ROLE, capabilitiesFor } from '../constants/roles.js'
import { ApiError } from '../utils/ApiError.js'
import {
  establishSession,
  rotateSession,
  revokeSession,
  clearRefreshCookie,
} from '../services/auth.service.js'

const normalizeEmail = (email) => String(email || '').trim().toLowerCase()

export const authController = {
  async register(req, res) {
    const { name, password, role, organization } = req.body
    const email = normalizeEmail(req.body.email)

    const existing = await User.findOne({ email })
    if (existing) throw ApiError.conflict('An account with this email already exists', 'EMAIL_IN_USE')

    const passwordHash = await bcrypt.hash(password, 12)
    const user = await User.create({
      name,
      email,
      passwordHash,
      role: SELF_SIGNUP_ROLES.includes(role) ? role : DEFAULT_ROLE,
      organization: organization || '',
      authProvider: 'local',
    })

    const session = await establishSession(user, res)
    res.status(201).json(session)
  },

  async login(req, res) {
    const email = normalizeEmail(req.body.email)
    const { password } = req.body

    const user = await User.findOne({ email }).select('+passwordHash')
    if (!user || !user.passwordHash) {
      throw ApiError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS')
    }

    // Administrator accounts can only be accessed through Google sign-in.
    if (user.role === 'admin') {
      throw ApiError.forbidden('Administrator accounts must sign in with Google', 'GOOGLE_REQUIRED')
    }

    const ok = await bcrypt.compare(password, user.passwordHash)
    if (!ok) throw ApiError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS')

    const session = await establishSession(user, res)
    res.json(session)
  },

  async refresh(req, res) {
    const session = await rotateSession(req, res)
    res.json(session)
  },

  async logout(req, res) {
    await revokeSession(req)
    clearRefreshCookie(res)
    res.json({ ok: true })
  },

  async me(req, res) {
    res.json({ user: req.user.toJSON(), capabilities: capabilitiesFor(req.user.role) })
  },
}
