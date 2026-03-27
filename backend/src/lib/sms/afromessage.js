const { config } = require('../../config');

function assertConfigured() {
  const missing = [];
  if (!config.afromessage.token) missing.push('AFRO_TOKEN');
  if (!config.afromessage.from) missing.push('AFRO_FROM');
  if (!config.afromessage.sender) missing.push('AFRO_SENDER');
  if (missing.length) {
    const err = new Error(`Afromessage not configured: missing ${missing.join(', ')}`);
    err.code = 'AFRO_CONFIG';
    throw err;
  }
}

function apiRoot() {
  const base = config.afromessage.baseUrl || 'https://api.afromessage.com/api/send';
  return base.replace(/\/send\/?$/, '');
}

async function requestAfromessage(url, errorCode) {
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${config.afromessage.token}`,
      Accept: 'application/json',
    },
  });

  const text = await res.text().catch(() => '');
  let payload = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch {
    payload = null;
  }

  if (!res.ok) {
    const err = new Error(`Afromessage failed: HTTP ${res.status}`);
    err.code = errorCode;
    err.status = res.status;
    err.details = payload || text;
    throw err;
  }

  if (payload && payload.acknowledge === 'error') {
    const firstError = payload?.response?.errors?.[0];
    const err = new Error(firstError || 'Afromessage returned an error');
    err.code = errorCode;
    err.status = 400;
    err.details = payload;
    throw err;
  }

  return payload || text;
}

/**
 * Send SMS via Afromessage.
 * Uses query params per their API; message is URL-encoded.
 * Callback is intentionally omitted (per requirement).
 */
async function sendSms({ to, message }) {
  assertConfigured();

  const params = new URLSearchParams({
    from: config.afromessage.from,
    sender: config.afromessage.sender,
    to: String(to),
    message: String(message),
  });

  const url = `${apiRoot()}/send?${params.toString()}`;
  return requestAfromessage(url, 'AFRO_SEND_FAILED');
}

async function sendSecurityCode({
  to,
  prefix = 'Your Addisway verification code is',
  postfix = 'Do not share this code.',
  ttl = 300,
  len = 6,
  type = 0,
}) {
  assertConfigured();

  const params = new URLSearchParams({
    from: config.afromessage.from,
    sender: config.afromessage.sender,
    to: String(to),
    pr: String(prefix),
    ps: String(postfix),
    sb: '1',
    sa: '1',
    ttl: String(ttl),
    len: String(len),
    t: String(type),
  });

  const url = `${apiRoot()}/challenge?${params.toString()}`;
  const payload = await requestAfromessage(url, 'AFRO_CHALLENGE_FAILED');
  return {
    verificationId: payload?.response?.verificationId || null,
    messageId: payload?.response?.message_id || null,
    status: payload?.response?.status || null,
    raw: payload,
  };
}

async function verifySecurityCode({ to, code, verificationId }) {
  assertConfigured();

  const params = new URLSearchParams({
    to: String(to),
    code: String(code),
  });
  if (verificationId) {
    params.set('vc', String(verificationId));
  }

  const url = `${apiRoot()}/verify?${params.toString()}`;
  const payload = await requestAfromessage(url, 'AFRO_VERIFY_FAILED');
  return payload;
}

module.exports = { sendSms, sendSecurityCode, verifySecurityCode };

