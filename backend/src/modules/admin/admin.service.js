const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Admin } = require('../../lib/db');
const { config } = require('../../config');

function toSafeAdmin(admin) {
  if (!admin) return null;
  const { passwordHash, ...rest } = admin;
  return rest;
}

function accessTokenExpiresInSeconds() {
  const s = config.jwt.accessExpiresIn;
  if (typeof s === 'number') return s;
  if (s.endsWith('m')) return parseInt(s, 10) * 60;
  if (s.endsWith('h')) return parseInt(s, 10) * 3600;
  if (s.endsWith('d')) return parseInt(s, 10) * 86400;
  return 900;
}

const BCRYPT_ROUNDS = 10;

const adminService = {
  async create(data) {
    const hashed = await bcrypt.hash(data.password, BCRYPT_ROUNDS);
    try {
      const admin = await Admin.create({
        username: data.username,
        passwordHash: hashed,
        fullName: data.fullName,
        role: data.role ?? 'ADMIN',
      });
      return toSafeAdmin(admin);
    } catch (err) {
      if (err?.name === 'SequelizeUniqueConstraintError') {
        err.code = 'P2002';
      }
      throw err;
    }
  },

  async login(data) {
    const admin = await Admin.findOne({ where: { username: data.username } });
    if (!admin) return null;
    const ok = await bcrypt.compare(data.password, admin.passwordHash);
    if (!ok) return null;

    const accessToken = jwt.sign(
      { sub: admin.id, role: admin.role, accountType: 'admin' },
      config.jwt.accessSecret,
      { expiresIn: config.jwt.accessExpiresIn }
    );

    return {
      admin: toSafeAdmin(admin),
      accessToken,
      expiresIn: accessTokenExpiresInSeconds(),
    };
  },
};

module.exports = { adminService };
