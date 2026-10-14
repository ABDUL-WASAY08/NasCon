export const ROLES = ['customer', 'provider', 'manager', 'admin']

export const ROLE_RANK = { customer: 1, provider: 2, manager: 3, admin: 4 }

export const ROLE_LABEL = {
  customer: 'Customer',
  provider: 'Service provider',
  manager: 'Operations manager',
  admin: 'Platform administrator',
}

export const ROLE_HOME = {
  customer: '/console',
  provider: '/console',
  manager: '/console',
  admin: '/console/admin',
}

export function atLeast(role, minimum) {
  return (ROLE_RANK[role] || 0) >= (ROLE_RANK[minimum] || 0)
}

export function homeForRole(role) {
  return ROLE_HOME[role] || '/console'
}

export function isAdmin(user) {
  return user?.role === 'admin'
}
