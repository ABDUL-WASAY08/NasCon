import { z } from 'zod'
import { ROLES } from '../constants/roles.js'

export const updateRoleSchema = z.object({
  role: z.enum(ROLES),
})
