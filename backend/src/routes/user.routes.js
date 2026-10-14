import { Router } from 'express'
import { userController } from '../controllers/user.controller.js'
import { requireAuth, authorize, authorizeMin } from '../middleware/auth.js'
import { validate } from '../middleware/validate.js'
import { asyncHandler } from '../utils/asyncHandler.js'
import { updateRoleSchema } from '../validators/user.schema.js'

const router = Router()

// Managers and above can read the directory; only administrators change roles.
router.use(requireAuth)

router.get('/', authorizeMin('manager'), asyncHandler(userController.list))
router.get('/:id', authorizeMin('manager'), asyncHandler(userController.getOne))
router.patch(
  '/:id/role',
  authorize('admin'),
  validate(updateRoleSchema),
  asyncHandler(userController.updateRole),
)

export default router
