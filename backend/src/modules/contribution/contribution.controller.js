const { contributionService } = require('./contribution.service');

const contributionController = {
  async list(req, res) {
    const roundId = req.params.roundId;
    if (!roundId) {
      res.status(400).json({ error: 'roundId required' });
      return;
    }
    const list = await contributionService.listByRound(roundId);
    res.json(list);
  },

  async getById(req, res) {
    const { id } = req.params;
    const contribution = await contributionService.getById(id);
    if (!contribution) {
      res.status(404).json({ error: 'Contribution not found' });
      return;
    }
    res.json(contribution);
  },

  async recordPayment(req, res) {
    const roundId = req.params.roundId;
    if (!roundId) {
      res.status(400).json({ error: 'roundId required' });
      return;
    }
    const body = req.body;
    await contributionService.recordPayment(roundId, body.memberId, {
      amount: body.amount,
      paymentRef: body.paymentRef,
    });
    res.status(200).json({ ok: true });
  },
};

module.exports = { contributionController };
