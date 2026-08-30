const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const SyncLog = sequelize.define('SyncLog', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  mobile_money_account_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'mobile_money_accounts', key: 'id' },
  },
  status: {
    type: DataTypes.ENUM('success', 'failed', 'partial'),
    allowNull: false,
  },
  transactions_synced: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  error_message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'sync_logs',
});

module.exports = SyncLog;
