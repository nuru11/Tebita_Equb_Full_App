module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Contribution',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      roundId: { type: DataTypes.STRING(36), allowNull: false, field: 'round_id' },
      memberId: { type: DataTypes.STRING(36), allowNull: false, field: 'member_id' },
      amount: { type: DataTypes.DECIMAL(12, 2), allowNull: false },
      status: {
        type: DataTypes.ENUM('PENDING', 'PAID', 'LATE', 'WAIVED'),
        allowNull: false,
        defaultValue: 'PENDING',
      },
      paidAt: { type: DataTypes.DATE, allowNull: true, field: 'paid_at' },
      paymentRef: { type: DataTypes.STRING(100), allowNull: true, field: 'payment_ref' },
      createdAt: { type: DataTypes.DATE, allowNull: false, field: 'created_at', defaultValue: DataTypes.NOW },
      updatedAt: { type: DataTypes.DATE, allowNull: false, field: 'updated_at', defaultValue: DataTypes.NOW },
    },
    {
      tableName: 'Contribution',
      freezeTableName: true,
      timestamps: true,
      indexes: [
        { unique: true, fields: ['round_id', 'member_id'] },
        { fields: ['round_id'] },
        { fields: ['member_id'] },
      ],
    }
  );
};

