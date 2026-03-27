const { Router } = require('express');
const { roundController } = require('./round.controller');

const roundRoutes = Router({ mergeParams: true });

roundRoutes.get('/', (req, res, next) => roundController.list(req, res).catch(next));
roundRoutes.get('/:roundId', (req, res, next) => roundController.getById(req, res).catch(next));
roundRoutes.post('/', (req, res, next) => roundController.create(req, res).catch(next));
roundRoutes.post('/:roundId/complete', (req, res, next) => roundController.complete(req, res).catch(next));

module.exports = roundRoutes;
