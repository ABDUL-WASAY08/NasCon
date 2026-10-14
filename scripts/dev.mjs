import { spawn } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)))
const isWindows = process.platform === 'win32'

const TARGETS = [
  { name: 'backend ', color: '\x1b[32m', cwd: path.join(root, 'backend'), command: 'npm run dev' },
  { name: 'frontend', color: '\x1b[36m', cwd: path.join(root, 'frontend'), command: 'npm run dev' },
]

const children = []

for (const target of TARGETS) {
  const child = spawn(target.command, {
    cwd: target.cwd,
    shell: true,
    env: process.env,
  })
  children.push({ child, target })

  const prefix = `${target.color}[${target.name}]\x1b[0m `

  const pipe = (stream) => {
    stream.setEncoding('utf8')
    let buffer = ''
    stream.on('data', (chunk) => {
      buffer += chunk
      const lines = buffer.split(/\r?\n/)
      buffer = lines.pop()
      for (const line of lines) {
        if (line.trim()) process.stdout.write(prefix + line + '\n')
      }
    })
  }

  pipe(child.stdout)
  pipe(child.stderr)

  child.on('exit', (code) => {
    process.stdout.write(`${prefix}process exited with code ${code}\n`)
  })
}

let shuttingDown = false
function shutdown(signal) {
  if (shuttingDown) return
  shuttingDown = true
  process.stdout.write(`\n[dev] ${signal} received — stopping servers\n`)
  for (const { child } of children) {
    if (!child.pid) continue
    if (isWindows) {
      spawn('taskkill', ['/pid', String(child.pid), '/T', '/F'], { stdio: 'ignore' })
    } else {
      child.kill('SIGTERM')
    }
  }
  setTimeout(() => process.exit(0), 800)
}

process.on('SIGINT', () => shutdown('SIGINT'))
process.on('SIGTERM', () => shutdown('SIGTERM'))
