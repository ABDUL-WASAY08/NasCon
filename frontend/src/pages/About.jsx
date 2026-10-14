import { Link } from 'react-router-dom'

const ARCHITECTURE = [
  {
    layer: 'Client',
    tag: 'PWA',
    items: ['Mobile / desktop PWA', 'React + service worker', 'Responsive shell'],
    link: 'HTTPS · WebSocket',
  },
  {
    layer: 'Edge',
    tag: 'Nginx',
    items: ['Reverse proxy', 'TLS termination', 'Load balancer · health checks'],
    link: 'route forward',
  },
  {
    layer: 'Entry',
    tag: 'api-gateway',
    items: ['Route forwarding', 'Shared request policy', 'Rate limits'],
    link: 'fan-out',
  },
  {
    layer: 'Services',
    tag: 'business logic',
    items: [
      'auth',
      'user',
      'organization',
      'service-catalog',
      'booking',
      'staff',
      'chat',
      'notification',
      'report',
      'ai',
      'analytics',
      'audit',
      'integration',
    ],
    link: 'jobs · events',
  },
  {
    layer: 'Data',
    tag: 'state',
    items: ['MongoDB · persistent data', 'Redis · cache, presence, queues'],
    link: 'workers',
  },
  {
    layer: 'Background',
    tag: 'workers',
    items: ['report-worker', 'notification-worker', 'booking-reminder-worker', 'ai-job-worker'],
    link: 'provider calls',
  },
  {
    layer: 'External',
    tag: 'adapters',
    items: ['LLM provider', 'WhatsApp Business Platform', 'Email provider'],
    link: null,
  },
]

const PRINCIPLES = [
  'Every service owns a clear responsibility and a versioned API or event contract.',
  'The PWA is separate from backend services and never holds provider secrets.',
  'Shared packages carry contracts and utilities, not business logic.',
  'External providers sit behind dedicated adapters so they can be swapped.',
  'Background jobs handle work that must not block an HTTP request.',
  'Retries, timeouts and duplicate events are designed for, not discovered in production.',
]

const SERVICES = [
  ['api-gateway', 'Backend entry point, routing and shared request policies'],
  ['auth-service', 'Authentication, sessions and tokens, roles and access policies'],
  ['user-service', 'Profiles, preferences and account settings'],
  ['organization-service', 'Organizations, teams and tenant isolation'],
  ['service-catalog-service', 'Services, categories, prices and service rules'],
  ['booking-service', 'Booking lifecycle, availability and conflict prevention'],
  ['staff-service', 'Staff skills, shifts, availability and assignment'],
  ['chat-service', 'Conversations, messages, history and real-time presence'],
  ['notification-service', 'Notification orchestration, preferences and delivery tracking'],
  ['report-service', 'Report schedules, metrics, generation and history'],
  ['ai-service', 'Model integration, prompts, tool calling and AI safety'],
  ['analytics-service', 'KPIs, aggregations, trends and forecasting'],
  ['audit-service', 'Traceable business and security events'],
  ['integration-service', 'WhatsApp, email and other external provider adapters'],
]

const SECURITY = [
  {
    title: 'Authentication & authorization',
    body: 'JWT or secure sessions, refresh rotation, role-based access, org isolation, and permission checks on every protected operation.',
  },
  {
    title: 'Booking consistency',
    body: 'Server-side availability at write time, unique constraints or locking to prevent double booking, and idempotency keys on retryable creates.',
  },
  {
    title: 'Notification reliability',
    body: 'Provider message IDs tracked, transient failures retried with bounded backoff, duplicates deduped, permanent failures made visible.',
  },
  {
    title: 'Secrets & privacy',
    body: 'Credentials in the environment or a secret manager, never in the PWA bundle. No passwords, tokens or private message content in logs.',
  },
  {
    title: 'Observability',
    body: 'Structured logs with correlation IDs, plus latency, error rate, queue backlog, cache hit ratio and AI cost. Health endpoints that leak nothing.',
  },
  {
    title: 'Honest PWA behaviour',
    body: 'A booking is never shown as confirmed until the server accepts it. Offline sync queues only safe, retryable actions.',
  },
]

const ROADMAP = [
  {
    phase: 'Phase 1',
    title: 'Working foundation',
    items: ['Monorepo and environment setup', 'Responsive PWA shell and navigation', 'Authentication and role-based access', 'Service catalog and booking lifecycle', 'Nginx routing and initial Redis caching'],
  },
  {
    phase: 'Phase 2',
    title: 'Real-time operations',
    items: ['Socket.IO chat with persisted messages', 'In-app real-time notifications', 'Staff assignment and manager dashboard', 'Event contracts and background jobs'],
  },
  {
    phase: 'Phase 3',
    title: 'AI and automated reports',
    items: ['LLM integration through ai-service', 'Tool calling for search and availability', 'Confirmation and permission workflow', 'Weekly report scheduler, PDF and WhatsApp delivery'],
  },
  {
    phase: 'Phase 4',
    title: 'Differentiators',
    items: ['AI management copilot', 'Forecasting or document RAG', 'Health and performance monitoring', 'Docker Compose with multiple API instances behind Nginx'],
  },
]

