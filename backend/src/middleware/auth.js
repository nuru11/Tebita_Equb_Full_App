const { User } = require('../lib/db');

/**
 * Attach authenticated user to request.
 * Use after JWT verification (e.g. in route handler or a prior middleware that sets req.userId).
 */
async function attachUser(req, res, next) {
  const userId = req.userId;
  if (!userId) {
    next();
    return;
  }
  try {
    const user = await User.findOne({ where: { id: userId } });
    if (user) req.user = user.toJSON();
  } catch {
    // ignore lookup errors; optional attachment
  }
  next();
}

/**
 * Require authenticated user. Call after a middleware that sets req.userId (e.g. JWT verify).
 */
function requireAuth(req, res, next) {
  if (!req.userId && !req.user) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  next();
}

/**
 * Require admin (accountType === 'admin'). Use for admin-only routes.
 */
function requireAdmin(req, res, next) {
  if (req.accountType !== 'admin' || !req.adminId) {
    res.status(403).json({ error: 'Admin only' });
    return;
  }
  next();
}

module.exports = { attachUser, requireAuth, requireAdmin };
