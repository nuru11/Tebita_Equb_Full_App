const { Router } = require('express');
const { adminController } = require('./admin.controller');
const { requireAdmin } = require('../../middleware/auth');

const adminRoutes = Router();

adminRoutes.post('/login', (req, res, next) =>
  adminController.login(req, res).catch(next)
);
adminRoutes.get('/users', requireAdmin, (req, res, next) =>
  adminController.listUsers(req, res).catch(next)
);
adminRoutes.patch('/users/:id', requireAdmin, (req, res, next) =>
  adminController.updateUser(req, res).catch(next)
);
adminRoutes.patch('/users/:id/status', requireAdmin, (req, res, next) =>
  adminController.updateUserStatus(req, res).catch(next)
);
adminRoutes.post('/', requireAdmin, (req, res, next) =>
  adminController.create(req, res).catch(next)
);

module.exports = adminRoutes;
