const { Op } = require('sequelize');

const {
  Contribution,
  Equb,
  EqubMember,
  EqubRound,
  Notification,
  PaymentTransaction,
  User,
  sequelize,
} = require('../../lib/db');

const { overdueDays, penaltyForDays } = require('../../lib/penalty');
const { sendSms } = require('../../lib/sms/afromessage');

/** Member IDs who have already won in this equb (any completed round). One win per member per equb. */
async function getPastWinnerMemberIds(equbId, excludeRoundId = null) {
  const where = {
    equbId,
    status: { [Op.in]: ['COMPLETED', 'DRAWN'] },
    winnerId: { [Op.ne]: null },
  };
  if (excludeRoundId) where.id = { [Op.ne]: excludeRoundId };
  const rounds = await EqubRound.findAll({
    where,
    attributes: ['winnerId'],
    raw: true,
  });
  return new Set(rounds.map((r) => r.winnerId));
}

/** Pick a random winner from round contributions. Excludes members who have already won in this equb. */
async function pickRandomWinner(equbId, round) {
  const pastWinnerIds = await getPastWinnerMemberIds(equbId, round.id);
  let eligibleContributions = round.contributions.filter(
    (c) => !pastWinnerIds.has(c.memberId),
  );
  if (eligibleContributions.length === 0) {
    const err = new Error('All members in this round have already won in this equb; cannot pick a winner');
    err.status = 400;
    throw err;
  }
  const randomIndex = Math.floor(Math.random() * eligibleContributions.length);
  return eligibleContributions[randomIndex].memberId;
}

