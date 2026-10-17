export function notFound(_req, res) {
  res.status(404).json({ message: 'Route not found.' });
}

export function errorHandler(error, _req, res, _next) {
  if (res.headersSent) return;

  if (error?.name === 'MulterError') {
    const message = error.code === 'LIMIT_FILE_SIZE'
      ? 'Image must be 5 MB or smaller.'
      : 'The uploaded image could not be accepted.';
    res.status(400).json({ message });
    return;
  }
  if (error?.name === 'ValidationError') {
    res.status(400).json({ message: error.message });
    return;
  }
  if (error?.name === 'CastError') {
    res.status(400).json({ message: 'The supplied identifier is invalid.' });
    return;
  }
  if (error?.code === 11000) {
    res.status(409).json({ message: 'An account with that email already exists.' });
    return;
  }
  if (error?.name === 'JsonWebTokenError' || error?.name === 'TokenExpiredError') {
    res.status(401).json({ message: 'The access token is invalid or expired.' });
    return;
  }

  const status = Number.isInteger(error?.statusCode) ? error.statusCode : 500;
  if (status >= 500) console.error(error);
  res.status(status).json({
    message: status >= 500 && process.env.NODE_ENV === 'production'
      ? 'An unexpected server error occurred.'
      : error?.message || 'An unexpected server error occurred.',
  });
}
