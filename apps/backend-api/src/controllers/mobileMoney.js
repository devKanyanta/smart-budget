const { MobileMoneyAccount, SyncLog } = require('../models');

// GET /api/v1/mobile-money/accounts
const listAccounts = async (req, res, next) => {
  try {
    const accounts = await MobileMoneyAccount.findAll({
      where: { user_id: req.userId },
      order: [['created_at', 'DESC']],
    });
    res.json({ success: true, data: accounts });
  } catch (error) {
    next(error);
  }
};

// POST /api/v1/mobile-money/accounts
const connectAccount = async (req, res, next) => {
  try {
    const { provider, phone_number, display_name } = req.validated.body;

    const account = await MobileMoneyAccount.create({
      user_id: req.userId,
      provider,
      phone_number,
      display_name: display_name || `${provider} (${phone_number})`,
      sync_status: 'pending',
    });

    res.status(201).json({ success: true, data: account });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/v1/mobile-money/accounts/:id
const disconnectAccount = async (req, res, next) => {
  try {
    const account = await MobileMoneyAccount.findOne({
      where: { id: req.params.id, user_id: req.userId },
    });

    if (!account) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Account not found' },
      });
    }

    await account.destroy();
    res.json({ success: true, data: { message: 'Account disconnected' } });
  } catch (error) {
    next(error);
  }
};

// POST /api/v1/mobile-money/accounts/:id/sync
const triggerSync = async (req, res, next) => {
  try {
    const account = await MobileMoneyAccount.findOne({
      where: { id: req.params.id, user_id: req.userId },
    });

    if (!account) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Account not found' },
      });
    }

    // Update status to syncing
    account.sync_status = 'syncing';
    await account.save();

    // In production, this would call the actual mobile money API
    // For now, simulate a sync operation
    const syncLog = await SyncLog.create({
      mobile_money_account_id: account.id,
      status: 'success',
      transactions_synced: 0,
      error_message: null,
    });

    account.sync_status = 'synced';
    account.last_synced_at = new Date();
    await account.save();

    res.json({
      success: true,
      data: {
        message: 'Sync completed (integration layer ready)',
        sync_log: syncLog,
        account,
      },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/mobile-money/accounts/:id/sync-status
const getSyncStatus = async (req, res, next) => {
  try {
    const account = await MobileMoneyAccount.findOne({
      where: { id: req.params.id, user_id: req.userId },
    });

    if (!account) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Account not found' },
      });
    }

    res.json({
      success: true,
      data: {
        account_id: account.id,
        sync_status: account.sync_status,
        last_synced_at: account.last_synced_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/mobile-money/sync-logs
const getSyncLogs = async (req, res, next) => {
  try {
    const accounts = await MobileMoneyAccount.findAll({
      where: { user_id: req.userId },
      attributes: ['id'],
    });
    const accountIds = accounts.map((a) => a.id);

    const logs = await SyncLog.findAll({
      where: { mobile_money_account_id: accountIds },
      order: [['created_at', 'DESC']],
      limit: 50,
    });

    res.json({ success: true, data: logs });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listAccounts,
  connectAccount,
  disconnectAccount,
  triggerSync,
  getSyncStatus,
  getSyncLogs,
};
