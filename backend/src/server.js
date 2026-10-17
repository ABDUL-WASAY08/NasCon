import { createServer } from 'node:http';
import { createApp } from './app.js';
import { connectDatabase } from './config/db.js';
import { env, validateEnv } from './config/env.js';

validateEnv();
await connectDatabase(env.mongoUri);

const server = createServer(createApp());
server.listen(env.port, () => {
  console.info(`NaSCon API listening on port ${env.port}.`);
});

async function shutdown(signal) {
  console.info(`${signal} received; shutting down.`);
  server.close(async (error) => {
    if (error) {
      console.error('HTTP server shutdown failed:', error);
      process.exitCode = 1;
    }
    const mongoose = await import('mongoose');
    await mongoose.default.disconnect();
  });
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
