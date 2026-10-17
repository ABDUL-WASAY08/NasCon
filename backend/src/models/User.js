import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';

const roles = ['super_admin', 'league_organizer', 'club_manager', 'player', 'viewer'];

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 100,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      maxlength: 254,
    },
    passwordHash: {
      type: String,
      select: false,
      minlength: 1,
    },
    googleId: {
      type: String,
      unique: true,
      sparse: true,
      select: false,
    },
    profileImage: {
      type: String,
      default: null,
    },
    profileImagePublicId: {
      type: String,
      default: null,
      select: false,
    },
    role: {
      type: String,
      enum: roles,
      default: 'viewer',
    },
    tokenVersion: {
      type: Number,
      default: 0,
      select: false,
    },
  },
  { timestamps: true },
);

userSchema.pre('validate', function ensureAuthMethod(next) {
  if (!this.passwordHash && !this.googleId) {
    this.invalidate('passwordHash', 'A password or verified Google account is required.');
  }
  next();
});

userSchema.methods.setPassword = async function setPassword(password) {
  this.passwordHash = await bcrypt.hash(password, 12);
};

userSchema.methods.verifyPassword = function verifyPassword(password) {
  if (!this.passwordHash) return Promise.resolve(false);
  return bcrypt.compare(password, this.passwordHash);
};

userSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this.id,
    full_name: this.fullName,
    email: this.email,
    role: this.role,
    avatar_url: this.profileImage,
  };
};

export const User = mongoose.model('User', userSchema);
