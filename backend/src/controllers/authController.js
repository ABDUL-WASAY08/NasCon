import { OAuth2Client } from 'google-auth-library';
import { env } from '../config/env.js';
import { User } from '../models/User.js';
import { createSession } from '../services/authService.js';

const googleClient = new OAuth2Client(env.googleClientId);
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function normalizedEmail(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

export async function register(req, res) {
  const body = req.body ?? {};
  const fullName = typeof body.full_name === 'string'
    ? body.full_name.trim()
    : '';
  const email = normalizedEmail(body.email);
  const password = body.password;

  if (fullName.length < 2 || fullName.length > 100) {
    return res.status(400).json({ message: 'Name must be between 2 and 100 characters.' });
  }
  if (email.length > 254 || !emailPattern.test(email)) {
    return res.status(400).json({ message: 'Enter a valid email address.' });
  }
  if (
    typeof password !== 'string' ||
    password.length < 8 ||
    Buffer.byteLength(password, 'utf8') > 72
  ) {
    return res.status(400).json({ message: 'Password must be at least 8 characters and at most 72 UTF-8 bytes.' });
  }

  const user = new User({ fullName, email, role: 'viewer' });
  await user.setPassword(password);
  await user.save();
  res.status(201).json(createSession(user));
}

export async function login(req, res) {
  const body = req.body ?? {};
  const email = normalizedEmail(body.email);
  const password = body.password;
  if (!emailPattern.test(email) || typeof password !== 'string') {
    return res.status(400).json({ message: 'Email and password are required.' });
  }

  const user = await User.findOne({ email }).select('+passwordHash');
  const valid = user && await user.verifyPassword(password);
  if (!valid) {
    return res.status(401).json({ message: 'Incorrect email or password.' });
  }
  res.json(createSession(user));
}

export async function googleLogin(req, res) {
  const idToken = req.body?.id_token;
  if (typeof idToken !== 'string' || !idToken) {
    return res.status(400).json({ message: 'A Google ID token is required.' });
  }

  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: env.googleClientId,
    });
    payload = ticket.getPayload();
  } catch {
    return res.status(401).json({ message: 'The Google ID token is invalid or expired.' });
  }

  if (!payload?.sub || !payload.email || payload.email_verified !== true) {
    return res.status(401).json({ message: 'Google did not provide a verified email.' });
  }

  const email = normalizedEmail(payload.email);
  let user = await User.findOne({ googleId: payload.sub });
  if (!user) {
    user = await User.findOne({ email });
    if (user) {
      user.googleId = payload.sub;
      if (!user.profileImage && payload.picture) user.profileImage = payload.picture;
    } else {
      user = new User({
        fullName: payload.name?.trim() || email.split('@')[0],
        email,
        googleId: payload.sub,
        profileImage: payload.picture || null,
        role: 'viewer',
      });
    }
    await user.save();
  }
  res.json(createSession(user));
}
