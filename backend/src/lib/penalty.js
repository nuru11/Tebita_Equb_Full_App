const { Contribution, EqubMember, EqubRound } = require('./db');

const DAILY_PENALTY_AMOUNT = 50; // ETB
const MAX_PENALTY_DAYS = 20;

function startOfDayUtc(d) {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function overdueDays(dueDate) {
  if (!dueDate) return 0;
  const today = startOfDayUtc(new Date());
  const due = startOfDayUtc(new Date(dueDate));
  const diffMs = today.getTime() - due.getTime();
  if (diffMs <= 0) return 0;
  return Math.floor(diffMs / 86400000);
}

function penaltyForDays(days) {
  const d = Math.max(0, Math.min(MAX_PENALTY_DAYS, days));
  return {
    overdueDays: days,
    penaltyDays: d,
    penaltyAmount: d * DAILY_PENALTY_AMOUNT,
  };
}

/**
 * Enforce: if any unpaid contribution is overdue >= 20 days, set EqubMember.status = REMOVED.
 * This is "global" in the sense that ANY unpaid overdue contribution triggers the removal for that member row.
 */
async function enforceOverdueMemberRemoval() {
  // Only need unpaid contributions; join their round (for dueDate) and member (for status).
  const unpaid = await Contribution.findAll({
    where: { status: 'PENDING' },
    include: [
      { model: EqubRound, as: 'round', required: true, attributes: ['id', 'dueDate'] },
      { model: EqubMember, as: 'member', required: true, attributes: ['id', 'status'] },
    ],
  });

  const toRemove = new Set();
  for (const c of unpaid) {
    const days = overdueDays(c.round?.dueDate);
    if (days >= MAX_PENALTY_DAYS) {
      const memberId = c.member?.id;
      if (memberId) toRemove.add(memberId);
    }
  }

  if (toRemove.size === 0) return { removed: 0 };

  const ids = Array.from(toRemove);
  const [count] = await EqubMember.update(
    { status: 'REMOVED' },
    { where: { id: ids } }
  );

  return { removed: count };
}

module.exports = {
  DAILY_PENALTY_AMOUNT,
  MAX_PENALTY_DAYS,
  overdueDays,
  penaltyForDays,
  enforceOverdueMemberRemoval,
};

