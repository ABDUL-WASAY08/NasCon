import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'

/* ---------------------------------------------------------------- data */

const STACK = [
  'React + Vite',
  'Node.js + Express',
  'MongoDB',
  'Redis + BullMQ',
  'Nginx',
  'Socket.IO',
  'LLM tool-calling',
]

const WORKFLOW = [
  {
    key: 'req',
    title: 'Customer sends a request',
    body: '“Book a technician tomorrow at 5 PM.” Plain language, no forms to learn.',
    tag: 'PWA',
  },
  {
    key: 'ai',
    title: 'AI understands the request',
    body: 'Asks for missing details, identifies the service and checks real availability through approved tools.',
    tag: 'ai-service',
  },
  {
    key: 'validate',
    title: 'Booking service validates',
    body: 'Availability, conflicts, pricing and explicit customer confirmation are verified server-side.',
    tag: 'booking-service',
  },
  {
    key: 'events',
    title: 'Event-driven automation begins',
    body: 'On confirmation, booking.confirmed.v1 fires. Notification and staff-assignment jobs start.',
    tag: 'BullMQ',
  },
  {
    key: 'live',
    title: 'Chat and dashboard update live',
    body: 'The customer and assigned staff get context. Managers see the update on the operations board.',
    tag: 'Socket.IO',
  },
  {
    key: 'report',
    title: 'Background reporting runs',
    body: 'A scheduled worker compiles the seven-day metrics and delivers the report over WhatsApp.',
    tag: 'report-worker',
  },
  {
    key: 'copilot',
    title: 'The copilot turns data into decisions',
    body: 'Workload, cancellations and demand trends become answers managers can act on.',
    tag: 'analytics',
  },
]

const MODULE_GROUPS = [
  {
    id: 'core',
    label: 'A · Core management',
    note: 'The business spine',
    modules: [
      { n: '01', name: 'Identity & access', role: 'JWT + refresh rotation, RBAC, org-level access, audit logs', tag: 'auth' },
      { n: '02', name: 'Service & booking', role: 'Catalog, pricing, availability, conflicts, waitlists, invoices', tag: 'booking' },
      { n: '03', name: 'Real-time chat', role: 'Booking-linked threads, presence, typing, read receipts', tag: 'socket' },
      { n: '04', name: 'Notification service', role: 'In-app, push, email and WhatsApp delivery with retries', tag: 'notify' },
      { n: '05', name: 'Automated reporting', role: 'Scheduled reports, PDF or secure link, delivery history', tag: 'report' },
    ],
  },
  {
    id: 'ai',
    label: 'B · Advanced AI',
    note: 'The intelligence layer',
    modules: [
      { n: '06', name: 'AI booking agent', role: 'Natural language to confirmed booking via tool calling', tag: 'ai' },
      { n: '07', name: 'Management copilot', role: 'Ask operational questions, get sourced answers and actions', tag: 'ai' },
      { n: '08', name: 'Predictive analytics', role: 'Demand forecasts, cancellation spikes, resource shortages', tag: 'ml' },
      { n: '09', name: 'Knowledge assistant', role: 'Semantic search over policies and manuals with citations', tag: 'rag' },
    ],
  },
  {
    id: 'edge',
    label: 'C · Differentiators',
    note: 'What judges remember',
    modules: [
      { n: '10', name: 'Live command center', role: 'Active bookings, staff load, queue, service health, activity feed', tag: 'live' },
      { n: '11', name: 'Queue & resource optimizer', role: 'Prioritization, conflict flags, best-match staff suggestions', tag: 'opt' },
      { n: '12', name: 'Audit & compliance', role: 'Who changed what, which AI action was approved, denials', tag: 'audit' },
      { n: '13', name: 'Installable PWA', role: 'Offline shell, push, and a safe queue for reconnect sync', tag: 'pwa' },
      { n: '14', name: 'Health & performance', role: 'Latency, error rate, queue backlog and cache hit ratio', tag: 'ops' },
    ],
  },
]

