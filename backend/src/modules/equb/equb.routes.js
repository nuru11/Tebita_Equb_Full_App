const { Router } = require('express');
const { equbController } = require('./equb.controller');
const { requireAuth, requireAdmin } = require('../../middleware/auth');

const equbRoutes = Router();

equbRoutes.get('/', (req, res, next) => equbController.list(req, res).catch(next));
equbRoutes.get('/:id', (req, res, next) => equbController.getById(req, res).catch(next));
equbRoutes.post('/', requireAdmin, (req, res, next) => equbController.create(req, res).catch(next));
equbRoutes.post('/:id/members', requireAdmin, (req, res, next) => equbController.addMember(req, res).catch(next));
equbRoutes.delete('/:id/members/:userId', requireAdmin, (req, res, next) => equbController.removeMember(req, res).catch(next));
equbRoutes.post('/:id/join', requireAuth, (req, res, next) => equbController.join(req, res).catch(next));
equbRoutes.post('/:id/leave', requireAuth, (req, res, next) => equbController.leave(req, res).catch(next));
equbRoutes.patch('/:id', requireAdmin, (req, res, next) => equbController.update(req, res).catch(next));
equbRoutes.delete('/:id', requireAdmin, (req, res, next) => equbController.delete(req, res).catch(next));

module.exports = equbRoutes;
