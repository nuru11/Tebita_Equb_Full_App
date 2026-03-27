module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'EqubMember',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      equbId: { type: DataTypes.STRING(36), allowNull: false, field: 'equb_id' },
      userId: { type: DataTypes.STRING(36), allowNull: false, field: 'user_id' },
      role: {
        type: DataTypes.ENUM('ORGANIZER', 'MEMBER'),
        allowNull: false,
        defaultValue: 'MEMBER',
      },
      payoutOrder: { type: DataTypes.INTEGER, allowNull: true, field: 'payout_order' },
      status: {
        type: DataTypes.ENUM('ACTIVE', 'LEFT', 'REMOVED'),
        allowNull: false,
        defaultValue: 'ACTIVE',
      },
      joinedAt: { type: DataTypes.DATE, allowNull: false, field: 'joined_at', defaultValue: DataTypes.NOW },
    },
    {
      tableName: 'EqubMember',
      freezeTableName: true,
      timestamps: false,
      indexes: [
        { unique: true, fields: ['equb_id', 'user_id'] },
        { fields: ['user_id'] },
        { fields: ['equb_id'] },
      ],
    }
  );
};

