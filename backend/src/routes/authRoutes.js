import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
import { googleLogin, login, register } from '../controllers/authController.js';
import { asyncHandler } from '../middlewares/asyncHandler.js';
import { requireAuth } from '../middlewares/authMiddleware.js';
import { currentUser, logout } from '../controllers/userController.js';

const router = Router();
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message: 'Too many sign-in attempts. Try again later.' },
});

router.post('/register', loginLimiter, asyncHandler(register));
router.post('/login', loginLimiter, asyncHandler(login));
router.post('/google', loginLimiter, asyncHandler(googleLogin));
router.get('/me', requireAuth, currentUser);
router.post('/logout', requireAuth, asyncHandler(logout));

export default router;