const roundService = {
  async listByEqub(equbId) {
    return EqubRound.findAll({
      where: { equbId },
      order: [['roundNumber', 'ASC']],
      include: [
        {
          model: EqubMember,
          as: 'winner',
          required: false,
          include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: false }],
        },
      ],
    });
  },

  async getById(roundId) {
    const round = await EqubRound.findOne({
      where: { id: roundId },
      include: [
        { model: Equb, as: 'equb', required: true },
        {
          model: EqubMember,
          as: 'winner',
          required: false,
          include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: false }],
        },
        {
          model: Contribution,
          as: 'contributions',
          required: false,
          include: [
            {
              model: EqubMember,
              as: 'member',
              required: true,
              include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: true }],
            },
            {
              model: PaymentTransaction,
              as: 'paymentTxns',
              required: false,
              attributes: ['id', 'screenshotUrl', 'reference'],
              separate: true,
              limit: 1,
              order: [['createdAt', 'DESC']],
            },
          ],
        },
      ],
    });
    if (!round) return null;

    const due = round.dueDate;
    for (const c of round.contributions ?? []) {
      if (c.status === 'PAID' || c.status === 'WAIVED') {
        c.setDataValue('overdueDays', 0);
        c.setDataValue('penaltyAmount', 0);
        c.setDataValue('penaltyDays', 0);
        continue;
      }
      const days = overdueDays(due);
      const p = penaltyForDays(days);
      c.setDataValue('overdueDays', p.overdueDays);
      c.setDataValue('penaltyDays', p.penaltyDays);
      c.setDataValue('penaltyAmount', p.penaltyAmount);
    }

    return round;
  },

  async create(equbId, data) {
    const equb = await Equb.findOne({
      where: { id: equbId },
      attributes: ['id', 'contributionAmount', 'maxMembers'],
      include: [{ model: EqubMember, as: 'members', where: { status: 'ACTIVE' }, attributes: ['id'], required: false }],
    });
    if (!equb) {
      const err = new Error('Equb not found');
      err.status = 404;
      throw err;
    }

    const activeMemberCount = equb.members.length;
    if (activeMemberCount === 0) {
      const err = new Error('Cannot create round without active members');
      err.status = 400;
      throw err;
    }

    // Respect maxMembers if set; otherwise use current active members.
    const maxSlots =
      equb.maxMembers && equb.maxMembers > 0
        ? Math.min(equb.maxMembers, activeMemberCount)
        : activeMemberCount;

    // Auto-assign next round number so admin cannot override it.
    const lastRound = await EqubRound.findOne({
      where: { equbId },
      order: [['roundNumber', 'DESC']],
      attributes: ['roundNumber'],
      raw: true,
    });
    const nextRoundNumber = (lastRound?.roundNumber || 0) + 1;

    if (nextRoundNumber > maxSlots) {
      const err = new Error('All members have already won; cannot create more rounds');
      err.status = 400;
      throw err;
    }

    const round = await EqubRound.create({
      equbId,
      roundNumber: nextRoundNumber,
      dueDate: data.dueDate,
    });

    if (equb.members.length > 0) {
      await Contribution.bulkCreate(
        equb.members.map((m) => ({
          roundId: round.id,
          memberId: m.id,
          amount: equb.contributionAmount,
          status: 'PENDING',
        }))
      );
    }
    return EqubRound.findOne({
      where: { id: round.id },
      include: [
        {
          model: EqubMember,
          as: 'winner',
          required: false,
          include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: false }],
        },
      ],
    });
  },

  async complete(equbId, roundId, options = {}) {
    return sequelize.transaction(async (t) => {
      const round = await EqubRound.findOne({
        where: { id: roundId, equbId },
        include: [
          {
            model: Equb,
            as: 'equb',
            required: true,
            attributes: ['payoutOrderType', 'name'],
            include: [{ model: EqubMember, as: 'members', where: { status: 'ACTIVE' }, attributes: ['id'], required: false }],
          },
          {
            model: Contribution,
            as: 'contributions',
            required: false,
            include: [{ model: EqubMember, as: 'member', required: true, attributes: ['id', 'userId'] }],
          },
        ],
        transaction: t,
      });
      if (!round) return null;

      const allPaid = round.contributions.length > 0 && round.contributions.every((c) => c.status === 'PAID');
      if (!allPaid) {
        const err = new Error('Not all contributions are paid');
        err.status = 400;
        throw err;
      }

      if (round.status === 'COMPLETED' || round.status === 'DRAWN') {
        const err = new Error('Round already completed');
        err.status = 400;
        throw err;
      }

      const potAmount = round.contributions.reduce((sum, c) => sum + Number(c.amount), 0);
      let winnerId = options.winnerId || null;
      const randomDraw = options.randomDraw === true;

      // Per-round choice: admin can request random draw regardless of equb type
      if (randomDraw && round.contributions.length > 0) {
        winnerId = await pickRandomWinner(equbId, round);
      } else if (winnerId) {
        // Admin selected a winner
        const validMember = round.contributions.some((c) => c.memberId === winnerId);
        if (!validMember) {
          const err = new Error('winnerId must be a member with a contribution in this round');
          err.status = 400;
          throw err;
        }
        const pastWinnerIds = await getPastWinnerMemberIds(equbId, roundId);
        if (pastWinnerIds.has(winnerId)) {
          const err = new Error('This member has already won in this equb. Each member can win only once.');
          err.status = 400;
          throw err;
        }
      } else if (round.equb.payoutOrderType === 'FIXED_ORDER') {
        const err = new Error('Either select a winner or choose random draw');
        err.status = 400;
        throw err;
      } else if (round.contributions.length > 0) {
        // LOTTERY equb, no winner sent: pick randomly (legacy behavior)
        winnerId = await pickRandomWinner(equbId, round);
      }

      await round.update(
        {
        potAmount,
        winnerId: winnerId || null,
        drawnAt: new Date(),
        status: 'COMPLETED',
      },
        { transaction: t }
      );

      const updated = await EqubRound.findOne({
        where: { id: roundId },
        include: [
          { model: Equb, as: 'equb', attributes: ['name'], required: true },
          {
            model: EqubMember,
            as: 'winner',
            required: false,
            include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: false }],
          },
          {
            model: Contribution,
            as: 'contributions',
            required: false,
            include: [
              {
                model: EqubMember,
                as: 'member',
                required: true,
                include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: true }],
              },
            ],
          },
        ],
        transaction: t,
      });

      if (updated?.winner?.user?.id) {
        const winnerUserId = updated.winner.user.id;
        const winnerPhone = updated.winner.user.phone;
        const equbName = updated.equb?.name || 'Equb';
        const potStr = potAmount != null ? ` Pot: ${potAmount}` : '';
        const body = `Congratulations! You won Round ${updated.roundNumber} in ${equbName}.${potStr}`;
        await Notification.create(
          {
            userId: winnerUserId,
            title: 'You won the round!',
            body,
            type: 'ROUND_WON',
          },
          { transaction: t }
        );

        // Send winner SMS (non-blocking): don't fail round completion if SMS fails.
        if (winnerPhone) {
          sendSms({
            to: winnerPhone,
            message: body,
          }).catch((e) => {
            // eslint-disable-next-line no-console
            console.error('Winner SMS failed', e?.message ?? e);
          });
        }
      }

      return updated;
    });
  },
};

module.exports = { roundService };
