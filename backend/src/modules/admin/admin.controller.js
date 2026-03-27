const { adminService } = require('./admin.service');
const { userService } = require('../user/user.service');

const adminController = {
  async create(req, res) {
    const body = req.body || {};
    if (!body.username || !body.password || !body.fullName) {
      res.status(400).json({
        error: 'Missing required fields',
        required: ['username', 'password', 'fullName'],
      });
      return;
    }
    try {
      const admin = await adminService.create({
        username: body.username,
        password: body.password,
        fullName: body.fullName,
        role: body.role,
      });
      res.status(201).json({ admin });
    } catch (err) {
      if (err.code === 'P2002') {
        res.status(409).json({ error: 'Username already taken' });
        return;
      }
      throw err;
    }
  },

  async login(req, res) {
    const body = req.body || {};
    if (!body.username || !body.password) {
      res.status(400).json({
        error: 'Missing required fields',
        required: ['username', 'password'],
      });
      return;
    }
    const result = await adminService.login(body);
    if (!result) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }
    res.json(result);
  },

  async listUsers(req, res) {
    const users = await userService.list();
    res.json(users);
  },

  async updateUserStatus(req, res) {
    const { id: userId } = req.params;
    const { status } = req.body || {};
    if (!status || !['PENDING', 'ACTIVE', 'INACTIVE'].includes(status)) {
      res.status(400).json({ error: 'Invalid or missing status. Use PENDING, ACTIVE, or INACTIVE.' });
      return;
    }
    try {
      const user = await userService.updateStatus(userId, status);
      res.json(user);
    } catch (err) {
      if (err.code === 'P2025') {
        res.status(404).json({ error: 'User not found' });
        return;
      }
      throw err;
    }
  },

  async updateUser(req, res) {
    const { id: userId } = req.params;
    const body = req.body || {};
    try {
      const user = await userService.updateInfo(userId, body);
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
};

module.exports = { adminController };