const PLATFORM_TABS = [
  {
    id: 'redis',
    label: 'Redis',
    headline: 'Cache, presence, queues, rate limits',
    body: 'Redis is not just a cache here. One lifecycle per job.',
    points: [
      { k: 'API caching', v: 'Public catalog and dashboard summaries. Key service-catalog:active:v1, TTL 60s, invalidated on write.' },
      { k: 'Real-time presence', v: 'Online status and typing indicators, plus the Socket.IO adapter across instances.' },
      { k: 'Background queues', v: 'BullMQ for weekly reports, reminders and bounded retry of failed deliveries.' },
      { k: 'Rate limiting', v: 'Login attempts, AI requests per user, verification codes with expiry.' },
    ],
    note: 'Pub/Sub is not durable. Critical booking events use BullMQ or a transactional outbox so a saved booking is never separated from its event.',
  },
  {
    id: 'nginx',
    label: 'Nginx',
    headline: 'Reverse proxy and load balancer',
    body: 'One entry point in front of every service.',
    points: [
      { k: 'TLS termination', v: 'HTTPS centralized at the edge, services stay private.' },
      { k: 'Upstream balancing', v: 'Distribute traffic across API instances A and B, health-checked.' },
      { k: 'WebSocket routing', v: 'Upgrade headers and long timeouts for chat and live updates.' },
      { k: 'Proof on stage', v: 'Two instances behind Nginx, then a load test that shows the split.' },
    ],
    note: 'Nginx alone does not make an app scalable. Instance count, shared session state and database capacity do the real work.',
  },
  {
    id: 'ai',
    label: 'AI orchestration',
    headline: 'The model never holds the keys',
    body: 'The AI proposes. The backend decides.',
    points: [
      { k: 'Intent + structured output', v: 'Free text becomes validated fields: service ID, date, time, requirements.' },
      { k: 'Tool / function calling', v: 'Search services, check availability, quote pricing, request a booking.' },
      { k: 'Retrieval (optional)', v: 'Embeddings over policies and manuals, answered with source citations.' },
      { k: 'Evaluation logs', v: 'Tool-call failures, latency, model errors and estimated cost, tracked.' },
    ],
    note: 'Availability and pricing always come from the backend. Explicit user confirmation is required before any booking is created or cancelled.',
  },
  {
    id: 'events',
    label: 'Event contracts',
    headline: 'Versioned, idempotent, traceable',
    body: 'Services talk in named contracts, not each other’s internals.',
    points: [
      { k: 'Named + versioned', v: 'booking.created.v1, staff.assigned.v1, report.generated.v1 and friends.' },
      { k: 'Idempotent consumers', v: 'Events and jobs may arrive twice. Every consumer must be safe to repeat.' },
      { k: 'Outbox pattern', v: 'A booking write and its event commit together, never silently split.' },
      { k: 'Lean payloads', v: 'Event IDs, timestamps, versions and entity IDs. No needless personal data.' },
    ],
    note: 'A first release can run direct internal events plus BullMQ. A separate broker is added only when scale or independence justifies it.',
  },
]

const REPORT_STEPS = [
  'User enables the weekly report, verifies WhatsApp and sets opt-in consent.',
  'Scheduler identifies which reports are due today.',
  'Report worker pulls authorized data for the seven-day window.',
  'Metrics and a PDF or secure link are generated.',
  'Notification layer delivers through the WhatsApp Business Platform.',
  'Delivery status, provider message ID, attempts and errors are recorded.',
  'Failed sends retry under a bounded policy, then surface for review.',
]

const ROLES = [
  { name: 'Customer', detail: 'Describe the job in plain language, confirm a slot, chat with the assigned provider, get a weekly summary.', tag: 'pwa' },
  { name: 'Staff / provider', detail: 'See assigned jobs, shifts and workload. Coordinate in booking-linked chat. Mark work complete.', tag: 'staff' },
  { name: 'Manager', detail: 'Watch live operations, spot bottlenecks and overdue jobs, ask the copilot for an operational read.', tag: 'analytics' },
  { name: 'Administrator', detail: 'Own roles and permissions, the audit trail, integration health and platform monitoring.', tag: 'audit' },
]

