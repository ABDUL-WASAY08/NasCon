import mongoose from 'mongoose';

export async function connectDatabase(uri) {
  mongoose.connection.on('error', (error) => {
    console.error('MongoDB connection error:', error.message);
  });
  mongoose.connection.on('disconnected', () => {
    console.warn('MongoDB disconnected.');
  });

  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 10_000,
      connectTimeoutMS: 10_000,
      maxPoolSize: 10,
      autoIndex: process.env.NODE_ENV !== 'production',
    });
    console.info(`MongoDB connected (${mongoose.connection.name}).`);
  } catch (error) {
    console.error('Unable to connect to MongoDB:', error.message);
    throw error;
  }
}
