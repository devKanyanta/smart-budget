const { v4: uuidv4 } = require('uuid');
const { Wallet, WalletTransaction, Notification, AuditLog, sequelize } = require('../models');
const flw = require('../services/flutterwave');

/**
 * Get or create the user's wallet.
 */
async function getOrCreateWallet(userId) {
  let wallet = await Wallet.findOne({ where: { user_id: userId } });
  if (!wallet) {
    wallet = await Wallet.create({ user_id: userId, balance: 0 });
  }
  return wallet;
}

// GET /api/v1/wallet
const getWallet = async (req, res, next) => {
  try {
    const wallet = await getOrCreateWallet(req.userId);
    res.json({
      success: true,
      data: {
        ...wallet.toJSON(),
        payment_mode: flw.isLiveMode() ? 'live' : 'simulated',
      },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/v1/wallet/topup
const topUp = async (req, res, next) => {
  try {
    const { amount, phone_number, network, description } = req.validated.body;
    const wallet = await getOrCreateWallet(req.userId);

    if (wallet.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: { code: 'WALLET_INACTIVE', message: 'Wallet is not active' },
      });
    }

    const txRef = `SBZ-${uuidv4()}`;
    const providerName = 'flutterwave';
    const providerRef = `${providerName}:${txRef}`;

    // Initiate charge with the payment provider (Flutterwave / simulated)
    const charge = await flw.initiateMobileMoneyCharge({
      txRef,
      amount: parseFloat(amount),
      phoneNumber: phone_number,
      network: network === 'mtn_momo' ? 'MTN' : 'AIRTEL',
      redirectUrl: `${process.env.APP_BASE_URL || 'http://localhost:3000'}/api/v1/wallet/redirect`,
    });

    const walletTx = await WalletTransaction.create({
      wallet_id: wallet.id,
      type: 'topup',
      amount,
      balance_after: parseFloat(wallet.balance),
      status: charge.mode === 'simulated' ? 'completed' : charge.status === 'successful' ? 'completed' : 'pending',
      provider: providerName,
      provider_reference: providerRef,
      phone_number,
      description: description || `Wallet top-up via ${network === 'mtn_momo' ? 'MTN MoMo' : 'Airtel Money'}`,
      meta: {
        mode: charge.mode,
        payment_link: charge.link || null,
        processor_response: charge.processorResponse || null,
      },
    });

    // In simulated mode the "payment" succeeds immediately: credit the wallet now.
    if (walletTx.status === 'completed') {
      wallet.balance = parseFloat(wallet.balance) + parseFloat(amount);
      await wallet.save();
      await walletTx.update({ balance_after: wallet.balance });
    }

    await AuditLog.create({
      actor_id: req.userId,
      actor_type: 'user',
      action: 'wallet.topup',
      resource_type: 'wallet_transaction',
      resource_id: walletTx.id,
      details: { amount, mode: charge.mode, provider_reference: providerRef },
      ip_address: req.ip,
    });

    res.status(201).json({
      success: true,
      data: {
        transaction: walletTx,
        payment_link: charge.link || null,
        mode: charge.mode,
        message: charge.mode === 'simulated'
          ? `Simulated top-up successful. K${parseFloat(amount).toFixed(2)} credited (sandbox mode — no real money moved).`
          : 'Top-up initiated. Complete the payment on your phone or via the payment link.',
      },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/wallet/transactions
const listWalletTransactions = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, type } = req.query;
    const wallet = await getOrCreateWallet(req.userId);

    const where = { wallet_id: wallet.id };
    if (type) where.type = type;

    const { count, rows } = await WalletTransaction.findAndCountAll({
      where,
      order: [['created_at', 'DESC']],
      limit: Math.min(parseInt(limit), 100),
      offset: (parseInt(page) - 1) * parseInt(limit),
    });

    res.json({
      success: true,
      data: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(count / parseInt(limit)),
      },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/v1/wallet/pay
const payFromWallet = async (req, res, next) => {
  try {
    const { amount, description } = req.validated.body;
    const wallet = await getOrCreateWallet(req.userId);

    const amt = parseFloat(amount);

    if (wallet.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: { code: 'WALLET_INACTIVE', message: 'Wallet is not active' },
      });
    }

    if (parseFloat(wallet.balance) < amt) {
      return res.status(400).json({
        success: false,
        error: { code: 'INSUFFICIENT_FUNDS', message: `Insufficient balance. Available: K${parseFloat(wallet.balance).toFixed(2)}` },
      });
    }

    // ── Spending controls: daily / monthly wallet limits ──
    const now = new Date();
    const violations = [];

    // Daily limit
    if (wallet.daily_limit) {
      const dailyLimit = parseFloat(wallet.daily_limit);
      const lastReset = wallet.daily_spent_at ? new Date(wallet.daily_spent_at) : null;
      const isSameDay = lastReset && lastReset.toDateString() === now.toDateString();
      const dailySpent = isSameDay ? parseFloat(wallet.daily_spent) : 0;

      if (dailySpent + amt > dailyLimit) {
        violations.push({
          control: 'daily_limit',
          limit: dailyLimit,
          spent_today: dailySpent,
          message: `Daily wallet limit of K${dailyLimit.toFixed(2)} would be exceeded (K${dailySpent.toFixed(2)} spent today).`,
        });
      }
    }

    // Monthly limit
    if (wallet.monthly_limit) {
      const monthlyLimit = parseFloat(wallet.monthly_limit);
      const lastReset = wallet.monthly_spent_at ? new Date(wallet.monthly_spent_at) : null;
      const isSameMonth = lastReset && lastReset.getMonth() === now.getMonth() && lastReset.getFullYear() === now.getFullYear();
      const monthlySpent = isSameMonth ? parseFloat(wallet.monthly_spent) : 0;

      if (monthlySpent + amt > monthlyLimit) {
        violations.push({
          control: 'monthly_limit',
          limit: monthlyLimit,
          spent_this_month: monthlySpent,
          message: `Monthly wallet limit of K${monthlyLimit.toFixed(2)} would be exceeded (K${monthlySpent.toFixed(2)} spent this month).`,
        });
      }
    }

    if (violations.length > 0) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'SPENDING_LIMIT_EXCEEDED',
          message: violations[0].message,
          details: violations,
        },
      });
    }

    // Debit atomically
    const result = await sequelize.transaction(async (t) => {
      const freshWallet = await Wallet.findByPk(wallet.id, { transaction: t, lock: t.LOCK.UPDATE });
      if (parseFloat(freshWallet.balance) < amt) {
        throw Object.assign(new Error('Insufficient balance'), { statusCode: 400, code: 'INSUFFICIENT_FUNDS' });
      }
      freshWallet.balance = parseFloat(freshWallet.balance) - amt;

      // Update rolling daily/monthly spend trackers
      const lastDaily = freshWallet.daily_spent_at ? new Date(freshWallet.daily_spent_at) : null;
      if (!lastDaily || lastDaily.toDateString() !== now.toDateString()) {
        freshWallet.daily_spent = amt;
      } else {
        freshWallet.daily_spent = parseFloat(freshWallet.daily_spent) + amt;
      }
      freshWallet.daily_spent_at = now;

      const lastMonthly = freshWallet.monthly_spent_at ? new Date(freshWallet.monthly_spent_at) : null;
      if (!lastMonthly || lastMonthly.getMonth() !== now.getMonth() || lastMonthly.getFullYear() !== now.getFullYear()) {
        freshWallet.monthly_spent = amt;
      } else {
        freshWallet.monthly_spent = parseFloat(freshWallet.monthly_spent) + amt;
      }
      freshWallet.monthly_spent_at = now;

      await freshWallet.save({ transaction: t });

      const walletTx = await WalletTransaction.create({
        wallet_id: freshWallet.id,
        type: 'payment',
        amount: amt,
        balance_after: freshWallet.balance,
        status: 'completed',
        description: description || 'Wallet payment',
      }, { transaction: t });

      return { freshWallet, walletTx };
    });

    await AuditLog.create({
      actor_id: req.userId,
      actor_type: 'user',
      action: 'wallet.payment',
      resource_type: 'wallet_transaction',
      resource_id: result.walletTx.id,
      details: { amount: amt, balance_after: result.freshWallet.balance },
      ip_address: req.ip,
    });

    res.status(201).json({
      success: true,
      data: {
        transaction: result.walletTx,
        balance: result.freshWallet.balance,
      },
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/v1/wallet/limits
const updateLimits = async (req, res, next) => {
  try {
    const { daily_limit, monthly_limit } = req.validated.body;
    const wallet = await getOrCreateWallet(req.userId);

    if (daily_limit !== undefined) wallet.daily_limit = daily_limit;
    if (monthly_limit !== undefined) wallet.monthly_limit = monthly_limit;
    await wallet.save();

    res.json({ success: true, data: wallet });
  } catch (error) {
    next(error);
  }
};

/**
 * Flutterwave webhook (POST /api/v1/wallet/webhook).
 * Verifies the payload signature when FLW_SECRET_HASH is configured,
 * then credits the wallet for successful top-ups (live mode only).
 */
const webhook = async (req, res, next) => {
  try {
    const secretHash = process.env.FLW_SECRET_HASH;
    if (secretHash) {
      const signature = req.headers['verif-hash'];
      if (!signature || signature !== secretHash) {
        return res.status(401).json({ success: false, error: { code: 'INVALID_SIGNATURE', message: 'Invalid webhook signature' } });
      }
    }

    const event = req.body;
    if (event['event.type'] !== 'Mobile money transaction' && event.type !== 'mobile_money_zambia') {
      // Accept generic charge.completed events for any wallet top-up
    }

    const data = event.data || {};
    const txRef = data.tx_ref;

    if (!txRef) {
      return res.status(400).json({ success: false, error: { code: 'INVALID_PAYLOAD', message: 'Missing tx_ref' } });
    }

    const walletTx = await WalletTransaction.findOne({ where: { provider_reference: `flutterwave:${txRef}` } });
    if (!walletTx) {
      return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'Transaction not found' } });
    }

    if (walletTx.status === 'completed') {
      return res.json({ success: true, data: { message: 'Already processed' } });
    }

    if (data.status === 'successful') {
      await sequelize.transaction(async (t) => {
        const wallet = await Wallet.findByPk(walletTx.wallet_id, { transaction: t, lock: t.LOCK.UPDATE });
        wallet.balance = parseFloat(wallet.balance) + parseFloat(walletTx.amount);
        await wallet.save({ transaction: t });
        await walletTx.update({
          status: 'completed',
          balance_after: wallet.balance,
          provider_tx_id: data.id ? String(data.id) : null,
        }, { transaction: t });
      });

      // Notify user of successful top-up
      const wallet = await Wallet.findByPk(walletTx.wallet_id);
      await Notification.create({
        user_id: wallet.user_id,
        type: 'general',
        title: 'Wallet top-up successful',
        body: `K${parseFloat(walletTx.amount).toFixed(2)} has been credited to your wallet.`,
      });
    } else {
      await walletTx.update({ status: 'failed' });
    }

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getWallet,
  topUp,
  listWalletTransactions,
  payFromWallet,
  updateLimits,
  webhook,
  getOrCreateWallet,
};
