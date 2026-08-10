const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3000),
  corsOrigin: process.env.CORS_ORIGIN || '*',
  mongoUri: process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/creditwise',
  mongoServerSelectionTimeoutMs: Number(
    process.env.MONGO_SERVER_SELECTION_TIMEOUT_MS || 5000,
  ),
  jwtSecret: process.env.JWT_SECRET || 'mock-dev-jwt-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  openRouter: {
    primaryApiKey: process.env.OPENROUTER_API_KEY_PRIMARY || '',
    fallbackApiKey: process.env.OPENROUTER_API_KEY_FALLBACK || '',
    model: process.env.OPENROUTER_MODEL || 'openai/gpt-4.1-mini',
    baseUrl: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
  },
};

module.exports = { env };
