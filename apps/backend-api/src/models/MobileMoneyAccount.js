const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const MobileMoneyAccount = sequelize.define('MobileMoneyAccount', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'users', key: 'id' },
  },
  provider: {
    type: DataTypes.ENUM('airtel_money', 'mtn_momo'),
    allowNull: false,
  },
  phone_number: {
    type: DataTypes.STRING(20),
    allowNull: false,
  },
  display_name: {
    type: DataTypes.STRING(255),
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  last_synced_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  sync_status: {
    type: DataTypes.ENUM('synced', 'syncing', 'error', 'pending'),
    defaultValue: 'pending',
  },
}, {
  tableName: 'mobile_money_accounts',
});

module.exports = MobileMoneyAccount;
