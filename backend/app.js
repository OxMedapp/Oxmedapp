require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const healthRouter = require('./routes/health');
const authRouter = require('./routes/auth');
const usersRouter = require('./routes/users');
const pharmaciesRouter = require('./routes/pharmacies');
const facilitiesRouter = require('./routes/facilities');
const patientsRouter = require('./routes/patients');
const encountersRouter = require('./routes/encounters');
const assessmentsRouter = require('./routes/assessments');
const aiReviewRouter = require('./routes/aiReview');
const routingRouter = require('./routes/routing');
const rulesRouter = require('./routes/rules');
const referralsRouter = require('./routes/referrals');
const eventsRouter = require('./routes/events');
const statsRouter = require('./routes/stats');

const { notFound, errorHandler } = require('./middleware/error');

const app = express();

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 60000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api', limiter);

// CORS – restrict to frontend domain
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:3000';
app.use(cors({
  origin: corsOrigin,
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '1mb' }));

// Health check (public)
app.use('/health', healthRouter);

// API routes
app.use('/api/auth', authRouter);
app.use('/api/users', usersRouter);
app.use('/api/pharmacies', pharmaciesRouter);
app.use('/api/facilities', facilitiesRouter);
app.use('/api/patients', patientsRouter);
app.use('/api/encounters', encountersRouter);
app.use('/api/assessments', assessmentsRouter);
app.use('/api/ai-review', aiReviewRouter);
app.use('/api/routing', routingRouter);
app.use('/api/rules', rulesRouter);
app.use('/api/referrals', referralsRouter);
app.use('/api/events', eventsRouter);
app.use('/api/stats', statsRouter);

app.use(notFound);
app.use(errorHandler);

module.exports = app;