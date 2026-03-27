const { settingsService } = require('./settings.service');

const settingsController = {
  async getBank(req, res) {
    const settings = await settingsService.getBank();
    res.json(settings);
  },

  async updateBank(req, res) {
    const body = req.body || {};
    const updated = await settingsService.updateBank({
      bankName: body.bankName,
      bankAccountName: body.bankAccountName,
      bankAccountNumber: body.bankAccountNumber,
      bankInstructions: body.bankInstructions,
    });
    res.json(updated);
  },
};

module.exports = { settingsController };

