const { paymentService } = require('./payment.service');

const paymentController = {
  async create(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const body = req.body;
    const txn = await paymentService.createTransaction({
      userId,
      equbId: body.equbId,
      roundId: body.roundId,
      contributionId: body.contributionId,
      type: body.type,
      amount: body.amount,
      currency: body.currency,
      reference: body.reference,
      screenshotUrl: body.screenshotUrl,
      metadata: body.metadata,
    });
    res.status(201).json(txn);
  },

  async callback(req, res) {
    // Placeholder for gateway webhook (e.g. Telebirr): verify signature, update status
    const body = req.body;
    if (body.transactionId && body.status === 'SUCCESS') {
      await paymentService.updateStatus(body.transactionId, 'SUCCESS');
    }
    res.status(200).send('OK');
  },

  async listForEqub(req, res) {
    const equbId = req.params.equbId;
    if (!equbId) {
      res.status(400).json({ error: 'equbId required' });
      return;
    }
    const status = req.query.status;
    const list = await paymentService.listForEqub(equbId, status);
    res.json(list);
  },

  async listMyTransactions(req, res) {
    const userId = req.userId ?? req.user?.id;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    const list = await paymentService.listForUser(userId);
    res.json(list);
  },

  async updateStatus(req, res) {
    const id = req.params.id;
    const status = req.body.status;
    if (!status) {
      res.status(400).json({ error: 'status required' });
      return;
    }
    const updated = await paymentService.updateStatus(id, status);
    res.json(updated);
  },
};

module.exports = { paymentController };
