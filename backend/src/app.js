const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const { env } = require('./config/env');
const { errorHandler } = require('./middleware/errorHandler');
const routes = require('./routes');

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: env.corsOrigin === '*' ? true : env.corsOrigin,
    credentials: env.corsOrigin !== '*',
  }),
);
app.use(express.json({ limit: '1mb' }));
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 300,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

const healthResponse = {
  ok: true,
  service: 'cardwise-backend',
};

app.get('/', (_req, res) => {
  res.json(healthResponse);
});

app.get('/health', (_req, res) => {
  res.json(healthResponse);
});

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'cardwise-backend',
    api: true,
  });
});

app.use('/api', routes);
app.use(errorHandler);

module.exports = { app };
