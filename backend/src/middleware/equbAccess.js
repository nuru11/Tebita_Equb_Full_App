const { EqubMember } = require('../lib/db');

/**
 * After requireUserOrAdmin: admins pass; users must be ACTIVE members of req.params.equbId.
 */
async function requireAdminOrActiveEqubMember(req, res, next) {
  if (req.accountType === 'admin' && req.adminId) {
    next();
    return;
  }

  const userId = req.userId;
  const equbId = req.params.equbId;
  if (!userId || !equbId) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const member = await EqubMember.findOne({
      where: { equbId, userId, status: 'ACTIVE' },
      attributes: ['id'],
    });
    if (!member) {
      res.status(403).json({ error: 'You are not a member of this equb' });
      return;
    }
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { requireAdminOrActiveEqubMember };
