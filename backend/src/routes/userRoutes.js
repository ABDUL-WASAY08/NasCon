import { Router } from 'express';
import { avatarUpload } from '../config/cloudinary.js';
import { profile, uploadAvatar as saveAvatar } from '../controllers/userController.js';
import { asyncHandler } from '../middlewares/asyncHandler.js';
import { requireAuth } from '../middlewares/authMiddleware.js';

const router = Router();

router.use(requireAuth);
router.get('/profile', profile);
router.post('/upload-avatar', avatarUpload.single('avatar'), asyncHandler(saveAvatar));

export default router;
