module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Admin',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      username: {
        type: DataTypes.STRING(120),
        allowNull: false,
        unique: true,
      },
      passwordHash: {
        type: DataTypes.STRING(255),
        allowNull: false,
        field: 'password_hash',
      },
      fullName: {
        type: DataTypes.STRING(120),
        allowNull: false,
        field: 'full_name',
      },
      role: {
        type: DataTypes.ENUM('SUPER_ADMIN', 'ADMIN', 'STAFF'),
        allowNull: false,
        defaultValue: 'ADMIN',
      },
      createdAt: {
        type: DataTypes.DATE,
        allowNull: false,
        field: 'created_at',
        defaultValue: DataTypes.NOW,
      },
      updatedAt: {
        type: DataTypes.DATE,
        allowNull: false,
        field: 'updated_at',
        defaultValue: DataTypes.NOW,
      },
    },
    {
      tableName: 'Admin',
      freezeTableName: true,
      timestamps: true,
      indexes: [{ fields: ['username'] }, { fields: ['role'] }],
    }
  );
};

