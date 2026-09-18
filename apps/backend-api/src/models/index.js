const sequelize = require('../config/database');
const User = require('./User');
const AdminUser = require('./AdminUser');
const RefreshToken = require('./RefreshToken');
const Category = require('./Category');
const Transaction = require('./Transaction');
const Budget = require('./Budget');
const SavingsGoal = require('./SavingsGoal');
const SavingsEntry = require('./SavingsEntry');
const MobileMoneyAccount = require('./MobileMoneyAccount');
const SyncLog = require('./SyncLog');
const Notification = require('./Notification');
const FinancialInsight = require('./FinancialInsight');
const AuditLog = require('./AuditLog');
const Wallet = require('./Wallet');
const WalletTransaction = require('./WalletTransaction');

// ─── Associations ────────────────────────────────────────────

// User ↔ AdminUser
User.hasOne(AdminUser, { foreignKey: 'user_id', as: 'adminRole' });
AdminUser.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User ↔ RefreshToken
User.hasMany(RefreshToken, { foreignKey: 'user_id', as: 'refreshTokens' });
RefreshToken.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User ↔ Category (custom categories)
User.hasMany(Category, { foreignKey: 'created_by', as: 'customCategories' });
Category.belongsTo(User, { foreignKey: 'created_by', as: 'creator' });

// User ↔ Transaction
User.hasMany(Transaction, { foreignKey: 'user_id', as: 'transactions' });
Transaction.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Category ↔ Transaction
Category.hasMany(Transaction, { foreignKey: 'category_id', as: 'transactions' });
Transaction.belongsTo(Category, { foreignKey: 'category_id', as: 'category' });

// User ↔ Budget
User.hasMany(Budget, { foreignKey: 'user_id', as: 'budgets' });
Budget.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Category ↔ Budget
Category.hasMany(Budget, { foreignKey: 'category_id', as: 'budgets' });
Budget.belongsTo(Category, { foreignKey: 'category_id', as: 'category' });

// User ↔ SavingsGoal
User.hasMany(SavingsGoal, { foreignKey: 'user_id', as: 'savingsGoals' });
SavingsGoal.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// SavingsGoal ↔ SavingsEntry
SavingsGoal.hasMany(SavingsEntry, { foreignKey: 'savings_goal_id', as: 'entries' });
SavingsEntry.belongsTo(SavingsGoal, { foreignKey: 'savings_goal_id', as: 'savingsGoal' });

// User ↔ MobileMoneyAccount
User.hasMany(MobileMoneyAccount, { foreignKey: 'user_id', as: 'mobileMoneyAccounts' });
MobileMoneyAccount.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// MobileMoneyAccount ↔ SyncLog
MobileMoneyAccount.hasMany(SyncLog, { foreignKey: 'mobile_money_account_id', as: 'syncLogs' });
SyncLog.belongsTo(MobileMoneyAccount, { foreignKey: 'mobile_money_account_id', as: 'account' });

// User ↔ Notification
User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User ↔ FinancialInsight
User.hasMany(FinancialInsight, { foreignKey: 'user_id', as: 'financialInsights' });
FinancialInsight.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User ↔ AuditLog
User.hasMany(AuditLog, { foreignKey: 'actor_id', as: 'auditActions' });
AuditLog.belongsTo(User, { foreignKey: 'actor_id', as: 'actor' });

// User ↔ Wallet (one per user)
User.hasOne(Wallet, { foreignKey: 'user_id', as: 'wallet' });
Wallet.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// Wallet ↔ WalletTransaction
Wallet.hasMany(WalletTransaction, { foreignKey: 'wallet_id', as: 'transactions' });
WalletTransaction.belongsTo(Wallet, { foreignKey: 'wallet_id', as: 'wallet' });

module.exports = {
  sequelize,
  User,
  AdminUser,
  RefreshToken,
  Category,
  Transaction,
  Budget,
  SavingsGoal,
  SavingsEntry,
  MobileMoneyAccount,
  SyncLog,
  Notification,
  FinancialInsight,
  AuditLog,
  Wallet,
  WalletTransaction,
};
