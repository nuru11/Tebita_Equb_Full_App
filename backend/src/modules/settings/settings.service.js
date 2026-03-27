const { BankSettings } = require('../../lib/db');

const SETTINGS_ID = 'global-bank-settings';

const settingsService = {
  async getBank() {
    return BankSettings.findOne({ where: { id: SETTINGS_ID }, raw: true });
  },

  async updateBank(data) {
    const [row] = await BankSettings.upsert({
      id: SETTINGS_ID,
      bankName: data.bankName,
      bankAccountName: data.bankAccountName,
      bankAccountNumber: data.bankAccountNumber,
      bankInstructions: data.bankInstructions,
    });
    return row?.toJSON?.() ?? row;
  },
};

module.exports = { settingsService };

