const { Contribution, EqubMember, EqubRound, PaymentTransaction, User } = require('../../lib/db');
const { overdueDays, penaltyForDays } = require('../../lib/penalty');

const contributionService = {
  async listByRound(roundId) {
    const list = await Contribution.findAll({
      where: { roundId },
      include: [
        {
          model: EqubMember,
          as: 'member',
          required: true,
          include: [
            {
              model: User,
              as: 'user',
              attributes: ['id', 'fullName', 'phone'],
              required: true,
            },
          ],
        },
      ],
    });

    // Fetch due date once for the round, then attach penalty fields.
    const round = await EqubRound.findOne({ where: { id: list[0]?.roundId ?? roundId }, attributes: ['dueDate'], raw: true });
    const due = round?.dueDate;
    for (const c of list) {
      if (!due || c.status === 'PAID' || c.status === 'WAIVED') {
        c.setDataValue('overdueDays', 0);
        c.setDataValue('penaltyDays', 0);
        c.setDataValue('penaltyAmount', 0);
        continue;
      }
      const days = overdueDays(due);
      const p = penaltyForDays(days);
      c.setDataValue('overdueDays', p.overdueDays);
      c.setDataValue('penaltyDays', p.penaltyDays);
      c.setDataValue('penaltyAmount', p.penaltyAmount);
    }

    return list;
  },

  async getById(id) {
    return Contribution.findOne({
      where: { id },
      include: [
        { model: EqubRound, as: 'round', required: true },
        {
          model: EqubMember,
          as: 'member',
          required: true,
          include: [{ model: User, as: 'user', required: true }],
        },
        { model: PaymentTransaction, as: 'paymentTxns', required: false },
      ],
    });
  },

  async recordPayment(roundId, memberId, data) {
    const [count] = await Contribution.update(
      { status: 'PAID', paidAt: new Date(), paymentRef: data.paymentRef ?? null },
      { where: { roundId, memberId } }
    );
    return { count };
  },
};

module.exports = { contributionService };