/* ---------------------------------------------------- booking console */

const CYCLE = 8

function useReducedMotion() {
  const [reduced, setReduced] = useState(
    () => window.matchMedia('(prefers-reduced-motion: reduce)').matches,
  )
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    const update = () => setReduced(mq.matches)
    mq.addEventListener('change', update)
    return () => mq.removeEventListener('change', update)
  }, [])
  return reduced
}

function BookingConsole() {
  const reduced = useReducedMotion()
  const [step, setStep] = useState(0)

  useEffect(() => {
    if (reduced) return undefined
    const id = window.setInterval(() => {
      setStep((value) => (value + 1) % CYCLE)
    }, 1500)
    return () => window.clearInterval(id)
  }, [reduced])

  const active = reduced ? CYCLE - 1 : step
  const at = (min) => active >= min
  const progress = Math.min(100, Math.round((active / (CYCLE - 2)) * 100))

  return (
    <div
      className="panel overflow-hidden bg-linear-to-b from-surface-2 to-surface-1"
      aria-label="Illustrative booking workflow"
    >
      <div className="flex items-center gap-3 border-b border-line bg-surface-3 px-4 py-3">
        <span className="flex gap-[6px]" aria-hidden="true">
          <i className="h-[9px] w-[9px] rounded-full bg-line-strong" />
          <i className="h-[9px] w-[9px] rounded-full bg-line-strong" />
          <i className="h-[9px] w-[9px] rounded-full bg-line-strong" />
        </span>
        <span className="mono text-faint">nexus / booking-console</span>
        <span className="chip chip--ai ms-auto">
          <span className="dot" aria-hidden="true" />
          AI intake
        </span>
      </div>

      <div className="flex min-h-[456px] flex-col gap-4 p-6 max-sm:min-h-0 max-sm:p-4" aria-live="polite">
        <div className={at(1) ? 'block' : 'hidden'}>
          <span className="mono mb-1.5 inline-block text-[0.68rem] tracking-[0.12em] text-faint uppercase">
            customer
          </span>
          <p className="max-w-[46ch] rounded-[4px_16px_16px_16px] border border-line bg-surface-3 px-4 py-3 text-[0.94rem] text-ink">
            I need an AC maintenance service tomorrow after 4 PM. Find an available technician and
            book it for me.
          </p>
        </div>

        <div className={at(2) ? 'block' : 'hidden'}>
          <span className="mono mb-1.5 inline-block text-[0.68rem] tracking-[0.12em] text-ai uppercase">
            ai-service
          </span>
          <div className="flex flex-wrap gap-2">
            {[
              ['service', 'AC maintenance'],
              ['window', 'Tomorrow · 16:00+'],
              ['location', 'Zone 4'],
            ].map(([k, v]) => (
              <div
                className="flex min-w-[128px] flex-col gap-0.5 rounded-sm border border-dashed border-live-line bg-live-soft px-3 py-2"
                key={k}
              >
                <span className="mono text-[0.66rem] tracking-[0.1em] text-faint uppercase">{k}</span>
                <span className="text-[0.88rem] font-medium text-ink">{v}</span>
              </div>
            ))}
          </div>
        </div>

        <div className={at(3) ? 'block' : 'hidden'}>
          {at(4) ? (
            <p className="inline-flex items-center gap-2 text-[0.9rem] text-live">
              <span className="dot dot--pulse" aria-hidden="true" />
              2 technicians free · earliest slot 17:00
            </p>
          ) : (
            <p className="mono inline-flex items-center gap-2 text-[0.9rem] text-faint">
              checking availability…
            </p>
          )}
        </div>

        <div
          className={`rounded-md border border-line-strong bg-surface-2 p-4 ${at(5) ? 'block' : 'hidden'}`}
        >
          <div className="flex items-center justify-between gap-4">
            <div>
              <span className="mono text-[0.66rem] tracking-[0.1em] text-faint uppercase">
                proposed slot
              </span>
              <p className="mt-0.5 text-base font-semibold">Imran K. · 17:00–18:00</p>
            </div>
            <span className="mono text-[0.95rem] text-live">PKR 3,500</span>
          </div>
          <div className="mt-4 flex gap-2">
            <span className="rounded-pill border border-live bg-live px-4 py-2 text-[0.82rem] font-semibold text-[var(--color-inkdee)]">
              Confirm
            </span>
            <span className="rounded-pill border border-line-strong px-4 py-2 text-[0.82rem] font-semibold text-muted">
              Change time
            </span>
          </div>
        </div>

        <div className={at(7) ? 'block' : 'hidden'}>
          <ol className="flex flex-col gap-2">
            {['Request parsed', 'Booking confirmed', 'Technician assigned', 'Chat opened', 'Weekly report scheduled'].map(
              (label) => (
                <li className="flex items-center gap-3 text-[0.9rem] text-ink" key={label}>
                  <span
                    className="grid h-[18px] w-[18px] shrink-0 place-items-center rounded-full bg-live"
                    aria-hidden="true"
                  >
                    <svg viewBox="0 0 12 12" width="11" height="11">
                      <path
                        d="M2.5 6.4 5 8.8 9.6 3.4"
                        fill="none"
                        stroke="var(--color-inkdee)"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      />
                    </svg>
                  </span>
                  {label}
                </li>
              ),
            )}
          </ol>
          <p className="mono mt-3 text-[0.76rem] text-faint">
            → notification sent to Imran · booking BL-2041
          </p>
        </div>
      </div>

      <div className="flex items-center gap-4 border-t border-line bg-inset px-6 py-3">
        <span className="mono whitespace-nowrap text-[0.74rem] text-faint">
          {active >= 7 ? 'workflow complete' : 'processing request'}
        </span>
        <span className="h-[3px] flex-1 overflow-hidden rounded-full bg-line" aria-hidden="true">
          <i
            className="block h-full bg-live transition-[width] duration-500 ease-[cubic-bezier(0.16,1,0.3,1)]"
            style={{ width: `${progress}%` }}
          />
        </span>
      </div>
    </div>
  )
}

