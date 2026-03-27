const { Router } = require('express');
const { authController } = require('./auth.controller');

const authRoutes = Router();

authRoutes.post('/register', (req, res, next) =>
  authController.register(req, res).catch(next)
);
authRoutes.post('/register/request-otp', (req, res, next) =>
  authController.requestRegisterOtp(req, res).catch(next)
);
authRoutes.post('/register/verify-otp', (req, res, next) =>
  authController.verifyRegisterOtp(req, res).catch(next)
);
authRoutes.post('/login', (req, res, next) =>
  authController.login(req, res).catch(next)
);
authRoutes.post('/refresh', (req, res, next) =>
  authController.refresh(req, res).catch(next)
);

module.exports = authRoutes;
