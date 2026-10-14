import bcrypt from 'bcryptjs'
import { connectDb, disconnectDb } from './config/db.js'
import { User } from './models/User.js'
import { env } from './config/env.js'

/**
 * Demo accounts. The administrator account is listed in ADMIN_EMAILS and signs
 * in exclusively with Google, so it is seeded without a password.
 */
const DEMO_USERS = [
  { name: 'Platform Admin', email: env.adminEmails[0], role: 'admin', organization: 'NEXUS', google: true },
  { name: 'Operations Manager', email: 'manager@nexus.dev', password: 'Manager@12345', role: 'manager', organization: 'Northline Services' },
  { name: 'Imran Khan', email: 'provider@nexus.dev', password: 'Provider@12345', role: 'provider', organization: 'Northline Services' },
  { name: 'Ayesha Rahman', email: 'customer@nexus.dev', password: 'Customer@12345', role: 'customer', organization: '' },
]

async function main() {
  await connectDb()

  for (const entry of DEMO_USERS) {
    const update = {
      name: entry.name,
      role: entry.role,
      organization: entry.organization,
      authProvider: entry.google ? 'google' : 'local',
      emailVerified: true,
    }

    if (entry.google) {
      update.passwordHash = undefined
    } else {
      update.passwordHash = await bcrypt.hash(entry.password, 12)
    }

    await User.findOneAndUpdate(
      { email: entry.email },
      { $set: update, $unset: entry.google ? { refreshTokenHash: 1 } : {} },
      { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true },
    )
    console.log(`✓ ${entry.role.padEnd(8)} ${entry.email.padEnd(28)} ${entry.password || 'Google sign-in only'}`)
  }

  await disconnectDb()
  console.log('\nSeed complete. Administrators sign in with Google; others can use email + password.')
}

main().catch(async (error) => {
  console.error('Seed failed:', error.message)
  await disconnectDb().catch(() => {})
  process.exit(1)
})
