const { Router } = require('express');
const { contributionController } = require('./contribution.controller');

const contributionRoutes = Router({ mergeParams: true });

contributionRoutes.get('/', (req, res, next) => contributionController.list(req, res).catch(next));
contributionRoutes.get('/:id', (req, res, next) => contributionController.getById(req, res).catch(next));
contributionRoutes.post('/pay', (req, res, next) => contributionController.recordPayment(req, res).catch(next));

module.exports = contributionRoutes;
