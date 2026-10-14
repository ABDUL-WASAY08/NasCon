import { ROLES, ROLE_LABEL } from '../lib/roles.js'
import RoleBadge from './RoleBadge.jsx'
import UserAvatar from './UserAvatar.jsx'

const fmtDate = (value) =>
  value
    ? new Date(value).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
    : '—'

export default function UserDirectory({
  users,
  currentUserId,
  canEditRoles = false,
  busyId,
  onChangeRole,
  notice,
}) {
  return (
    <section className="panel flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="text-[1.08rem]">User directory</h2>
          <p className="text-[0.82rem] leading-snug text-muted">
            {canEditRoles
              ? 'Administrators can change any role. Changes are enforced server-side.'
              : 'Read-only. Only administrators can change roles.'}
          </p>
        </div>
        <span className="chip">{users.length} shown</span>
      </div>

      {notice && (
        <p
          className="rounded-sm border border-live-line bg-live-soft px-4 py-3 text-[0.82rem] text-live"
          role="status"
        >
          {notice}
        </p>
      )}

      <div className="overflow-x-auto">
        <table className="w-full min-w-[520px] border-collapse">
          <thead>
            <tr>
              {['User', 'Role', 'Method', 'Joined'].map((heading) => (
                <th
                  key={heading}
                  scope="col"
                  className="border-b border-line-strong pe-3 pb-3 text-left font-mono text-[0.68rem] font-medium uppercase tracking-[0.09em] text-faint"
                >
                  {heading}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {users.map((row) => (
              <tr key={row.id}>
                <td className="border-b border-line py-3 pe-3 align-middle last:border-b-0">
                  <div className="flex items-center gap-3">
                    <UserAvatar user={row} size={34} />
                    <div>
                      <span className="block text-[0.88rem] font-semibold text-ink">{row.name}</span>
                      <span className="block font-mono text-[0.72rem] text-faint">{row.email}</span>
                    </div>
                  </div>
                </td>
                <td className="border-b border-line py-3 pe-3 align-middle last:border-b-0">
                  {canEditRoles && row.id !== currentUserId ? (
                    <select
                      className="field__input min-h-[38px] px-3 pr-9 text-[0.82rem]"
                      value={row.role}
                      disabled={busyId === row.id}
                      aria-label={`Role for ${row.name}`}
                      onChange={(event) => onChangeRole(row, event.target.value)}
                    >
                      {ROLES.map((role) => (
                        <option key={role} value={role}>
                          {ROLE_LABEL[role]}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <RoleBadge role={row.role} />
                  )}
                </td>
                <td className="mono border-b border-line py-3 pe-3 align-middle text-muted last:border-b-0">
                  {row.authProvider === 'google' ? 'Google' : 'Password'}
                </td>
                <td className="mono border-b border-line py-3 pe-3 align-middle text-muted last:border-b-0">
                  {fmtDate(row.createdAt)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
