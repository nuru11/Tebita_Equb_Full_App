module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'EqubRound',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      equbId: { type: DataTypes.STRING(36), allowNull: false, field: 'equb_id' },
      roundNumber: { type: DataTypes.INTEGER, allowNull: false, field: 'round_number' },
      dueDate: { type: DataTypes.DATEONLY, allowNull: false, field: 'due_date' },
      potAmount: { type: DataTypes.DECIMAL(12, 2), allowNull: true, field: 'pot_amount' },
      status: {
        type: DataTypes.ENUM('PENDING', 'COLLECTING', 'DRAWN', 'COMPLETED'),
        allowNull: false,
        defaultValue: 'PENDING',
      },
      winnerId: { type: DataTypes.STRING(36), allowNull: true, field: 'winner_id' },
      drawnAt: { type: DataTypes.DATE, allowNull: true, field: 'drawn_at' },
      createdAt: { type: DataTypes.DATE, allowNull: false, field: 'created_at', defaultValue: DataTypes.NOW },
      updatedAt: { type: DataTypes.DATE, allowNull: false, field: 'updated_at', defaultValue: DataTypes.NOW },
    },
    {
      tableName: 'EqubRound',
      freezeTableName: true,
      timestamps: true,
      indexes: [
        { unique: true, fields: ['equb_id', 'round_number'] },
        { fields: ['equb_id'] },
        { fields: ['winner_id'] },
      ],
    }
  );
};

