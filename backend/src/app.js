import express from 'express'
import mongoose from 'mongoose'
import cors from 'cors'
import helmet from 'helmet'
import cookieParser from 'cookie-parser'
import rateLimit from 'express-rate-limit'
import passport from './config/passport.js'
import { env } from './config/env.js'
import { dbState } from './config/db.js'
import authRoutes from './routes/auth.routes.js'
import googleRoutes from './routes/google.routes.js'
import userRoutes from './routes/user.routes.js'
import dashboardRoutes from './routes/dashboard.routes.js'
import adminRoutes from './routes/admin.routes.js'
import { notFound, errorHandler } from './middleware/error.js'

const app = express()

app.disable('x-powered-by')
app.set('trust proxy', 1)

app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }),
)
app.use(cors({ origin: env.clientUrl, credentials: true }))
app.use(express.json({ limit: '1mb' }))
app.use(cookieParser())
app.use(passport.initialize())

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'nexus-api', db: dbState(), uptime: process.uptime() })
})

// If the database is unavailable, fail fast with a clear 503 instead of hanging
// on the driver's server-selection timeout.
app.use('/api', (_req, res, next) => {
  if (mongoose.connection.readyState !== 1) {
    return res.status(503).json({
      error: {
        message: 'Database unavailable. Check the MongoDB connection and IP allowlist.',
        code: 'DB_UNAVAILABLE',
      },
    })
  }
  return next()
})

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Too many attempts, try again later', code: 'RATE_LIMITED' } },
})

app.use('/api/auth', authLimiter, authRoutes)
app.use('/auth', googleRoutes)
app.use('/api/users', userRoutes)
app.use('/api/dashboard', dashboardRoutes)
app.use('/api/admin', adminRoutes)

app.use(notFound)
app.use(errorHandler)

export default app
