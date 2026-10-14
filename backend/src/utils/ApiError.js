export class ApiError extends Error {
  constructor(status, message, code, issues) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code || 'ERROR'
    if (issues) this.issues = issues
  }

  static badRequest(message, code, issues) {
    return new ApiError(400, message, code || 'BAD_REQUEST', issues)
  }

  static unauthorized(message, code) {
    return new ApiError(401, message, code || 'UNAUTHORIZED')
  }

  static forbidden(message, code) {
    return new ApiError(403, message, code || 'FORBIDDEN')
  }

  static notFound(message, code) {
    return new ApiError(404, message, code || 'NOT_FOUND')
  }

  static conflict(message, code) {
    return new ApiError(409, message, code || 'CONFLICT')
  }

  static validation(issues) {
    return new ApiError(422, 'Validation failed', 'VALIDATION_FAILED', issues)
  }
}
