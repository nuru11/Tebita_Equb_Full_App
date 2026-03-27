module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'PaymentTransaction',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      userId: { type: DataTypes.STRING(36), allowNull: false, field: 'user_id' },
      equbId: { type: DataTypes.STRING(36), allowNull: true, field: 'equb_id' },
      roundId: { type: DataTypes.STRING(36), allowNull: true, field: 'round_id' },
      contributionId: { type: DataTypes.STRING(36), allowNull: true, field: 'contribution_id' },
      type: {
        type: DataTypes.ENUM('CONTRIBUTION', 'PAYOUT'),
        allowNull: false,
      },
      amount: { type: DataTypes.DECIMAL(12, 2), allowNull: false },
      currency: { type: DataTypes.STRING(5), allowNull: false, defaultValue: 'ETB' },
      status: {
        type: DataTypes.ENUM('PENDING', 'SUCCESS', 'FAILED'),
        allowNull: false,
        defaultValue: 'PENDING',
      },
      reference: { type: DataTypes.STRING(100), allowNull: true },
      metadata: { type: DataTypes.JSON, allowNull: true },
      screenshotUrl: { type: DataTypes.STRING(500), allowNull: true, field: 'screenshot_url' },
      createdAt: { type: DataTypes.DATE, allowNull: false, field: 'created_at', defaultValue: DataTypes.NOW },
    },
    {
      tableName: 'PaymentTransaction',
      freezeTableName: true,
      timestamps: false,
      indexes: [
        { fields: ['user_id'] },
        { fields: ['equb_id'] },
        { fields: ['created_at'] },
        { fields: ['round_id'] },
        { fields: ['contribution_id'] },
      ],
    }
  );
};

