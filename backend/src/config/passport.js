import passport from 'passport'
import mongoose from 'mongoose'
import passportGoogle from 'passport-google-oauth20'
import { env } from './env.js'
import { User } from '../models/User.js'
import { SELF_SIGNUP_ROLES, DEFAULT_ROLE } from '../constants/roles.js'

const GoogleStrategy = passportGoogle.Strategy

/** Reads the role the visitor picked on the sign-in screen (round-tripped via OAuth `state`). */
function requestedRoleFrom(req) {
  const role = req?.query?.state
  return SELF_SIGNUP_ROLES.includes(role) ? role : null
}

passport.use(
  new GoogleStrategy(
    {
      clientID: env.google.clientId,
      clientSecret: env.google.clientSecret,
      callbackURL: env.google.callbackUrl,
      scope: ['profile', 'email'],
      passReqToCallback: true,
    },
    async (req, _accessToken, _refreshToken, profile, done) => {
      try {
        if (mongoose.connection.readyState !== 1) {
          console.error('[google-oauth] cannot look up the user: MongoDB is not connected')
          return done(null, false, { message: 'db_unavailable' })
        }

        const email = profile.emails?.[0]?.value?.toLowerCase()
        if (!email) return done(new Error('Google account did not expose an email address'))

        const avatarUrl = profile.photos?.[0]?.value || ''
        const isAdmin = env.isAdminEmail(email)
        const requestedRole = requestedRoleFrom(req)

        let user = await User.findOne({ $or: [{ googleId: profile.id }, { email }] })

        if (!user) {
          // New account. Whitelisted emails are always administrators; everyone
          // else gets the role they chose (customer or service provider).
          user = await User.create({
            name: profile.displayName || email.split('@')[0],
            email,
            googleId: profile.id,
            avatarUrl,
            authProvider: 'google',
            emailVerified: true,
            role: isAdmin ? 'admin' : requestedRole || DEFAULT_ROLE,
          })
        } else {
          // Link the Google identity to an existing account with the same email.
          if (!user.googleId) user.googleId = profile.id
          if (user.authProvider !== 'google' && !user.passwordHash) user.authProvider = 'google'
          if (!user.avatarUrl && avatarUrl) user.avatarUrl = avatarUrl
          user.emailVerified = true

          // The whitelist always wins: admins never get demoted.
          if (isAdmin) {
            if (user.role !== 'admin') user.role = 'admin'
          } else if (requestedRole && SELF_SIGNUP_ROLES.includes(user.role)) {
            // A returning customer/provider may switch between the two self-signup
            // roles. Privileged roles (manager, admin) are never changed here.
            user.role = requestedRole
          }

          await user.save()
        }

        return done(null, user)
      } catch (error) {
        return done(error)
      }
    },
  ),
)

export default passport
