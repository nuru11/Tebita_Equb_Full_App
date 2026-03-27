const { authService } = require('./auth.service');

const authController = {
  async register(req, res) {
    res.status(400).json({
      error: 'Signup now requires OTP verification. Use /register/request-otp then /register/verify-otp.',
    });
  },

  async requestRegisterOtp(req, res) {
    const body = req.body || {};
    if (!body.phone) {
      res.status(400).json({
        error: 'Missing required fields',
        required: ['phone'],
      });
      return;
    }

    try {
      const result = await authService.requestRegisterOtp(body);
      res.status(200).json(result);
    } catch (err) {
      if (err.code === 'DUPLICATE_PHONE' || err.code === 'P2002') {
        res.status(409).json({ error: 'Phone or email already registered' });
        return;
      }
      if (err.code === 'OTP_COOLDOWN') {
        res.status(429).json({
          error: err.message,
          retryAfter: err.retryAfter || 60,
        });
        return;
      }
      if (
        err.code === 'AFRO_CONFIG' ||
        err.code === 'AFRO_CHALLENGE_FAILED' ||
        err.code === 'AFRO_SEND_FAILED'
      ) {
        res.status(502).json({ error: err.message });
        return;
      }
      throw err;
    }
  },

  async verifyRegisterOtp(req, res) {
    const body = req.body || {};
    if (
      !body.phone ||
      !body.password ||
      !body.fullName ||
      !body.code ||
      !body.verificationId
    ) {
      res.status(400).json({
        error: 'Missing required fields',
        required: ['phone', 'password', 'fullName', 'code', 'verificationId'],
      });
      return;
    }

    try {
      const user = await authService.verifyRegisterOtpAndRegister(body);
      res.status(201).json({ user });
    } catch (err) {
      if (err.code === 'P2002') {
        res.status(409).json({ error: 'Phone or email already registered' });
        return;
      }
      if (err.code === 'AFRO_VERIFY_FAILED') {
        res.status(400).json({ error: err.message || 'Invalid verification code' });
        return;
      }
      throw err;
    }
  },

  async login(req, res) {
    const body = req.body || {};
    if (!body.phone || !body.password) {
      res.status(400).json({
        error: 'Missing required fields',
        required: ['phone', 'password'],
      });
      return;
    }
    const result = await authService.login(body);
    if (!result) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }
    res.json(result);
  },

  async refresh(req, res) {
    const body = req.body || {};
    if (!body.refreshToken) {
      res.status(400).json({
        error: 'Missing required field',
        required: ['refreshToken'],
      });
      return;
    }
    const result = await authService.refresh(body.refreshToken);
    if (!result) {
      res.status(401).json({ error: 'Invalid refresh token' });
      return;
    }
    res.json(result);
  },
};

module.exports = { authController };
