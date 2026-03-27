module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Notification',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      userId: { type: DataTypes.STRING(36), allowNull: false, field: 'user_id' },
      title: { type: DataTypes.STRING(120), allowNull: false },
      body: { type: DataTypes.TEXT, allowNull: true },
      type: { type: DataTypes.STRING(50), allowNull: false },
      readAt: { type: DataTypes.DATE, allowNull: true, field: 'read_at' },
      createdAt: { type: DataTypes.DATE, allowNull: false, field: 'created_at', defaultValue: DataTypes.NOW },
    },
    {
      tableName: 'Notification',
      freezeTableName: true,
      timestamps: false,
      indexes: [{ fields: ['user_id'] }, { fields: ['created_at'] }],
    }
  );
};

