module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'BankSettings',
    {
      id: {
        type: DataTypes.STRING(120),
        primaryKey: true,
      },
      bankName: { type: DataTypes.STRING(120), allowNull: true },
      bankAccountName: { type: DataTypes.STRING(120), allowNull: true },
      bankAccountNumber: { type: DataTypes.STRING(50), allowNull: true },
      bankInstructions: { type: DataTypes.TEXT, allowNull: true },
      createdAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW, field: 'created_at' },
      updatedAt: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW, field: 'updated_at' },
    },
    {
      tableName: 'BankSettings',
      freezeTableName: true,
      timestamps: true,
    }
  );
};

