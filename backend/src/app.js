import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { env } from './config/env.js';
import { errorHandler, notFound } from './middlewares/errorHandler.js';
import authRoutes from './routes/authRoutes.js';
import sampleDataRoutes from './routes/sampleDataRoutes.js';
import userRoutes from './routes/userRoutes.js';

export function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({
    origin(origin, callback) {
      if (!origin || env.corsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }
      const error = new Error('This origin is not allowed by CORS.');
      error.statusCode = 403;
      callback(error);
    },
  }));
  app.use(express.json({ limit: '1mb' }));
  app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));
  app.use('/api/auth', authRoutes);
  app.use('/api/user', userRoutes);
  app.use('/api', sampleDataRoutes);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
