const { User } = require('../../lib/db');

function isNonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

function isValidPhone(phone) {
  // Admin panel currently uses 09XXXXXXXX format
  return typeof phone === 'string' && /^09\d{8}$/.test(phone);
}

function isValidEmail(email) {
  if (email == null) return true;
  if (typeof email !== 'string') return false;
  const e = email.trim();
  if (!e) return true; // allow clearing email
  // Lightweight sanity check (avoid over-restricting valid emails)
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e);
}

const userService = {
  async getById(id) {
    return User.findOne({
      where: { id },
      attributes: [
        'id',
        'phone',
        'fullName',
        'email',
        'avatarUrl',
        'referenceCode',
        'isVerified',
        'kyc',
        'status',
        'createdAt',
        'updatedAt',
      ],
      raw: true,
    });
  },

  async getMe(userId) {
    return this.getById(userId);
  },

  /** List all users (safe fields only). For admin use. */
  async list() {
    return User.findAll({
      order: [['createdAt', 'DESC']],
      attributes: ['id', 'phone', 'fullName', 'email', 'avatarUrl', 'isVerified', 'kyc', 'status', 'createdAt'],
      raw: true,
    });
  },

  /** Update user status (admin only). */
  async updateStatus(userId, status) {
    const allowed = ['PENDING', 'ACTIVE', 'INACTIVE'];
    if (!allowed.includes(status)) {
      const err = new Error('Invalid status');
      err.status = 400;
      throw err;
    }
    const user = await User.findOne({ where: { id: userId } });
    if (!user) {
      const err = new Error('User not found');
      err.code = 'P2025';
      err.status = 404;
      throw err;
    }
    await user.update({ status });
    return user.get({ plain: true, attributes: ['id', 'status', 'fullName', 'phone'] });
  },

  /** Update user info (admin only). Safe fields only. */
  async updateInfo(userId, data) {
    const patch = {};

    if (data.fullName !== undefined) {
      if (!isNonEmptyString(data.fullName)) {
        const err = new Error('Invalid fullName');
        err.status = 400;
        throw err;
      }
      patch.fullName = data.fullName.trim();
    }

    if (data.phone !== undefined) {
      if (typeof data.phone !== 'string') {
        const err = new Error('Invalid phone');
        err.status = 400;
        throw err;
      }
      const phone = data.phone.trim().replace(/\s+/g, '');
      if (!isValidPhone(phone)) {
        const err = new Error('Phone must start with 09 and be 10 digits');
        err.status = 400;
        throw err;
      }
      patch.phone = phone;
    }

    if (data.email !== undefined) {
      if (!isValidEmail(data.email)) {
        const err = new Error('Invalid email');
        err.status = 400;
        throw err;
      }
      const email = typeof data.email === 'string' ? data.email.trim() : data.email;
      patch.email = email || null;
    }

    if (data.avatarUrl !== undefined) {
      if (data.avatarUrl != null && typeof data.avatarUrl !== 'string') {
        const err = new Error('Invalid avatarUrl');
        err.status = 400;
        throw err;
      }
      const v = typeof data.avatarUrl === 'string' ? data.avatarUrl.trim() : data.avatarUrl;
      patch.avatarUrl = v || null;
    }

    if (data.referenceCode !== undefined) {
      if (data.referenceCode != null && typeof data.referenceCode !== 'string') {
        const err = new Error('Invalid referenceCode');
        err.status = 400;
        throw err;
      }
      const v = typeof data.referenceCode === 'string' ? data.referenceCode.trim() : data.referenceCode;
      patch.referenceCode = v || null;
    }

    if (data.isVerified !== undefined) {
      if (typeof data.isVerified !== 'boolean') {
        const err = new Error('Invalid isVerified');
        err.status = 400;
        throw err;
      }
      patch.isVerified = data.isVerified;
    }

    if (data.kyc !== undefined) {
      if (typeof data.kyc !== 'boolean') {
        const err = new Error('Invalid kyc');
        err.status = 400;
        throw err;
      }
      patch.kyc = data.kyc;
    }

    if (Object.keys(patch).length === 0) {
      const err = new Error('No editable fields provided');
      err.status = 400;
      throw err;
    }

    const user = await User.findOne({ where: { id: userId } });
    if (!user) {
      const err = new Error('User not found');
      err.code = 'P2025';
      err.status = 404;
      throw err;
    }

    try {
      await user.update(patch);
    } catch (err) {
      if (err?.name === 'SequelizeUniqueConstraintError') {
        err.code = 'P2002';
        // give a clearer message when we can
        const field = err?.errors?.[0]?.path;
        err.message = field ? `${field} already exists` : 'Duplicate field';
      }
      throw err;
    }

    return user.get({
      plain: true,
      attributes: [
        'id',
        'phone',
        'fullName',
        'email',
        'avatarUrl',
        'isVerified',
        'kyc',
        'status',
        'referenceCode',
        'createdAt',
        'updatedAt',
      ],
    });
  },

  /** Update the authenticated user's own profile (safe fields only). */
  async updateSelf(userId, data) {
    const patch = {};

    if (data.fullName !== undefined) {
      if (!isNonEmptyString(data.fullName)) {
        const err = new Error('Invalid fullName');
        err.status = 400;
        throw err;
      }
      patch.fullName = data.fullName.trim();
    }

    if (data.email !== undefined) {
      if (!isValidEmail(data.email)) {
        const err = new Error('Invalid email');
        err.status = 400;
        throw err;
      }
      const email = typeof data.email === 'string' ? data.email.trim() : data.email;
      patch.email = email || null;
    }

    if (data.phone !== undefined) {
      const err = new Error('Phone number cannot be changed');
      err.status = 400;
      throw err;
    }

    if (data.avatarUrl !== undefined) {
      const err = new Error('avatarUrl cannot be changed here');
      err.status = 400;
      throw err;
    }

    if (data.referenceCode !== undefined) {
      if (data.referenceCode != null && typeof data.referenceCode !== 'string') {
        const err = new Error('Invalid referenceCode');
        err.status = 400;
        throw err;
      }
      const v =
        typeof data.referenceCode === 'string' ? data.referenceCode.trim() : data.referenceCode;
      patch.referenceCode = v || null;
    }

    if (Object.keys(patch).length === 0) {
      const err = new Error('No editable fields provided');
      err.status = 400;
      throw err;
    }

    const user = await User.findOne({ where: { id: userId } });
    if (!user) {
      const err = new Error('User not found');
      err.code = 'P2025';
      err.status = 404;
      throw err;
    }

    try {
      await user.update(patch);
    } catch (err) {
      if (err?.name === 'SequelizeUniqueConstraintError') {
        err.code = 'P2002';
        const field = err?.errors?.[0]?.path;
        err.message = field ? `${field} already exists` : 'Duplicate field';
      }
      throw err;
    }

    return user.get({
      plain: true,
      attributes: [
        'id',
        'phone',
        'fullName',
        'email',
        'avatarUrl',
        'referenceCode',
        'isVerified',
        'kyc',
        'status',
        'createdAt',
        'updatedAt',
      ],
    });
  },
};

module.exports = { userService };
