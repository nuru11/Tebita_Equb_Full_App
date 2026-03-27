const {
  Contribution,
  Equb,
  EqubMember,
  EqubRound,
  PaymentTransaction,
  User,
} = require('../../lib/db');

const paymentService = {
  async createTransaction(data) {
    let contributionId = data.contributionId ?? null;
    // If roundId is set but contributionId is missing, resolve current user's contribution for that round
    if (!contributionId && data.roundId && data.userId) {
      const contribution = await Contribution.findOne({
        where: { roundId: data.roundId },
        include: [
          {
            model: EqubMember,
            as: 'member',
            where: { userId: data.userId },
            required: true,
            attributes: ['id'],
          },
        ],
        attributes: ['id'],
      });
      if (contribution) contributionId = contribution.id;
    }

    return PaymentTransaction.create({
      userId: data.userId,
      equbId: data.equbId ?? null,
      roundId: data.roundId ?? null,
      contributionId,
      type: data.type,
      // Default to 0 when amount is not provided (e.g. generic upload)
      amount: data.amount ?? 0,
      currency: data.currency ?? 'ETB',
      reference: data.reference ?? null,
      metadata: data.metadata ?? null,
      screenshotUrl: data.screenshotUrl ?? null,
      status: 'PENDING',
    });
  },

  async updateStatus(id, status) {
    const txn = await PaymentTransaction.findOne({ where: { id } });
    if (!txn) return null;
    await txn.update({ status });
    return txn;
  },

  async listForEqub(equbId, status) {
    const where = {
      equbId,
      type: 'CONTRIBUTION',
    };
    if (status != null && String(status).trim() !== '') {
      where.status = String(status).toUpperCase();
    }
    return PaymentTransaction.findAll({
      where,
      include: [
        { model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: true },
        { model: Equb, as: 'equb', attributes: ['id', 'name'], required: false },
        { model: EqubRound, as: 'round', attributes: ['id', 'roundNumber'], required: false },
        {
          model: Contribution,
          as: 'contribution',
          attributes: ['id'],
          required: false,
          include: [
            {
              model: EqubMember,
              as: 'member',
              attributes: ['id'],
              required: false,
              include: [{ model: User, as: 'user', attributes: ['id', 'fullName', 'phone'], required: false }],
            },
          ],
        },
      ],
      order: [['createdAt', 'DESC']],
    });
  },

  async listForUser(userId) {
    return PaymentTransaction.findAll({
      where: { userId },
      include: [
        { model: Equb, as: 'equb', attributes: ['id', 'name'], required: false },
        { model: EqubRound, as: 'round', attributes: ['id', 'roundNumber'], required: false },
      ],
      order: [['createdAt', 'DESC']],
    });
  },
};

module.exports = { paymentService };
