const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { RefreshToken, User } = require('../../lib/db');
const { config } = require('../../config');
const {
  sendSecurityCode,
  verifySecurityCode,
} = require('../../lib/sms/afromessage');

const BCRYPT_ROUNDS = 10;
const OTP_RESEND_COOLDOWN_SECONDS = 60;
const otpCooldownByPhone = new Map();

function toSafeUser(user) {
  if (!user) return null;
  const plain = typeof user.toJSON === 'function' ? user.toJSON() : user;
  const { passwordHash, ...rest } = plain;
  return rest;
}

function accessTokenExpiresInSeconds() {
  const s = config.jwt.accessExpiresIn;
  if (typeof s === 'number') return s;
  if (s.endsWith('m')) return parseInt(s, 10) * 60;
  if (s.endsWith('h')) return parseInt(s, 10) * 3600;
  if (s.endsWith('d')) return parseInt(s, 10) * 86400;
  return 900; // default 15 min in seconds
}

function normalizePhone(phone) {
  return String(phone || '').trim();
}

const authService = {
  async requestRegisterOtp(data) {
    const phone = normalizePhone(data.phone);
    const existing = await User.findOne({ where: { phone } });
    if (existing) {
      const err = new Error('Phone or email already registered');
      err.code = 'DUPLICATE_PHONE';
      throw err;
    }

    const now = Date.now();
    const cooldownUntil = otpCooldownByPhone.get(phone) || 0;
    if (cooldownUntil > now) {
      const err = new Error('Please wait before requesting a new code');
      err.code = 'OTP_COOLDOWN';
      err.retryAfter = Math.ceil((cooldownUntil - now) / 1000);
      throw err;
    }

    const sent = await sendSecurityCode({ to: phone });
    otpCooldownByPhone.set(phone, now + OTP_RESEND_COOLDOWN_SECONDS * 1000);
    return {
      verificationId: sent.verificationId,
      retryAfter: OTP_RESEND_COOLDOWN_SECONDS,
    };
  },

  async verifyRegisterOtpAndRegister(data) {
    const phone = normalizePhone(data.phone);
    await verifySecurityCode({
      to: phone,
      code: data.code,
      verificationId: data.verificationId,
    });

    return this.register({
      phone,
      password: data.password,
      fullName: data.fullName,
      email: data.email,
      referenceCode: data.referenceCode,
    });
  },

  async register(data) {
    const hashed = await bcrypt.hash(data.password, BCRYPT_ROUNDS);
    const user = await User.create({
      phone: normalizePhone(data.phone),
      email: data.email ?? null,
      fullName: data.fullName,
      referenceCode: data.referenceCode ?? null,
      passwordHash: hashed,
      kyc: false,
    });
    return toSafeUser(user);
  },

  async login(data) {
    const user = await User.findOne({ where: { phone: data.phone } });
    if (!user) return null;
    const ok = await bcrypt.compare(data.password, user.passwordHash);
    if (!ok) return null;

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const refreshPayload = { sub: user.id };
    const refreshJwt = jwt.sign(
      refreshPayload,
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiresIn }
    );

    await RefreshToken.create({
      userId: user.id,
      token: refreshJwt,
      expiresAt,
    });

    const accessJwt = jwt.sign(
      { sub: user.id },
      config.jwt.accessSecret,
      { expiresIn: config.jwt.accessExpiresIn }
    );

    return {
      user: toSafeUser(user),
      accessToken: accessJwt,
      refreshToken: refreshJwt,
      expiresIn: accessTokenExpiresInSeconds(),
    };
  },

  async refresh(refreshToken) {
    let payload;
    try {
      payload = jwt.verify(refreshToken, config.jwt.refreshSecret);
    } catch {
      return null;
    }

    const record = await RefreshToken.findOne({ where: { token: refreshToken } });
    if (!record || record.expiresAt < new Date()) return null;

    const user = await User.findOne({ where: { id: payload.sub } });
    if (!user) return null;

    await RefreshToken.destroy({ where: { id: record.id } }).catch(() => {});

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const newRefreshJwt = jwt.sign(
      { sub: user.id },
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiresIn }
    );

    await RefreshToken.create({
      userId: user.id,
      token: newRefreshJwt,
      expiresAt,
    });

    const accessJwt = jwt.sign(
      { sub: user.id },
      config.jwt.accessSecret,
      { expiresIn: config.jwt.accessExpiresIn }
    );

    return {
      user: toSafeUser(user),
      accessToken: accessJwt,
      refreshToken: newRefreshJwt,
      expiresIn: accessTokenExpiresInSeconds(),
    };
  },
};

module.exports = { authService };
