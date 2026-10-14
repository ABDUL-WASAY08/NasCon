const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000'

let accessToken = null
let refreshInFlight = null

export function setAccessToken(token) {
  accessToken = token || null
}

export function getAccessToken() {
  return accessToken
}

async function parse(response) {
  const text = await response.text()
  if (!text) return {}
  try {
    return JSON.parse(text)
  } catch {
    return {}
  }
}

async function request(path, { method = 'GET', body, auth = true, retry = true } = {}) {
  const headers = {}
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  if (auth && accessToken) headers.Authorization = `Bearer ${accessToken}`

  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    credentials: 'include',
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  if (response.status === 401 && auth && retry && path !== '/api/auth/refresh') {
    const session = await refreshSession()
    if (session) return request(path, { method, body, auth, retry: false })
  }

  const data = await parse(response)

  if (!response.ok) {
    const error = new Error(data?.error?.message || 'Request failed')
    error.status = response.status
    error.code = data?.error?.code
    error.issues = data?.error?.issues
    throw error
  }

  return data
}

export async function refreshSession() {
  if (!refreshInFlight) {
    refreshInFlight = fetch(`${BASE_URL}/api/auth/refresh`, {
      method: 'POST',
      credentials: 'include',
    })
      .then(async (response) => {
        if (!response.ok) throw new Error('no session')
        const data = await parse(response)
        accessToken = data.accessToken
        return data
      })
      .catch(() => null)
      .finally(() => {
        refreshInFlight = null
      })
  }
  return refreshInFlight
}

export const api = {
  baseUrl: BASE_URL,
  googleUrl: (role) =>
    `${BASE_URL}/auth/google${role ? `?role=${encodeURIComponent(role)}` : ''}`,
  register: (body) => request('/api/auth/register', { method: 'POST', body, auth: false }),
  login: (body) => request('/api/auth/login', { method: 'POST', body, auth: false }),
  logout: () => request('/api/auth/logout', { method: 'POST', auth: false }),
  me: () => request('/api/auth/me'),
  dashboard: () => request('/api/dashboard/summary'),
  users: () => request('/api/users'),
  updateRole: (id, role) => request(`/api/users/${id}/role`, { method: 'PATCH', body: { role } }),
  adminOverview: () => request('/api/admin/overview'),
}
