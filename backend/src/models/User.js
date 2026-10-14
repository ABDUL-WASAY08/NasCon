import mongoose from 'mongoose'
import { ROLES, DEFAULT_ROLE } from '../constants/roles.js'

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 120 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true, index: true },
    passwordHash: { type: String, select: false },
    googleId: { type: String, index: true, sparse: true },
    avatarUrl: { type: String, default: '' },
    role: { type: String, enum: ROLES, default: DEFAULT_ROLE, index: true },
    organization: { type: String, trim: true, default: '' },
    authProvider: { type: String, enum: ['local', 'google'], default: 'local' },
    emailVerified: { type: Boolean, default: false },
    lastLoginAt: { type: Date },
    refreshTokenHash: { type: String, select: false },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (_doc, ret) => {
        ret.id = ret._id
        delete ret._id
        delete ret.__v
        delete ret.passwordHash
        delete ret.refreshTokenHash
        return ret
      },
    },
  },
)

userSchema.virtual('initials').get(function initials() {
  return this.name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('')
})

export const User = mongoose.model('User', userSchema)
