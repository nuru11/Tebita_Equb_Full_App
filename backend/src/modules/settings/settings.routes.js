const { Router } = require('express');
const { settingsController } = require('./settings.controller');
const { requireAdmin } = require('../../middleware/auth');

const settingsRoutes = Router();

settingsRoutes.get('/bank', requireAdmin, (req, res, next) =>
  settingsController.getBank(req, res).catch(next)
);

settingsRoutes.put('/bank', requireAdmin, (req, res, next) =>
  settingsController.updateBank(req, res).catch(next)
);

module.exports = settingsRoutes;

