import { z } from 'zod'

const emailField = z
  .string()
  .trim()
  .regex(/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Enter a valid email address')

export const registerSchema = z.object({
  name: z.string().trim().min(2, 'Enter your full name').max(120),
  email: emailField,
  password: z.string().min(8, 'Use at least 8 characters').max(128),
  role: z.enum(['customer', 'provider']).optional(),
  organization: z.string().trim().max(120).optional(),
})

export const loginSchema = z.object({
  email: emailField,
  password: z.string().min(1, 'Enter your password').max(128),
})
