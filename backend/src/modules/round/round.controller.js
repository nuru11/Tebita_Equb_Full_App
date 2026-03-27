const { roundService } = require('./round.service');

const roundController = {
  async list(req, res) {
    const equbId = req.params.equbId;
    if (!equbId) {
      res.status(400).json({ error: 'equbId required' });
      return;
    }
    const list = await roundService.listByEqub(equbId);
    res.json(list);
  },

  async getById(req, res) {
    const { roundId } = req.params;
    const round = await roundService.getById(roundId);
    if (!round) {
      res.status(404).json({ error: 'Round not found' });
      return;
    }
    res.json(round);
  },

  async create(req, res) {
    const equbId = req.params.equbId;
    if (!equbId) {
      res.status(400).json({ error: 'equbId required' });
      return;
    }
    const body = req.body;
    const round = await roundService.create(equbId, {
      dueDate: new Date(body.dueDate),
    });
    res.status(201).json(round);
  },

  async complete(req, res) {
    const equbId = req.params.equbId;
    const roundId = req.params.roundId;
    if (!equbId || !roundId) {
      res.status(400).json({ error: 'equbId and roundId required' });
      return;
    }
    try {
      const round = await roundService.complete(equbId, roundId, {
        winnerId: req.body.winnerId || null,
        randomDraw: req.body.randomDraw === true,
      });
      res.json(round);
    } catch (err) {
      if (err.status === 400) {
        res.status(400).json({ error: err.message });
        return;
      }
      throw err;
    }
  },
};

module.exports = { roundController };