/* ---------------------------------------------------------- platform */

function PlatformTabs() {
  const [active, setActive] = useState(0)
  const tabRefs = useRef([])

  const onKeyDown = (event) => {
    const last = PLATFORM_TABS.length - 1
    let next
    if (event.key === 'ArrowRight') next = active === last ? 0 : active + 1
    else if (event.key === 'ArrowLeft') next = active === 0 ? last : active - 1
    else if (event.key === 'Home') next = 0
    else if (event.key === 'End') next = last
    else return
    event.preventDefault()
    setActive(next)
    tabRefs.current[next]?.focus()
  }

  const tab = PLATFORM_TABS[active]

  return (
    <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-[290px_minmax(0,1fr)]">
      <div
        className="flex flex-row gap-2 overflow-x-auto pb-2 lg:flex-col lg:overflow-visible lg:pb-0"
        role="tablist"
        aria-label="Platform subsystems"
        onKeyDown={onKeyDown}
      >
        {PLATFORM_TABS.map((item, index) => (
          <button
            key={item.id}
            ref={(node) => {
              tabRefs.current[index] = node
            }}
            type="button"
            role="tab"
            id={`tab-${item.id}`}
            aria-selected={active === index}
            aria-controls={`panel-${item.id}`}
            tabIndex={active === index ? 0 : -1}
            className={`relative flex min-w-[220px] flex-col gap-[3px] rounded-md border border-transparent p-4 pr-10 text-left transition-colors duration-200 ease-[cubic-bezier(0.16,1,0.3,1)] hover:bg-surface-1 lg:min-w-0 ${
              active === index ? 'border-line bg-surface-2' : ''
            }`}
            onClick={() => setActive(index)}
          >
            <span className="text-base font-semibold">{item.label}</span>
            <span className="text-[0.82rem] leading-[1.4] text-muted">{item.headline}</span>
            <span
              className={`absolute top-4 right-4 text-live transition-opacity duration-200 ${
                active === index ? 'opacity-100' : 'opacity-0'
              }`}
              aria-hidden="true"
            >
              →
            </span>
          </button>
        ))}
      </div>

      <div
        className="panel flex flex-col gap-6 p-[clamp(24px,3vw,40px)]"
        role="tabpanel"
        id={`panel-${tab.id}`}
        aria-labelledby={`tab-${tab.id}`}
        tabIndex={0}
      >
        <div className="flex flex-col gap-2">
          <span className="eyebrow eyebrow--live">{tab.label}</span>
          <h3>{tab.headline}</h3>
          <p className="text-[0.95rem] text-muted">{tab.body}</p>
        </div>
        <dl className="flex flex-col">
          {tab.points.map((point) => (
            <div
              key={point.k}
              className="grid grid-cols-1 gap-1 border-t border-line py-4 md:grid-cols-[190px_1fr] md:gap-4"
            >
              <dt className="mono pt-0.5 text-[0.8rem] text-live">{point.k}</dt>
              <dd className="text-[0.92rem] leading-[1.55] text-ink">{point.v}</dd>
            </div>
          ))}
        </dl>
        <p className="flex gap-3 rounded-md border border-[rgba(255,176,46,0.28)] bg-attention-soft p-4 text-[0.88rem] leading-[1.55] text-ink">
          <span className="mono shrink-0 pt-0.5 text-[0.68rem] tracking-[0.12em] text-attention uppercase">
            note
          </span>
          {tab.note}
        </p>
      </div>
    </div>
  )
}

