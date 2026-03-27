const jwt = require('jsonwebtoken');
const { config } = require('../config');

function verifyJwt(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    next();
    return;
  }

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, config.jwt.accessSecret);
    if (payload.accountType === 'admin') {
      req.accountType = 'admin';
      req.adminId = payload.sub;
      req.role = payload.role;
    } else {
      req.accountType = 'user';
      req.userId = payload.sub;
    }
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { verifyJwt };
