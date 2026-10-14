import { Router } from 'express'
import { dashboardController } from '../controllers/dashboard.controller.js'
import { requireAuth } from '../middleware/auth.js'
import { asyncHandler } from '../utils/asyncHandler.js'

const router = Router()

router.get('/summary', requireAuth, asyncHandler(dashboardController.summary))

export default router
