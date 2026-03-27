const { Router } = require('express');
const { paymentController } = require('./payment.controller');
const { requireAuth, requireAdmin } = require('../../middleware/auth');

const paymentRoutes = Router();

// Create a payment transaction (e.g. member uploads bank transfer receipt)
paymentRoutes.post('/', requireAuth, (req, res, next) =>
  paymentController.create(req, res).catch(next)
);

// List current user's payment transactions
paymentRoutes.get('/me', requireAuth, (req, res, next) =>
  paymentController.listMyTransactions(req, res).catch(next)
);

// List payments for a specific equb (admin only)
paymentRoutes.get('/equbs/:equbId', requireAdmin, (req, res, next) =>
  paymentController.listForEqub(req, res).catch(next)
);

// Update payment transaction status (e.g. mark as approved/rejected)
paymentRoutes.patch('/:id/status', requireAdmin, (req, res, next) =>
  paymentController.updateStatus(req, res).catch(next)
);

// Placeholder for external gateway webhooks
paymentRoutes.post('/callback', (req, res, next) =>
  paymentController.callback(req, res).catch(next)
);

module.exports = paymentRoutes;
