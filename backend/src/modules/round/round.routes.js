const { Router } = require('express');
const { requireAdmin, requireUserOrAdmin } = require('../../middleware/auth');
const { requireAdminOrActiveEqubMember } = require('../../middleware/equbAccess');
const { roundController } = require('./round.controller');

const roundRoutes = Router({ mergeParams: true });

roundRoutes.get(
  '/',
  requireUserOrAdmin,
  requireAdminOrActiveEqubMember,
  (req, res, next) => roundController.list(req, res).catch(next),
);
roundRoutes.get(
  '/:roundId',
  requireUserOrAdmin,
  requireAdminOrActiveEqubMember,
  (req, res, next) => roundController.getById(req, res).catch(next),
);
roundRoutes.post('/', requireAdmin, (req, res, next) => roundController.create(req, res).catch(next));
roundRoutes.post('/:roundId/complete', requireAdmin, (req, res, next) =>
  roundController.complete(req, res).catch(next),
);

module.exports = roundRoutes;
