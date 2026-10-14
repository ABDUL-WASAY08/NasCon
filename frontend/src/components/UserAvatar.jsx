export default function UserAvatar({ user, size = 40 }) {
  if (user?.avatarUrl) {
    return (
      <img className="avatar" src={user.avatarUrl} alt="" width={size} height={size} />
    )
  }
  return (
    <span
      className="avatar avatar--initials"
      style={{ width: size, height: size }}
      aria-hidden="true"
    >
      {user?.initials || user?.name?.slice(0, 2).toUpperCase()}
    </span>
  )
}
