/**
 * Single source of truth for the platform's role-based access control (RBAC).
 * Roles are a strict hierarchy: customer < provider < manager < admin.
 */

export const ROLES = ['customer', 'provider', 'manager', 'admin']

export const ROLE_RANK = { customer: 1, provider: 2, manager: 3, admin: 4 }

/** Roles a visitor may pick when they create their own account. */
export const SELF_SIGNUP_ROLES = ['customer', 'provider']

export const DEFAULT_ROLE = 'customer'

/**
 * Capabilities granted to a role, including everything granted to lower-ranked
 * roles. This is the contract the API enforces; the client only mirrors it for
 * presentation.
 */
const CAPABILITIES = {
  customer: ['profile:read', 'booking:create', 'booking:read:own', 'chat:participate'],
  provider: ['assignment:read', 'booking:status:update', 'schedule:read'],
  manager: ['users:read', 'analytics:read', 'operations:dashboard', 'report:read'],
  admin: ['users:role:update', 'audit:read', 'platform:configure', 'integration:manage'],
}

export function capabilitiesFor(role) {
  const rank = ROLE_RANK[role] || 0
  return Object.entries(CAPABILITIES)
    .filter(([name]) => (ROLE_RANK[name] || 0) <= rank)
    .flatMap(([, caps]) => caps)
}

export function hasCapability(role, capability) {
  return capabilitiesFor(role).includes(capability)
}

export function isValidRole(role) {
  return ROLES.includes(role)
}

export function atLeastRole(role, minimum) {
  return (ROLE_RANK[role] || 0) >= (ROLE_RANK[minimum] || 0)
}
