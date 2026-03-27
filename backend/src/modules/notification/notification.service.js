const { Notification } = require('../../lib/db');

const notificationService = {
  async listForUser(userId, options = {}) {
    const { unreadOnly = false, limit = 50 } = options;
    const where = { userId };
    if (unreadOnly) where.readAt = null;
    return Notification.findAll({
      where,
      order: [['createdAt', 'DESC']],
      limit,
      raw: true,
    });
  },

  async markRead(id, userId) {
    const [count] = await Notification.update(
      { readAt: new Date() },
      { where: { id, userId } }
    );
    return { count };
  },
};

module.exports = { notificationService };
