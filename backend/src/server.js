import app from './app.js'
import { connectDb } from './config/db.js'
import { env } from './config/env.js'

const RETRY_MS = 15000

async function ensureDb(attempt = 1) {
  try {
    await connectDb()
  } catch (error) {
    console.error(`[db] connection failed (attempt ${attempt}): ${error.message}`)
    console.error('[db] If this is MongoDB Atlas, add your current IP to the allowlist:')
    console.error('[db]   Atlas → your cluster → Network Access → Add IP Address')
    console.error(`[db]   Your public IP is the one shown at https://api.ipify.org`)
    console.error(`[db] Retrying in ${RETRY_MS / 1000}s. The API stays up so /health keeps responding.`)
    setTimeout(() => ensureDb(attempt + 1), RETRY_MS)
  }
}

// Listen first so a database outage never makes the whole API unreachable.
app.listen(env.port, () => {
  console.log(`[api] NEXUS backend listening on http://localhost:${env.port}`)
  console.log(`[api] CORS origin: ${env.clientUrl}`)
  console.log(`[api] Google callback: ${env.google.callbackUrl}`)
})

ensureDb()

process.on('unhandledRejection', (reason) => {
  console.error('[unhandledRejection]', reason)
})
