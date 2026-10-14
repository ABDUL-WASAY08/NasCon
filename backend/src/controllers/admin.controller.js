import { User } from '../models/User.js'
import { ROLES, capabilitiesFor } from '../constants/roles.js'
import { env } from '../config/env.js'
import { dbState } from '../config/db.js'

/**
 * Administrator-only console endpoints. Every route that reaches this
 * controller is already guarded by `requireAuth` + `authorize('admin')`.
 */
export const adminController = {
  async overview(_req, res) {
    const [totalUsers, verifiedUsers, googleUsers, byRoleAgg, recentUsers] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ emailVerified: true }),
      User.countDocuments({ authProvider: 'google' }),
      User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]),
      User.find().sort({ createdAt: -1 }).limit(8),
    ])

    const byRole = Object.fromEntries(ROLES.map((name) => [name, 0]))
    for (const row of byRoleAgg) byRole[row._id] = row.count

    res.json({
      overview: {
        admins: env.adminEmails,
        platform: {
          name: 'NEXUS',
          api: 'v1',
          environment: env.nodeEnv,
          database: dbState(),
          uptimeSeconds: Math.round(process.uptime()),
        },
        stats: { totalUsers, verifiedUsers, googleUsers, byRole },
        recentUsers,
        roleCapabilities: Object.fromEntries(ROLES.map((role) => [role, capabilitiesFor(role)])),
      },
    })
  },
}