/* ------------------------------------------------------------- page */

export default function Home() {
  return (
    <>
      <section className="pt-[clamp(48px,7vw,88px)] pb-[clamp(48px,6vw,80px)]">
        <div className="container grid grid-cols-1 items-center gap-[clamp(32px,6vw,72px)] lg:grid-cols-[minmax(0,1.05fr)_minmax(0,1fr)]">
          <div className="flex flex-col items-start gap-6">
            <span className="chip chip--live self-start">
              <span className="dot dot--pulse" aria-hidden="true" />
              AI-powered service operations
            </span>
            <h1 className="max-w-full sm:max-w-[15ch]">
              Run every service request from a single live console
            </h1>
            <p className="lede max-w-[46ch]">
              NEXUS turns a plain-language request into a confirmed booking, an assigned
              technician, a live chat and a scheduled report. One connected workflow, not a pile of
              CRUD screens.
            </p>
            <div className="mt-2 flex flex-wrap gap-3">
              <Link to="/auth?mode=signup" className="btn btn--primary btn--lg">
                Open the console
              </Link>
              <Link to="/about" className="btn btn--ghost btn--lg">
                See the architecture
              </Link>
            </div>
            <dl className="mt-4 flex w-full flex-wrap gap-6 border-t border-line pt-6 sm:gap-8">
              <div>
                <dt className="mono text-[1.6rem] font-semibold text-live">14</dt>
                <dd className="mt-0.5 text-[0.82rem] text-muted">product modules</dd>
              </div>
              <div>
                <dt className="mono text-[1.6rem] font-semibold text-live">14</dt>
                <dd className="mt-0.5 text-[0.82rem] text-muted">backend services</dd>
              </div>
              <div>
                <dt className="mono text-[1.6rem] font-semibold text-live">1</dt>
                <dd className="mt-0.5 text-[0.82rem] text-muted">traceable workflow</dd>
              </div>
            </dl>
          </div>

          <div className="flex max-w-[560px] flex-col gap-3 lg:max-w-none">
            <BookingConsole />
            <p className="mono text-right text-faint">Illustrative UI · sample data</p>
          </div>
        </div>

        <div className="container mt-[clamp(40px,5vw,64px)] flex flex-col gap-4 border-t border-line pt-6">
          <span className="eyebrow">Runs on</span>
          <ul className="flex flex-wrap gap-x-6 gap-y-2">
            {STACK.map((item) => (
              <li
                key={item}
                className="mono relative pl-4 text-[0.8rem] text-muted before:absolute before:top-1/2 before:left-0 before:h-[5px] before:w-[5px] before:-translate-y-1/2 before:rounded-full before:bg-live before:content-['']"
              >
                {item}
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="section" id="workflow">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">One request · complete automation</span>
            <h2>Seven steps, fully connected</h2>
            <p className="lede">
              This is the part that separates a platform from a prototype. Every module below
              participates in the same request, and every step is traceable.
            </p>
          </div>

          <ol className="relative flex flex-col gap-8 before:absolute before:top-3 before:bottom-3 before:left-4 before:w-px before:bg-linear-to-b before:from-line-strong before:to-line before:content-[''] sm:before:left-[19px]">
            {WORKFLOW.map((step, index) => (
              <li
                className="relative grid grid-cols-[32px_1fr] gap-4 sm:grid-cols-[40px_1fr] sm:gap-6"
                key={step.key}
              >
                <div
                  className="grid h-8 w-8 place-items-center rounded-full border border-line-strong bg-surface-2 text-live sm:h-10 sm:w-10"
                  aria-hidden="true"
                >
                  <span className="mono">{String(index + 1).padStart(2, '0')}</span>
                </div>
                <div className="pt-1">
                  <div className="mb-2 flex flex-wrap items-baseline justify-between gap-4">
                    <h3>{step.title}</h3>
                    <span className="chip">{step.tag}</span>
                  </div>
                  <p className="max-w-[68ch] text-[0.96rem] text-muted">{step.body}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </section>

      <section className="section section--tight" id="modules">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">The module roster</span>
            <h2>Fourteen modules, three tiers</h2>
            <p className="lede">
              Core operations, an intelligence layer, and the differentiators that make the
              demonstration memorable.
            </p>
          </div>

          <div className="flex flex-col gap-12">
            {MODULE_GROUPS.map((group) => (
              <div key={group.id}>
                <div className="flex flex-wrap items-baseline justify-between gap-4 border-b border-line-strong pb-3">
                  <h3>{group.label}</h3>
                  <span className="mono text-[0.76rem] text-faint">{group.note}</span>
                </div>
                <ul className="grid grid-cols-1 gap-x-12 md:grid-cols-2">
                  {group.modules.map((module) => (
                    <li
                      className="group grid grid-cols-[34px_1fr_auto] items-center gap-4 border-b border-line py-4 transition-colors duration-200 ease-[cubic-bezier(0.16,1,0.3,1)] hover:bg-linear-to-r hover:from-surface-2 hover:to-transparent"
                      key={module.n}
                    >
                      <span className="mono text-[0.78rem] text-faint">{module.n}</span>
                      <div className="flex min-w-0 flex-col gap-0.5">
                        <span className="text-[0.98rem] font-semibold">{module.name}</span>
                        <span className="text-[0.85rem] leading-[1.45] text-muted">
                          {module.role}
                        </span>
                      </div>
                      <span className="mono rounded-pill border border-line px-[9px] py-[3px] text-[0.7rem] whitespace-nowrap text-faint group-hover:border-live-line group-hover:text-live">
                        {module.tag}
                      </span>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section" id="platform">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Platform engineering</span>
            <h2>The parts judges actually ask about</h2>
            <p className="lede">
              Redis, Nginx, AI orchestration and event contracts. Each has a defined data lifecycle
              and a defined failure mode.
            </p>
          </div>
          <PlatformTabs />
        </div>
      </section>

      <section className="section section--tight" id="reports">
        <div className="container grid grid-cols-1 items-center gap-[clamp(32px,5vw,72px)] lg:grid-cols-[minmax(0,1.05fr)_minmax(0,0.95fr)]">
          <div className="flex flex-col gap-4">
            <span className="eyebrow eyebrow--live">Signature feature</span>
            <h2>The seven-day report that sends itself</h2>
            <p className="lede">
              Scheduling, background processing, report generation and a third-party messaging API,
              all in one observable flow. Delivery status and retries are recorded, not assumed.
            </p>
            <ol className="mt-3 flex flex-col gap-3">
              {REPORT_STEPS.map((step, index) => (
                <li className="grid grid-cols-[30px_1fr] gap-3 text-[0.92rem] text-muted" key={step}>
                  <span className="mono pt-[3px] text-[0.74rem] text-live">
                    {String(index + 1).padStart(2, '0')}
                  </span>
                  <span>{step}</span>
                </li>
              ))}
            </ol>
            <p className="mt-2 border-l-2 border-line-strong pl-4 text-[0.82rem] text-faint">
              WhatsApp automation requires approved Business Platform access, verified opt-in and
              template compliance. Private reports ship as secure, expiring links.
            </p>
          </div>

          <aside className="panel flex flex-col gap-4 p-6" aria-label="Illustrative weekly report">
            <div className="flex items-center justify-between gap-3 text-faint">
              <span className="mono">weekly report · 7 days</span>
              <span className="chip chip--live">delivered</span>
            </div>
            <dl className="grid grid-cols-2 gap-3 sm:gap-4">
              {[
                ['Bookings', '128'],
                ['Completed', '119'],
                ['Cancellations', '09'],
                ['Avg response', '4m 12s'],
              ].map(([k, v]) => (
                <div key={k}>
                  <dt className="mono text-[0.72rem] tracking-[0.08em] text-faint uppercase">{k}</dt>
                  <dd className="mt-0.5 font-display text-[1.7rem] font-semibold text-ink">{v}</dd>
                </div>
              ))}
            </dl>
            <div className="flex flex-col gap-2 border-t border-line pt-3">
              {[
                ['queued', '21:00'],
                ['generated', '21:00'],
                ['sent', '21:01'],
                ['delivered', '21:01'],
              ].map(([state, time]) => (
                <div className="flex items-center justify-between text-[0.84rem]" key={state}>
                  <span className="inline-flex items-center gap-2 text-live">
                    <span className="dot" aria-hidden="true" />
                    {state}
                  </span>
                  <span className="mono text-faint">{time}</span>
                </div>
              ))}
            </div>
            <p className="mono text-[0.72rem] text-faint">Illustrative sample · not a live delivery</p>
          </aside>
        </div>
      </section>

      <section className="section section--tight" id="roles">
        <div className="container">
          <div className="section-head">
            <span className="eyebrow">Built for the whole floor</span>
            <h2>Four roles, one source of truth</h2>
          </div>
          <ul className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {ROLES.map((role) => (
              <li className="flex flex-col gap-2 border-t border-line-strong pt-4" key={role.name}>
                <span className="mono text-[0.7rem] tracking-[0.08em] text-live">{role.tag}</span>
                <h3>{role.name}</h3>
                <p className="text-[0.9rem] leading-[1.55] text-muted">{role.detail}</p>
              </li>
            ))}
          </ul>
        </div>
      </section>

      <section className="cta">
        <div className="container cta__inner panel">
          <div className="cta__copy">
            <span className="eyebrow eyebrow--live">Ready when you are</span>
            <h2>Open the console and run a request end to end</h2>
            <p className="lede">
              Sign in as a customer, provider, manager or admin and watch the modules move together.
            </p>
          </div>
          <div className="cta__actions">
            <Link to="/auth?mode=signup" className="btn btn--primary btn--lg">
              Create an account
            </Link>
            <Link to="/auth" className="btn btn--ghost btn--lg">
              Sign in
            </Link>
          </div>
        </div>
      </section>
    </>
  )
}
