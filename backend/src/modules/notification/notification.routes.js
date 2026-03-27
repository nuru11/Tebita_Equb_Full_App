const { Router } = require('express');
const { notificationController } = require('./notification.controller');
const { requireAuth } = require('../../middleware/auth');

const notificationRoutes = Router();

notificationRoutes.get('/', requireAuth, (req, res, next) =>
  notificationController.list(req, res).catch(next)
);
notificationRoutes.patch('/:id/read', requireAuth, (req, res, next) =>
  notificationController.markRead(req, res).catch(next)
);

module.exports = notificationRoutes;
