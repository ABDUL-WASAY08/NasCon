import mongoose from 'mongoose'
import { env } from './env.js'

mongoose.set('strictQuery', true)
// Fail fast with a clear error instead of buffering queries for 10s while
// the cluster is unreachable (e.g. the IP is not on the Atlas allowlist).
mongoose.set('bufferCommands', false)

export async function connectDb() {
  await mongoose.connect(env.mongoUri, {
    dbName: env.mongoDbName,
    serverSelectionTimeoutMS: 20000,
    maxPoolSize: 10,
  })
  const { name, host } = mongoose.connection
  console.log(`[db] connected to "${name}" at ${host}`)
  return mongoose.connection
}

export async function disconnectDb() {
  await mongoose.disconnect()
}

export function dbState() {
  return ['disconnected', 'connected', 'connecting', 'disconnecting'][mongoose.connection.readyState] ?? 'unknown'
}
