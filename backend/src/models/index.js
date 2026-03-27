const { DataTypes } = require('sequelize');

const defineUser = require('./user.model');
const defineRefreshToken = require('./refresh_token.model');
const defineAdmin = require('./admin.model');
const defineEqub = require('./equb.model');
const defineEqubMember = require('./equb_member.model');
const defineEqubRound = require('./equb_round.model');
const defineContribution = require('./contribution.model');
const definePaymentTransaction = require('./payment_transaction.model');
const defineNotification = require('./notification.model');
const defineBankSettings = require('./bank_settings.model');

function initModels(sequelize) {
  const User = defineUser(sequelize, DataTypes);
  const RefreshToken = defineRefreshToken(sequelize, DataTypes);
  const Admin = defineAdmin(sequelize, DataTypes);
  const Equb = defineEqub(sequelize, DataTypes);
  const EqubMember = defineEqubMember(sequelize, DataTypes);
  const EqubRound = defineEqubRound(sequelize, DataTypes);
  const Contribution = defineContribution(sequelize, DataTypes);
  const PaymentTransaction = definePaymentTransaction(sequelize, DataTypes);
  const Notification = defineNotification(sequelize, DataTypes);
  const BankSettings = defineBankSettings(sequelize, DataTypes);

  // Associations (mirror prisma schema)
  User.hasMany(Equb, { as: 'organizedEqubs', foreignKey: 'organizerId' });
  Equb.belongsTo(User, { as: 'organizer', foreignKey: 'organizerId' });

  User.hasMany(EqubMember, { as: 'memberships', foreignKey: 'userId' });
  EqubMember.belongsTo(User, { as: 'user', foreignKey: 'userId' });

  Equb.hasMany(EqubMember, { as: 'members', foreignKey: 'equbId' });
  EqubMember.belongsTo(Equb, { as: 'equb', foreignKey: 'equbId' });

  Equb.hasMany(EqubRound, { as: 'rounds', foreignKey: 'equbId' });
  EqubRound.belongsTo(Equb, { as: 'equb', foreignKey: 'equbId' });

  EqubRound.belongsTo(EqubMember, { as: 'winner', foreignKey: 'winnerId' });
  EqubMember.hasMany(EqubRound, { as: 'roundsWon', foreignKey: 'winnerId' });

  EqubRound.hasMany(Contribution, { as: 'contributions', foreignKey: 'roundId' });
  Contribution.belongsTo(EqubRound, { as: 'round', foreignKey: 'roundId' });

  EqubMember.hasMany(Contribution, { as: 'contributions', foreignKey: 'memberId' });
  Contribution.belongsTo(EqubMember, { as: 'member', foreignKey: 'memberId' });

  User.hasMany(Notification, { as: 'notifications', foreignKey: 'userId' });
  Notification.belongsTo(User, { as: 'user', foreignKey: 'userId' });

  User.hasMany(PaymentTransaction, { as: 'paymentTxns', foreignKey: 'userId' });
  PaymentTransaction.belongsTo(User, { as: 'user', foreignKey: 'userId' });

  Equb.hasMany(PaymentTransaction, { as: 'paymentTxns', foreignKey: 'equbId' });
  PaymentTransaction.belongsTo(Equb, { as: 'equb', foreignKey: 'equbId' });

  EqubRound.hasMany(PaymentTransaction, { as: 'paymentTxns', foreignKey: 'roundId' });
  PaymentTransaction.belongsTo(EqubRound, { as: 'round', foreignKey: 'roundId' });

  Contribution.hasMany(PaymentTransaction, { as: 'paymentTxns', foreignKey: 'contributionId' });
  PaymentTransaction.belongsTo(Contribution, { as: 'contribution', foreignKey: 'contributionId' });

  User.hasMany(RefreshToken, { as: 'refreshTokens', foreignKey: 'userId' });
  RefreshToken.belongsTo(User, { as: 'user', foreignKey: 'userId' });

  return {
    User,
    RefreshToken,
    Admin,
    Equb,
    EqubMember,
    EqubRound,
    Contribution,
    PaymentTransaction,
    Notification,
    BankSettings,
  };
}

module.exports = { initModels };

