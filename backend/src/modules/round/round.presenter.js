const { maskPhone } = require('../../lib/maskPhone');

function maskUserForMember(user) {
  if (!user || typeof user !== 'object') return;
  const raw = user.phone;
  delete user.phone;
  if (raw != null && raw !== '') {
    user.phoneMasked = maskPhone(raw);
  } else {
    user.phoneMasked = null;
  }
}

/**
 * Deep clone round JSON and strip raw phones from nested users; add phoneMasked for members.
 * @param {object} round - plain object from Sequelize toJSON()
 */
function presentRoundForMember(round) {
  const o = JSON.parse(JSON.stringify(round));
  if (o.winner?.user) maskUserForMember(o.winner.user);
  if (Array.isArray(o.contributions)) {
    for (const c of o.contributions) {
      if (c.member?.user) maskUserForMember(c.member.user);
    }
  }
  return o;
}

function isAdminRequest(req) {
  return req.accountType === 'admin' && req.adminId;
}

module.exports = { presentRoundForMember, isAdminRequest };
