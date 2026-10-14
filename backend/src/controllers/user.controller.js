import { User } from '../models/User.js'
import { ApiError } from '../utils/ApiError.js'

export const userController = {
  /** Lists users for managers and above. */
  async list(_req, res) {
    const users = await User.find().sort({ createdAt: -1 }).limit(100)
    res.json({ users })
  },

  /** Returns a single user by id. */
  async getOne(req, res) {
    const user = await User.findById(req.params.id)
    if (!user) throw ApiError.notFound('User not found', 'USER_NOT_FOUND')
    res.json({ user: user.toJSON() })
  },

  /** Changes another user's role. Administrators only, enforced by the route. */
  async updateRole(req, res) {
    const { id } = req.params
    const { role } = req.body

    if (String(req.user._id) === id) {
      throw ApiError.badRequest('You cannot change your own role', 'SELF_ROLE_CHANGE')
    }

    const user = await User.findById(id)
    if (!user) throw ApiError.notFound('User not found', 'USER_NOT_FOUND')

    user.role = role
    await user.save()
    res.json({ user: user.toJSON() })
  },
}
