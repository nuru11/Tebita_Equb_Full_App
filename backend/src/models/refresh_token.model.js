module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'RefreshToken',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      userId: {
        type: DataTypes.STRING(36),
        allowNull: false,
        field: 'user_id',
      },
      token: {
        type: DataTypes.STRING(500),
        allowNull: false,
        unique: true,
      },
      expiresAt: {
        type: DataTypes.DATE,
        allowNull: false,
        field: 'expires_at',
      },
      createdAt: {
        type: DataTypes.DATE,
        allowNull: false,
        field: 'created_at',
        defaultValue: DataTypes.NOW,
      },
    },
    {
      tableName: 'RefreshToken',
      freezeTableName: true,
      timestamps: false,
      indexes: [
        { fields: ['user_id'] },
        { fields: ['token'] },
      ],
    }
  );
};

