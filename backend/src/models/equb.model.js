module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Equb',
    {
      id: {
        type: DataTypes.STRING(36),
        primaryKey: true,
        defaultValue: DataTypes.UUIDV4,
      },
      name: { type: DataTypes.STRING(120), allowNull: false },
      description: { type: DataTypes.TEXT, allowNull: true },
      type: {
        type: DataTypes.ENUM('PUBLIC', 'PRIVATE', 'CORPORATE', 'PARTNERSHIP'),
        allowNull: false,
        defaultValue: 'PRIVATE',
      },
      equbType: { type: DataTypes.STRING(60), allowNull: true, field: 'equb_type' },
      contributionAmount: {
        type: DataTypes.DECIMAL(12, 2),
        allowNull: false,
        field: 'contribution_amount',
      },
      currency: { type: DataTypes.STRING(5), allowNull: false, defaultValue: 'ETB' },
      frequency: {
        type: DataTypes.ENUM('WEEKLY', 'BIWEEKLY', 'MONTHLY'),
        allowNull: false,
        defaultValue: 'MONTHLY',
      },
      payoutOrderType: {
        type: DataTypes.ENUM('FIXED_ORDER', 'LOTTERY', 'BIDDING', 'NEED_BASED'),
        allowNull: false,
        defaultValue: 'FIXED_ORDER',
        field: 'payout_order_type',
      },
      maxMembers: { type: DataTypes.INTEGER, allowNull: false, field: 'max_members' },
      currentCycleNumber: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0,
        field: 'current_cycle_number',
      },
      inviteCode: { type: DataTypes.STRING(20), allowNull: true, unique: true, field: 'invite_code' },
      isInviteOnly: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false, field: 'is_invite_only' },
      status: {
        type: DataTypes.ENUM('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED'),
        allowNull: false,
        defaultValue: 'DRAFT',
      },
      memberType: {
        type: DataTypes.ENUM('MERCHANT', 'EMPLOYEE', 'MEMBER', 'ORGANIZER'),
        allowNull: false,
        defaultValue: 'MEMBER',
        field: 'member_type',
      },
      startDate: { type: DataTypes.DATEONLY, allowNull: true, field: 'start_date' },
      endDate: { type: DataTypes.DATEONLY, allowNull: true, field: 'end_date' },
      bankName: { type: DataTypes.STRING(120), allowNull: true, field: 'bank_name' },
      bankAccountName: { type: DataTypes.STRING(120), allowNull: true, field: 'bank_account_name' },
      bankAccountNumber: { type: DataTypes.STRING(50), allowNull: true, field: 'bank_account_number' },
      bankInstructions: { type: DataTypes.TEXT, allowNull: true, field: 'bank_instructions' },
      organizerId: { type: DataTypes.STRING(36), allowNull: true, field: 'organizer_id' },
      createdAt: { type: DataTypes.DATE, allowNull: false, field: 'created_at', defaultValue: DataTypes.NOW },
      updatedAt: { type: DataTypes.DATE, allowNull: false, field: 'updated_at', defaultValue: DataTypes.NOW },
    },
    {
      tableName: 'Equb',
      freezeTableName: true,
      timestamps: true,
      indexes: [{ fields: ['organizer_id'] }, { fields: ['status'] }, { fields: ['invite_code'] }],
    }
  );
};

