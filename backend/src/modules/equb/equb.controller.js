const { equbService } = require('./equb.service');

const equbController = {
  async list(req, res) {
    const userId = req.accountType === 'user' ? (req.userId ?? req.user?.id) : null;
    const isAdmin = req.accountType === 'admin';
    const filters = {
      myEqubsOnly: req.query.myEqubsOnly === 'true' && !isAdmin,
      status: req.query.status || undefined,
      memberType: req.query.memberType || undefined,
      type: req.query.type || undefined,
      allForAdmin: isAdmin,
    };
    const list = await equbService.list(userId, filters);
    res.json(list);
  },

  async getById(req, res) {
    const { id } = req.params;
    const isAdmin = req.accountType === 'admin';
    const equb = await equbService.getById(id, { includeAllMembers: isAdmin });
    if (!equb) {
      res.status(404).json({ error: 'Equb not found' });
      return;
    }
    // Users may only fetch active equbs; admin can fetch any
    if (!isAdmin && equb.status !== 'ACTIVE') {
      res.status(404).json({ error: 'Equb not found' });
      return;
    }
    res.json(equb);
  },

  async create(req, res) {
    const body = req.body;
    if (body.maxMembers == null || body.maxMembers === '') {
      res.status(400).json({
        error: 'maxMembers is required',
      });
      return;
    }
    const maxMembers = Number(body.maxMembers);
    if (!Number.isInteger(maxMembers) || maxMembers < 1) {
      res.status(400).json({
        error: 'maxMembers must be an integer greater than 0',
      });
      return;
    }
    if (
      body.startDate == null ||
      body.startDate === '' ||
      body.endDate == null ||
      body.endDate === ''
    ) {
      res.status(400).json({ error: 'startDate and endDate are required' });
      return;
    }
    const startDate = new Date(body.startDate);
    const endDate = new Date(body.endDate);
    if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
      res.status(400).json({ error: 'Invalid startDate or endDate' });
      return;
    }
    if (endDate < startDate) {
      res.status(400).json({ error: 'endDate must be on or after startDate' });
      return;
    }
    const organizerId = body.organizerId ?? body.organizer_id;
    const equbType = (body.equbType ?? body.equb_type ?? '').toString().trim();
    const equb = await equbService.create({
      name: body.name,
      description: body.description,
      type: body.type ?? 'PRIVATE',
      ...(equbType ? { equbType } : {}),
      currency: body.currency ?? 'ETB',
      contributionAmount: body.contributionAmount,
      frequency: body.frequency ?? 'MONTHLY',
      payoutOrderType: body.payoutOrderType ?? 'FIXED_ORDER',
      maxMembers,
      currentCycleNumber: body.currentCycleNumber ?? 0,
      status: body.status ?? 'DRAFT',
      memberType: body.memberType ?? 'MEMBER',
      startDate,
      endDate,
      bankName: body.bankName,
      bankAccountName: body.bankAccountName,
      bankAccountNumber: body.bankAccountNumber,
      bankInstructions: body.bankInstructions,
      ...(organizerId && { organizer: { connect: { id: organizerId } } }),
    });
    res.status(201).json(equb);
  },

  async update(req, res) {
    const { id } = req.params;
    const body = req.body;
    const isAdmin = req.accountType === 'admin';
    const userId = isAdmin ? undefined : (req.userId ?? req.user?.id);
    if (!isAdmin && !userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    try {
      const equb = await equbService.update(
        id,
        {
          ...(body.name != null && { name: body.name }),
          ...(body.description != null && { description: body.description }),
          ...(body.type != null && { type: body.type }),
          ...(body.equbType != null && { equbType: body.equbType }),
          ...(body.equb_type != null && { equbType: body.equb_type }),
          ...(body.currency != null && { currency: body.currency }),
          ...(body.contributionAmount != null && {
            contributionAmount: body.contributionAmount,
          }),
          ...(body.frequency != null && { frequency: body.frequency }),
          ...(body.payoutOrderType != null && {
            payoutOrderType: body.payoutOrderType,
          }),
          ...(body.maxMembers != null && { maxMembers: body.maxMembers }),
          ...(body.currentCycleNumber != null && {
            currentCycleNumber: body.currentCycleNumber,
          }),
          ...(body.status != null && { status: body.status }),
          ...(body.memberType != null && { memberType: body.memberType }),
          ...(body.startDate != null && {
            startDate: body.startDate ? new Date(body.startDate) : null,
          }),
          ...(body.endDate != null && {
            endDate: body.endDate ? new Date(body.endDate) : null,
          }),
          ...(body.bankName != null && { bankName: body.bankName }),
          ...(body.bankAccountName != null && {
            bankAccountName: body.bankAccountName,
          }),
          ...(body.bankAccountNumber != null && {
            bankAccountNumber: body.bankAccountNumber,
          }),
          ...(body.bankInstructions != null && {
            bankInstructions: body.bankInstructions,
          }),
        },
        userId
      );
      res.json(equb);
    } catch (e) {
      if (e.code === 'P2025') {
        res.status(404).json({ error: 'Equb not found or you are not the organizer' });
        return;
      }
      throw e;
    }
  },

  async delete(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const { id } = req.params;
    try {
      await equbService.delete(id, userId);
      res.status(204).send();
    } catch (e) {
      if (e.code === 'P2025') {
        res.status(404).json({ error: 'Equb not found or you are not the organizer' });
        return;
      }
      throw e;
    }
  },

  async join(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const { id } = req.params;
    try {
      const membership = await equbService.join(id, userId);
      res.status(201).json(membership);
    } catch (e) {
      if (e.status) {
        res.status(e.status).json({ error: e.message });
        return;
      }
      throw e;
    }
  },

  async leave(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const { id } = req.params;
    try {
      const membership = await equbService.leave(id, userId);
      res.status(200).json(membership);
    } catch (e) {
      if (e.status) {
        res.status(e.status).json({ error: e.message });
        return;
      }
      throw e;
    }
  },

  async addMember(req, res) {
    const { id: equbId } = req.params;
    const body = req.body || {};
    try {
      const membership = await equbService.addMemberByPhone(equbId, body.phone);
      res.status(201).json(membership);
    } catch (e) {
      if (e.status) {
        res.status(e.status).json({ error: e.message });
        return;
      }
      throw e;
    }
  },

  async removeMember(req, res) {
    const { id: equbId, userId } = req.params;
    try {
      const result = await equbService.removeMember(equbId, userId);
      if (result?.action === 'DELETED') {
        res.status(204).send();
        return;
      }
      res.status(200).json(result);
    } catch (e) {
      if (e.status) {
        res.status(e.status).json({ error: e.message });
        return;
      }
      throw e;
    }
  },
};

module.exports = { equbController };
