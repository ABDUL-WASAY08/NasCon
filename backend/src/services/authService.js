import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export function createAccessToken(user) {
  return jwt.sign(
    { role: user.role, token_version: user.tokenVersion || 0 },
    env.jwtSecret,
    { subject: user.id, expiresIn: env.jwtExpiresIn, issuer: 'nascon-api' },
  );
}

export function createSession(user) {
  const accessToken = createAccessToken(user);
  const decoded = jwt.decode(accessToken);
  return {
    access_token: accessToken,
    token_type: 'Bearer',
    expires_at: new Date(decoded.exp * 1000).toISOString(),
    user: user.toPublicJSON(),
  };
}
