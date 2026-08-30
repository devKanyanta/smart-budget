const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Budget = sequelize.define('Budget', {
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
  category_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: { model: 'categories', key: 'id' },
  },
  amount: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
  },
  period: {
    type: DataTypes.ENUM('weekly', 'monthly', 'quarterly', 'yearly'),
    defaultValue: 'monthly',
  },
  start_date: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  end_date: {
    type: DataTypes.DATEONLY,
    allowNull: true,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  alert_threshold: {
    type: DataTypes.DECIMAL(5, 2),
    defaultValue: 80.0,
  },
}, {
  tableName: 'budgets',
});

module.exports = Budget;
