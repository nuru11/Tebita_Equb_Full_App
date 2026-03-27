const { notificationService } = require('./notification.service');

const notificationController = {
  async list(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const unreadOnly = req.query.unreadOnly === 'true';
    const limit = Math.min(parseInt(req.query.limit, 10) || 50, 100);
    const list = await notificationService.listForUser(userId, { unreadOnly, limit });
    res.json(list);
  },

  async markRead(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const { id } = req.params;
    await notificationService.markRead(id, userId);
    res.json({ ok: true });
  },
};

module.exports = { notificationController };
