const express = require('express');
const path = require('path');
const { errorHandler } = require('./middleware/errorHandler');
const { verifyJwt } = require('./middleware/verifyJwt');
const { attachUser } = require('./middleware/auth');
const authRoutes = require('./modules/auth/auth.routes');
const adminRoutes = require('./modules/admin/admin.routes');
const userRoutes = require('./modules/user/user.routes');
const equbRoutes = require('./modules/equb/equb.routes');
const roundRoutes = require('./modules/round/round.routes');
const contributionRoutes = require('./modules/contribution/contribution.routes');
const paymentRoutes = require('./modules/payment/payment.routes');
const uploadRoutes = require('./modules/upload/upload.routes');
const settingsRoutes = require('./modules/settings/settings.routes');
const notificationRoutes = require('./modules/notification/notification.routes');
const cors = require('cors');


function createApp() {
  const app = express();

  const allowedOrigins = [
    'http://localhost:5173',
    'https://equbadminpanel.shinur.com',
  ];
  app.use(
    cors({
      origin: (origin, callback) => {
        // Allow requests with no origin (e.g. Postman, server-to-server)
        if (!origin) return callback(null, true);
        if (allowedOrigins.includes(origin)) return callback(null, true);
        callback(null, false);
      },
      credentials: true,
    })
  );

  app.use(express.json());
  app.use(verifyJwt);
  app.use(attachUser);

  // Serve uploaded assets (e.g. payment screenshots)
  const uploadsDir = path.join(__dirname, '..', 'uploads');
  app.use('/uploads', express.static(uploadsDir));

  app.use('/api/auth', authRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/equbs', equbRoutes);
  app.use('/api/equbs/:equbId/rounds', roundRoutes);
  app.use('/api/rounds/:roundId/contributions', contributionRoutes);
  app.use('/api/payments', paymentRoutes);
  app.use('/api/uploads', uploadRoutes);
  app.use('/api/admin/settings', settingsRoutes);
  app.use('/api/notifications', notificationRoutes);

  app.use(errorHandler);
  return app;
}

module.exports = { createApp };
