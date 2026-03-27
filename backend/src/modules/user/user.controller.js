const { userService } = require('./user.service');

const userController = {
  async getMe(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const user = await userService.getMe(userId);
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    res.json(user);
  },

  async updateMe(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const body = req.body || {};
    try {
      const user = await userService.updateSelf(userId, body);
      res.json(user);
    } catch (err) {
      if (err?.status) {
        res.status(err.status).json({ error: err.message });
        return;
      }
      if (err?.code === 'P2025') {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      if (err?.code === 'P2002') {
        res.status(409).json({ error: err.message || 'Duplicate field' });
        return;
      }
      throw err;
    }
  },

  async getById(req, res) {
    const { id } = req.params;
    const user = await userService.getById(id);
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    res.json(user);
  },
};

module.exports = { userController };
