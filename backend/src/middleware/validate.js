import { ApiError } from '../utils/ApiError.js'

export function validate(schema, source = 'body') {
  return (req, _res, next) => {
    const result = schema.safeParse(req[source])
    if (!result.success) {
      const issues = result.error.issues.map((issue) => ({
        field: issue.path.join('.') || source,
        message: issue.message,
      }))
      return next(ApiError.validation(issues))
    }
    req[source] = result.data
    next()
  }
}
