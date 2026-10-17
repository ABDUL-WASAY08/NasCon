import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { User } from '../models/User.js';
import { asyncHandler } from './asyncHandler.js';

export const requireAuth = asyncHandler(async (req, res, next) => {
  const [scheme, token] = (req.get('authorization') || '').split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Authentication is required.' });
  }

  let claims;
  try {
    claims = jwt.verify(token, env.jwtSecret, { issuer: 'nascon-api' });
  } catch {
    return res.status(401).json({ message: 'The access token is invalid or expired.' });
  }

  const user = await User.findById(claims.sub)
    .select('+profileImagePublicId +tokenVersion');
  if (!user || claims.token_version !== (user.tokenVersion || 0)) {
    return res.status(401).json({ message: 'The access token is invalid or revoked.' });
  }
  req.user = user;
  next();
});