const TECH = [
  ['PWA frontend', 'React + Vite', 'Responsive interface and client logic'],
  ['PWA capabilities', 'Web App Manifest + service worker', 'Installation and selected offline behaviour'],
  ['Backend', 'Node.js + Express', 'APIs and business logic'],
  ['Database', 'MongoDB', 'Persistent application data'],
  ['Cache / queues', 'Redis + BullMQ', 'Cache, job processing and retries'],
  ['Real-time', 'Socket.IO', 'Chat and live updates'],
  ['Reverse proxy / LB', 'Nginx', 'Routing and load balancing'],
  ['AI', 'LLM API or local model', 'Conversation, tool calling and summaries'],
  ['Document search', 'Embeddings + vector search', 'Optional RAG and semantic retrieval'],
  ['Deployment', 'Docker Compose', 'Repeatable local deployment'],
]

export default function About() {
  return (
    <>
      <section className="pt-[clamp(48px,7vw,88px)] pb-[clamp(32px,5vw,56px)]">
        <div className="container grid grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)] items-start gap-[clamp(32px,6vw,72px)] max-[1020px]:grid-cols-1">
          <div className="flex flex-col gap-4">
            <span className="eyebrow">About NEXUS</span>
            <h1 className="max-w-[18ch] max-[560px]:max-w-full">One platform where a service request becomes a finished job</h1>
          </div>
          <div className="flex flex-col gap-4 border-t border-line-strong pt-3">
            <p className="lede text-[0.98rem] leading-[1.65]">
              NEXUS is an AI-powered, real-time service operations and management platform. It
              brings booking, staff coordination, live communication, automated reporting and
              analytics into a single system, with AI handling the language and the backend
              handling the truth.
            </p>
            <p className="max-w-[60ch] text-[0.98rem] leading-[1.65] text-muted">
              It is designed as a service-based system: a separate installable PWA in front, clearly
              bounded backend services behind it, Redis for caching and asynchronous processing, and
              Nginx for routing and load balancing. The goal is not a collection of unrelated CRUD
              screens, but one traceable workflow where the modules genuinely depend on each other.
            </p>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container">
          <blockquote className="flex flex-col gap-6 border-l-2 border-live pl-[clamp(20px,3vw,40px)]">
            <p className="max-w-[34ch] font-display text-[clamp(1.4rem,3vw,2.15rem)] font-medium leading-[1.28] tracking-[-0.02em] text-ink">
              “I need an AC maintenance service tomorrow after 4 PM. Find an available technician
              and book it.”
            </p>
            <footer className="mono max-w-[60ch] text-[0.8rem] leading-[1.6] text-faint">
              One sentence in → parsed request, availability check, confirmed booking, assigned
              staff, live chat, scheduled report.
            </footer>
          </blockquote>
        </div>
      </section>

      <section className="section" id="architecture">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Architecture</span>
            <h2>A logical stack, not a promise of fourteen servers on day one</h2>
            <p className="lede">
              Each layer has one job. The platform can start as a modular application with clear
              boundaries, then split services out as load and ownership demand it.
            </p>
          </div>

          <div className="flex flex-col">
            {ARCHITECTURE.map((layer) => (
              <div key={layer.layer}>
                <div className="panel flex flex-col gap-3 px-6 py-4">
                  <div className="flex items-baseline justify-between gap-4">
                    <span className="font-display text-[1.05rem] font-semibold">{layer.layer}</span>
                    <span className="mono text-[0.72rem] text-faint">{layer.tag}</span>
                  </div>
                  <ul className="flex flex-wrap gap-2">
                    {layer.items.map((item) => (
                      <li key={item} className="mono rounded-pill border border-line bg-inset px-[11px] py-1 text-[0.74rem] text-muted">
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
                {layer.link && (
                  <div className="my-1.5 ml-[26px] flex items-center gap-[10px] text-faint" aria-hidden="true">
                    <span className="h-5 w-px bg-line-strong" />
                    <span className="mono text-[0.68rem] uppercase tracking-[0.12em]">{layer.link}</span>
                  </div>
                )}
              </div>
            ))}
          </div>

          <div className="mt-12 border-t border-line pt-8">
            <div>
              <span className="eyebrow">Architecture principles</span>
            </div>
            <ul className="mt-4 grid grid-cols-2 gap-x-12 gap-y-4 max-[760px]:grid-cols-1">
              {PRINCIPLES.map((item, index) => (
                <li key={item} className="grid grid-cols-[32px_1fr] gap-3 text-[0.92rem] leading-[1.55] text-muted">
                  <span className="mono pt-[3px] text-[0.74rem] text-live">{String(index + 1).padStart(2, '0')}</span>
                  <span>{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      <section className="section section--tight" id="services">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Service responsibilities</span>
            <h2>Fourteen services, no overlap</h2>
            <p className="lede">
              Separate folders do not make a microservices system. Clear ownership and API contracts
              do. The boundary that matters most: the AI service never writes bookings directly. It
              calls the booking service, which checks availability, permission and confirmation.
            </p>
          </div>

          <div className="border-t border-line-strong">
            {SERVICES.map(([name, role]) => (
              <div
                className="grid grid-cols-[260px_1fr] gap-6 border-b border-line px-2 py-4 transition-colors duration-200 ease-[cubic-bezier(0.16,1,0.3,1)] hover:bg-surface-1 max-[760px]:grid-cols-1 max-[760px]:gap-1"
                key={name}
              >
                <span className="mono text-[0.82rem] text-live">{name}</span>
                <span className="text-[0.92rem] leading-[1.5] text-muted">{role}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section" id="security">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Security & reliability</span>
            <h2>Trust is an engineering property, not a login screen</h2>
          </div>
          <ul className="grid grid-cols-3 gap-6 max-[1020px]:grid-cols-2 max-[560px]:grid-cols-1">
            {SECURITY.map((item) => (
              <li className="flex flex-col gap-2 border-t border-line-strong pt-4" key={item.title}>
                <h3 className="text-[1.02rem]">{item.title}</h3>
                <p className="text-[0.9rem] leading-[1.55] text-muted">{item.body}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section section--tight" id="roadmap">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Implementation roadmap</span>
            <h2>Built in four phases, reliable first</h2>
            <p className="lede">
              Every phase ends in something demonstrable. A dependable end-to-end workflow beats
              every optional feature half-built.
            </p>
          </div>
          <ol className="grid grid-cols-4 gap-6 max-[1020px]:grid-cols-2 max-[560px]:grid-cols-1">
            {ROADMAP.map((phase) => (
              <li className="flex flex-col gap-4 border-t-2 border-live-line pt-4" key={phase.phase}>
                <div className="flex flex-col gap-1">
                  <span className="mono text-[0.72rem] tracking-[0.08em] text-live">{phase.phase}</span>
                  <h3>{phase.title}</h3>
                </div>
                <ul className="flex flex-col gap-2">
                  {phase.items.map((item) => (
                    <li
                      className="relative pl-4 text-[0.88rem] leading-[1.5] text-muted before:absolute before:left-0 before:top-[0.62em] before:h-px before:w-1.5 before:bg-faint before:content-['']"
                      key={item}
                    >
                      {item}
                    </li>
                  ))}
                </ul>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="section section--tight" id="technology">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Technology summary</span>
            <h2>What it is built from</h2>
          </div>
          <div className="overflow-x-auto rounded-md border border-line bg-surface-1">
            <table className="w-full min-w-[560px] border-collapse">
              <caption className="sr-only">Technology choices by layer</caption>
              <thead>
                <tr>
                  <th className="border-b border-line bg-surface-2 px-6 py-4 text-left align-top font-mono text-[0.72rem] font-medium uppercase tracking-[0.1em] text-faint" scope="col">Layer</th>
                  <th className="border-b border-line bg-surface-2 px-6 py-4 text-left align-top font-mono text-[0.72rem] font-medium uppercase tracking-[0.1em] text-faint" scope="col">Suggested technology</th>
                  <th className="border-b border-line bg-surface-2 px-6 py-4 text-left align-top font-mono text-[0.72rem] font-medium uppercase tracking-[0.1em] text-faint" scope="col">Purpose</th>
                </tr>
              </thead>
              <tbody className="[&>tr:last-child>*]:border-b-0">
                {TECH.map(([layer, tech, purpose]) => (
                  <tr className="hover:bg-surface-2" key={layer}>
                    <th className="whitespace-nowrap border-b border-line px-6 py-4 text-left align-top text-[0.92rem] font-semibold" scope="row">{layer}</th>
                    <td className="mono border-b border-line px-6 py-4 text-left align-top text-[0.82rem] text-ink">{tech}</td>
                    <td className="border-b border-line px-6 py-4 text-left align-top text-[0.9rem] text-muted">{purpose}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section className="cta">
        <div className="container cta__inner panel">
          <div className="cta__copy">
            <span className="eyebrow eyebrow--live">The definition</span>
            <h2>Intelligent booking, coordination and reporting in one system</h2>
            <p className="lede">
              Its strongest differentiator is integration: AI, backend services, Redis, real-time
              events, reporting and PWA, all reachable through one request and one traceable
              workflow.
            </p>
          </div>
          <div className="cta__actions">
            <Link to="/auth?mode=signup" className="btn btn--primary btn--lg">
              Open the console
            </Link>
            <Link to="/" className="btn btn--ghost btn--lg">
              Back to home
            </Link>
          </div>
        </div>
      </section>
    </>
  )
}
