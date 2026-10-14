import { useEffect } from 'react'
import { Routes, Route, Outlet, Navigate, useLocation } from 'react-router-dom'
import SiteHeader from '../components/SiteHeader.jsx'
import SiteFooter from '../components/SiteFooter.jsx'
import ProtectedRoute from '../components/ProtectedRoute.jsx'
import { AuthProvider } from '../context/AuthContext.jsx'
import Home from '../pages/Home.jsx'
import About from '../pages/About.jsx'
import Auth from '../pages/Auth.jsx'
import AuthCallback from '../pages/AuthCallback.jsx'
import Console from '../pages/Console.jsx'
import NotFound from '../pages/NotFound.jsx'

function ScrollToTop() {
  const { pathname, hash } = useLocation()

  useEffect(() => {
    if (hash) {
      const target = document.querySelector(hash)
      if (target) {
        target.scrollIntoView({ block: 'start' })
        return
      }
    }
    window.scrollTo({ top: 0, left: 0, behavior: 'auto' })
  }, [pathname, hash])

  return null
}

function SiteLayout() {
  return (
    <>
      <SiteHeader />
      <main id="content" className="flex-1 min-w-0">
        <Outlet />
      </main>
      <SiteFooter />
    </>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <a className="skip-link" href="#content">
        Skip to content
      </a>
      <ScrollToTop />
      <Routes>
        <Route element={<SiteLayout />}>
          <Route index element={<Home />} />
          <Route path="about" element={<About />} />
          <Route
            path="console"
            element={
              <ProtectedRoute>
                <Console />
              </ProtectedRoute>
            }
          />
          <Route
            path="console/admin"
            element={
              <ProtectedRoute roles={['admin']}>
                <Console />
              </ProtectedRoute>
            }
          />
          <Route path="dashboard" element={<Navigate to="/console" replace />} />
          <Route path="*" element={<NotFound />} />
        </Route>
        <Route path="auth" element={<Auth />} />
        <Route path="auth/callback" element={<AuthCallback />} />
      </Routes>
    </AuthProvider>
  )
}
