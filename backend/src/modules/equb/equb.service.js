const { Contribution, Equb, EqubMember, EqubRound, User } = require('../../lib/db');
const { Op, fn, col } = require('sequelize');

const equbService = {
  async list(userId, filters = {}) {
    const where = {};
    const membersInclude = {
      model: EqubMember,
      as: 'members',
      where: { status: 'ACTIVE' },
      attributes: ['id'],
      required: false,
    };

    if (!filters.allForAdmin) {
      where.status = 'ACTIVE';
      if (userId && filters.myEqubsOnly) {
        membersInclude.where = { ...membersInclude.where, userId };
        membersInclude.required = true;
      }
    }

    if (filters.status && filters.allForAdmin) where.status = filters.status;
    if (filters.memberType) where.memberType = filters.memberType;
    if (filters.type) where.type = filters.type;

    const equbs = await Equb.findAll({
      where,
      include: [
        {
          model: User,
          as: 'organizer',
          attributes: ['id', 'fullName', 'phone'],
          required: false,
        },
        membersInclude,
      ],
      order: [['createdAt', 'DESC']],
    });

    // Current round comes directly from EqubRound table (MAX round_number per equb).
    const equbIds = equbs.map((e) => e.id);
    if (equbIds.length === 0) return equbs;

    const roundRows = await EqubRound.findAll({
      where: { equbId: { [Op.in]: equbIds } },
      attributes: [
        'equbId',
        [fn('MAX', col('round_number')), 'currentRoundNumber'],
      ],
      group: ['equbId'],
      raw: true,
    });

    const roundMap = new Map(
      roundRows.map((r) => [r.equbId, Number(r.currentRoundNumber) || 0])
    );

    for (const equb of equbs) {
      equb.setDataValue('currentRoundNumber', roundMap.get(equb.id) || 0);
    }

    // Base value for remaining payment until equb completion.
    // For member-specific requests, this will be recalculated after memberPaidAmount is known.
    for (const equb of equbs) {
      const contributionAmount = Number(equb.contributionAmount) || 0;
      const maxMembers = Number(equb.maxMembers) || 0;
      const totalRequiredForEqub = contributionAmount * maxMembers;
      equb.setDataValue('willPayAmount', totalRequiredForEqub > 0 ? totalRequiredForEqub : 0);
    }

    // For "myEqubsOnly", determine won round directly from EqubRound.winner_id.
    if (userId && filters.myEqubsOnly) {
      const memberIdByEqubId = new Map(
        equbs.map((equb) => [
          equb.id,
          Array.isArray(equb.members) && equb.members.length > 0 ? equb.members[0].id : null,
        ])
      );
      const memberIds = [...memberIdByEqubId.values()].filter(Boolean);

      if (memberIds.length > 0) {
        // Sum paid contributions from Contribution table by member id.
        const paidRows = await Contribution.findAll({
          where: {
            memberId: { [Op.in]: memberIds },
            status: 'PAID',
          },
          attributes: [
            'memberId',
            [fn('SUM', col('amount')), 'memberPaidAmount'],
          ],
          group: ['memberId'],
          raw: true,
        });
        const paidByMemberId = new Map(
          paidRows.map((r) => [r.memberId, Number(r.memberPaidAmount) || 0])
        );

        const wonRows = await EqubRound.findAll({
          where: {
            equbId: { [Op.in]: equbIds },
            winnerId: { [Op.in]: memberIds },
          },
          attributes: ['equbId', 'winnerId', 'roundNumber'],
          raw: true,
        });

        const wonRoundByEqubId = new Map();
        for (const row of wonRows) {
          const roundNo = Number(row.roundNumber) || 0;
          const prev = wonRoundByEqubId.get(row.equbId) || 0;
          if (roundNo > prev) wonRoundByEqubId.set(row.equbId, roundNo);
        }

        for (const equb of equbs) {
          const memberId = memberIdByEqubId.get(equb.id);
          const memberPaidAmount =
            memberId && paidByMemberId.has(memberId)
              ? paidByMemberId.get(memberId)
              : 0;
          const contributionAmount = Number(equb.contributionAmount) || 0;
          const maxMembers = Number(equb.maxMembers) || 0;
          const totalRequiredForEqub = contributionAmount * maxMembers;
          const remainingWillPay = totalRequiredForEqub - memberPaidAmount;
          const wonRoundNumber = wonRoundByEqubId.get(equb.id) || 0;
          equb.setDataValue('memberPaidAmount', memberPaidAmount);
          equb.setDataValue('willPayAmount', remainingWillPay > 0 ? remainingWillPay : 0);
          equb.setDataValue('wonRoundNumber', wonRoundNumber);
          equb.setDataValue('hasWon', wonRoundNumber > 0);
        }
      } else {
        for (const equb of equbs) {
          equb.setDataValue('memberPaidAmount', 0);
          equb.setDataValue('wonRoundNumber', 0);
          equb.setDataValue('hasWon', false);
        }
      }
    } else {
      for (const equb of equbs) {
        equb.setDataValue('memberPaidAmount', 0);
      }
    }

    return equbs;
  },

  async getById(id, options = {}) {
    const includeAllMembers = options.includeAllMembers === true;
    return Equb.findOne({
      where: { id },
      include: [
        {
          model: User,
          as: 'organizer',
          attributes: ['id', 'fullName', 'phone'],
          required: false,
        },
        {
          model: EqubMember,
          as: 'members',
          ...(includeAllMembers ? {} : { where: { status: 'ACTIVE' } }),
          required: false,
          attributes: ['id', 'status', 'role', 'joinedAt', 'equbId', 'userId', 'payoutOrder'],
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
  },

  async create(data) {
    // Controller sends Prisma-style connect object; normalize to organizerId.
    const { organizer, ...rest } = data;
    const organizerId = organizer?.connect?.id ?? rest.organizerId ?? null;
    return Equb.create({
      ...rest,
      organizerId,
    });
  },

  async update(id, data, organizerId) {
    const where = organizerId != null ? { id, organizerId } : { id };
    const equb = await Equb.findOne({ where });
    if (!equb) {
      const err = new Error('Equb not found');
      err.code = 'P2025';
      err.status = 404;
      throw err;
    }
    await equb.update(data);
    return equb;
  },

  async delete(id, organizerId) {
    const equb = await Equb.findOne({ where: { id, organizerId } });
    if (!equb) {
      const err = new Error('Equb not found');
      err.code = 'P2025';
      err.status = 404;
      throw err;
    }
    await equb.destroy();
    return true;
  },

  async join(equbId, userId) {
    const equb = await Equb.findOne({
      where: { id: equbId },
      attributes: ['id', 'status', 'isInviteOnly', 'maxMembers'],
      raw: true,
    });
    if (!equb) {
      const err = new Error('Equb not found');
      err.status = 404;
      throw err;
    }

    // Disallow joining cancelled/completed equbs
    if (equb.status === 'CANCELLED' || equb.status === 'COMPLETED') {
      const err = new Error('Equb is not joinable');
      err.status = 400;
      throw err;
    }

    if (equb.isInviteOnly) {
      const err = new Error('Equb is invite-only');
      err.status = 403;
      throw err;
    }

    const activeCount = await EqubMember.count({ where: { equbId, status: 'ACTIVE' } });
    if (equb.maxMembers > 0 && activeCount >= equb.maxMembers) {
      const err = new Error('Equb is full');
      err.status = 400;
      throw err;
    }

    const existing = await EqubMember.findOne({ where: { equbId, userId } });
    if (existing) {
      if (existing.status === 'ACTIVE') {
        const err = new Error('Already joined');
        err.status = 400;
        throw err;
      }
      // Reactivate existing membership
      await existing.update({ status: 'ACTIVE' });
      return existing;
    }

    return EqubMember.create({
      equbId,
      userId,
      role: 'MEMBER',
      status: 'ACTIVE',
    });
  },

  async leave(equbId, userId) {
    const equb = await Equb.findOne({
      where: { id: equbId },
      attributes: ['status'],
      raw: true,
    });
    if (!equb) {
      const err = new Error('Equb not found');
      err.status = 404;
      throw err;
    }

    if (equb.status === 'COMPLETED' || equb.status === 'CANCELLED') {
      const err = new Error('Cannot leave a completed or cancelled equb');
      err.status = 400;
      throw err;
    }

    const member = await EqubMember.findOne({ where: { equbId, userId } });

    if (!member) {
      const err = new Error('You are not a member of this equb');
      err.status = 404;
      throw err;
    }

    if (member.status !== 'ACTIVE') {
      const err = new Error('Membership is not active');
      err.status = 400;
      throw err;
    }

    await member.update({ status: 'LEFT' });
    return member;
  },

  async addMemberByPhone(equbId, phone) {
    const p = String(phone ?? '').trim();
    if (!p) {
      const err = new Error('phone is required');
      err.status = 400;
      throw err;
    }

    const user = await User.findOne({ where: { phone: p }, attributes: ['id', 'fullName', 'phone'] });
    if (!user) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    const equb = await Equb.findOne({
      where: { id: equbId },
      attributes: ['id', 'status', 'maxMembers'],
      raw: true,
    });
    if (!equb) {
      const err = new Error('Equb not found');
      err.status = 404;
      throw err;
    }

    const activeCount = await EqubMember.count({ where: { equbId, status: 'ACTIVE' } });
    if (equb.maxMembers > 0 && activeCount >= equb.maxMembers) {
      const err = new Error('Equb is full');
      err.status = 400;
      throw err;
    }

    const existing = await EqubMember.findOne({ where: { equbId, userId: user.id } });
    if (existing) {
      if (existing.status === 'ACTIVE') {
        const err = new Error('User is already a member of this equb');
        err.status = 409;
        throw err;
      }
      // Reactivate removed/left member
      await existing.update({ status: 'ACTIVE' });
      return {
        ...existing.toJSON(),
        user: user.toJSON(),
      };
    }

    const membership = await EqubMember.create({
      equbId,
      userId: user.id,
      role: 'MEMBER',
      status: 'ACTIVE',
    });

    return {
      ...membership.toJSON(),
      user: user.toJSON(),
    };
  },

  async removeMember(equbId, userId) {
    const equb = await Equb.findOne({
      where: { id: equbId },
      attributes: ['id', 'status'],
      raw: true,
    });
    if (!equb) {
      const err = new Error('Equb not found');
      err.status = 404;
      throw err;
    }

    const member = await EqubMember.findOne({ where: { equbId, userId } });
    if (!member) {
      const err = new Error('Member not found');
      err.status = 404;
      throw err;
    }

    // If equb has not started yet, admin may delete membership row entirely.
    if (equb.status === 'DRAFT') {
      await member.destroy();
      return { action: 'DELETED' };
    }

    // If equb already started, do not delete; only change member status.
    if (member.status !== 'REMOVED') {
      await member.update({ status: 'REMOVED' });
    }
    return { action: 'STATUS_UPDATED', member: member.toJSON() };
  },
};

module.exports = { equbService };
