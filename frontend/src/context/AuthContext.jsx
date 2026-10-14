import { useCallback, useEffect, useMemo, useState } from 'react'
import { api, setAccessToken, refreshSession } from '../lib/api-client.js'
import { AuthContext } from './auth-context.js'

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [capabilities, setCapabilities] = useState([])
  const [status, setStatus] = useState('loading')

  const applySession = useCallback((session) => {
    setAccessToken(session.accessToken)
    setUser(session.user)
    setCapabilities(session.capabilities || [])
  }, [])

  useEffect(() => {
    let active = true
    refreshSession().then((session) => {
      if (!active) return
      if (session) {
        applySession(session)
        setStatus('authed')
      } else {
        setStatus('guest')
      }
    })
    return () => {
      active = false
    }
  }, [applySession])

  const signIn = useCallback(
    (session) => {
      applySession(session)
      setStatus('authed')
    },
    [applySession],
  )

  const signOut = useCallback(async () => {
    try {
      await api.logout()
    } catch {
      // ignore — clearing local state is what matters
    }
    setAccessToken(null)
    setUser(null)
    setCapabilities([])
    setStatus('guest')
  }, [])

  const refresh = useCallback(async () => {
    const session = await refreshSession()
    if (!session) return null
    applySession(session)
    setUser(session.user)
    setCapabilities(session.capabilities || [])
    return session
  }, [applySession])

  const hasCapability = useCallback(
    (capability) => capabilities.includes(capability),
    [capabilities],
  )

  const value = useMemo(
    () => ({ user, capabilities, status, signIn, signOut, refresh, hasCapability }),
    [user, capabilities, status, signIn, signOut, refresh, hasCapability],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
