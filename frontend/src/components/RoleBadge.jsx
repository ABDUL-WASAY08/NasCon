import { ROLE_LABEL } from '../lib/roles.js'

export default function RoleBadge({ role }) {
  return (
    <span className={`chip role-badge role-badge--${role}`}>{ROLE_LABEL[role] || role}</span>
  )
}
