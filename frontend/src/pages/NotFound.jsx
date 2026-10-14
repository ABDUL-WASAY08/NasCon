import { Link } from 'react-router-dom'

export default function NotFound() {
  return (
    <section className="container py-24 md:py-32">
      <div className="flex max-w-[60ch] flex-col gap-5">
        <span className="eyebrow">Error 404</span>
        <h1>This route isn&apos;t scheduled</h1>
        <p className="lede">
          The page you requested doesn&apos;t exist in the console. Check the address, or head back
          to the operations overview.
        </p>
        <div className="flex flex-wrap gap-3">
          <Link to="/" className="btn btn--primary">
            Back to home
          </Link>
          <Link to="/auth" className="btn btn--ghost">
            Sign in
          </Link>
        </div>
      </div>
    </section>
  )
}
