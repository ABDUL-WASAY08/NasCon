import 'dotenv/config';

const required = [
  'JWT_SECRET',
  'MONGODB_URI',
  'GOOGLE_CLIENT_ID',
  'CLOUDINARY_CLOUD_NAME',
  'CLOUDINARY_API_KEY',
  'CLOUDINARY_API_SECRET',
];

export function validateEnv() {
  const missing = required.filter((key) => !process.env[key]?.trim());
  if (missing.length) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
  const port = Number.parseInt(process.env.PORT || '5000', 10);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }
  if (process.env.JWT_SECRET.length < 32) {
    throw new Error('JWT_SECRET must be at least 32 characters long.');
  }
  if (process.env.MONGODB_URI.includes('<') || process.env.MONGODB_URI.includes('>')) {
    throw new Error('MONGODB_URI still contains template placeholders.');
  }
  const mongoProtocol = new URL(process.env.MONGODB_URI).protocol;
  if (!['mongodb:', 'mongodb+srv:'].includes(mongoProtocol)) {
    throw new Error('MONGODB_URI must use mongodb:// or mongodb+srv://.');
  }
}

export const env = {
  get port() {
    return Number.parseInt(process.env.PORT || '5000', 10);
  },
  get nodeEnv() {
    return process.env.NODE_ENV || 'development';
  },
  get jwtSecret() {
    return process.env.JWT_SECRET;
  },
  get jwtExpiresIn() {
    return process.env.JWT_EXPIRES_IN || '1d';
  },
  get mongoUri() {
    return process.env.MONGODB_URI;
  },
  get googleClientId() {
    return process.env.GOOGLE_CLIENT_ID;
  },
  get cloudinary() {
    return {
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      apiSecret: process.env.CLOUDINARY_API_SECRET,
    };
  },
  get corsOrigins() {
    return (process.env.CORS_ORIGINS || '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean);
  },
};
