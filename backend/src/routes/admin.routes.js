import { Router } from 'express'
import { adminController } from '../controllers/admin.controller.js'
import { requireAuth, authorize } from '../middleware/auth.js'
import { asyncHandler } from '../utils/asyncHandler.js'

const router = Router()

// The administrator console is Google-only: admins authenticate through Google,
// and the admin role is granted only for whitelisted Google email addresses.
router.use(requireAuth, authorize('admin'))

router.get('/overview', asyncHandler(adminController.overview))

export default router
