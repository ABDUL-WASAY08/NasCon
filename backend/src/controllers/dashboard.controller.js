import { User } from '../models/User.js'
import { ROLE_RANK, ROLES, capabilitiesFor } from '../constants/roles.js'
import { env } from '../config/env.js'

export const dashboardController = {
  /** Role-aware summary: everyone gets personal data, managers+ get stats, admins get the roster. */
  async summary(req, res) {
    const { role } = req.user
    const rank = ROLE_RANK[role] || 0

    const summary = {
      role,
      capabilities: capabilitiesFor(role),
      session: {
        provider: req.user.authProvider,
        emailVerified: req.user.emailVerified,
        lastLoginAt: req.user.lastLoginAt,
        memberSince: req.user.createdAt,
      },
      platform: {
        name: 'NEXUS',
        api: 'v1',
        environment: env.nodeEnv,
      },
    }

    if (rank >= ROLE_RANK.manager) {
      const [totalUsers, verifiedUsers, byRoleAgg] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ emailVerified: true }),
        User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]),
      ])

      const byRole = Object.fromEntries(ROLES.map((name) => [name, 0]))
      for (const row of byRoleAgg) byRole[row._id] = row.count

      summary.stats = { totalUsers, verifiedUsers, byRole }
    }

    if (rank >= ROLE_RANK.admin) {
      summary.recentUsers = await User.find().sort({ createdAt: -1 }).limit(6)
    }

    res.json({ summary })
  },
}
