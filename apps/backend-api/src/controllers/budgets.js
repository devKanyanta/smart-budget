const { Budget, Category, Transaction } = require('../models');
const { getCurrentPeriodRange } = require('../utils/dates');
const { Op } = require('sequelize');
const {
  computeBudgetSpending,
  evaluateBudgetAlerts,
  checkSpendingControls,
  predictBudgetExhaustion,
} = require('../services/budgetAlerts');

// GET /api/v1/budgets
const listBudgets = async (req, res, next) => {
  try {
    const budgets = await Budget.findAll({
      where: { user_id: req.userId },
      include: [
        { model: Category, as: 'category', attributes: ['id', 'name', 'icon', 'color'] },
      ],
      order: [['created_at', 'DESC']],
    });

    // Calculate spent amounts for each budget
    const results = await Promise.all(budgets.map(async (budget) => {
      const { spent, remaining, percentage } = await computeBudgetSpending(budget);

      return {
        ...budget.toJSON(),
        spent_amount: spent,
        remaining,
        percentage_used: percentage,
        status: percentage > 100 ? 'exceeded' : percentage >= (parseFloat(budget.alert_threshold) || 80) ? 'warning' : 'ok',
      };
    }));

    res.json({ success: true, data: results });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/budgets/alerts — evaluate + return budget warnings/notifications
const getBudgetAlerts = async (req, res, next) => {
  try {
    const alerts = await evaluateBudgetAlerts(req.userId);
    res.json({ success: true, data: alerts });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/budgets/prediction — ML overspending / exhaustion prediction
const getBudgetPrediction = async (req, res, next) => {
  try {
    const prediction = await predictBudgetExhaustion(req.userId);
    res.json({ success: true, data: prediction });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/budgets/:id
const getBudget = async (req, res, next) => {
  try {
    const budget = await Budget.findOne({
      where: { id: req.params.id, user_id: req.userId },
      include: [
        { model: Category, as: 'category', attributes: ['id', 'name', 'icon', 'color'] },
      ],
    });

    if (!budget) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Budget not found' },
      });
    }

    const { spent, remaining, percentage } = await computeBudgetSpending(budget);
    const { start, end } = getCurrentPeriodRange(budget.period);

    const transactions = await Transaction.findAll({
      where: {
        user_id: req.userId,
        type: 'expense',
        transaction_date: { [Op.gte]: start, [Op.lt]: end },
        ...(budget.category_id ? { category_id: budget.category_id } : {}),
      },
      include: [{ model: Category, as: 'category', attributes: ['id', 'name', 'icon', 'color'] }],
      order: [['transaction_date', 'DESC']],
    });

    res.json({
      success: true,
      data: {
        ...budget.toJSON(),
        spent_amount: spent,
        remaining,
        percentage_used: percentage,
        transaction_count: transactions.length,
      },
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/v1/budgets
const createBudget = async (req, res, next) => {
  try {
    const { category_id, amount, period, start_date, end_date, alert_threshold, enforce } = req.validated.body;

    const budget = await Budget.create({
      user_id: req.userId,
      category_id: category_id || null,
      amount,
      period: period || 'monthly',
      start_date,
      end_date: end_date || null,
      alert_threshold: alert_threshold || 80,
      enforce: enforce || false,
    });

    const result = await Budget.findByPk(budget.id, {
      include: [{ model: Category, as: 'category', attributes: ['id', 'name', 'icon', 'color'] }],
    });

    res.status(201).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

// PUT /api/v1/budgets/:id
const updateBudget = async (req, res, next) => {
  try {
    const budget = await Budget.findOne({
      where: { id: req.params.id, user_id: req.userId },
    });

    if (!budget) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Budget not found' },
      });
    }

    const updates = req.validated.body;
    if (updates.amount !== undefined) budget.amount = updates.amount;
    if (updates.period) budget.period = updates.period;
    if (updates.end_date !== undefined) budget.end_date = updates.end_date;
    if (updates.is_active !== undefined) budget.is_active = updates.is_active;
    if (updates.alert_threshold !== undefined) budget.alert_threshold = updates.alert_threshold;
    if (updates.enforce !== undefined) budget.enforce = updates.enforce;

    await budget.save();

    const result = await Budget.findByPk(budget.id, {
      include: [{ model: Category, as: 'category', attributes: ['id', 'name', 'icon', 'color'] }],
    });

    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/v1/budgets/:id
const deleteBudget = async (req, res, next) => {
  try {
    const budget = await Budget.findOne({
      where: { id: req.params.id, user_id: req.userId },
    });

    if (!budget) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Budget not found' },
      });
    }

    await budget.destroy();
    res.json({ success: true, data: { message: 'Budget deleted' } });
  } catch (error) {
    next(error);
  }
};

// GET /api/v1/budgets/:id/spending
const getBudgetSpending = async (req, res, next) => {
  try {
    const budget = await Budget.findOne({
      where: { id: req.params.id, user_id: req.userId },
    });

    if (!budget) {
      return res.status(404).json({
        success: false,
        error: { code: 'NOT_FOUND', message: 'Budget not found' },
      });
    }

    const { start, end } = getCurrentPeriodRange(budget.period);
    const where = {
      user_id: req.userId,
      type: 'expense',
      transaction_date: { [Op.gte]: start, [Op.lt]: end },
    };
    if (budget.category_id) where.category_id = budget.category_id;

    const transactions = await Transaction.findAll({
      where,
      include: [{ model: Category, as: 'category', attributes: ['id', 'name', 'icon', 'color'] }],
      order: [['transaction_date', 'DESC']],
    });

    // Group by category
    const categorySpending = {};
    transactions.forEach((t) => {
      const catName = t.category?.name || 'Uncategorized';
      if (!categorySpending[catName]) {
        categorySpending[catName] = { amount: 0, count: 0, category: t.category };
      }
      categorySpending[catName].amount += parseFloat(t.amount);
      categorySpending[catName].count += 1;
    });

    res.json({
      success: true,
      data: {
        budget_id: budget.id,
        period: { start, end },
        total_spent: transactions.reduce((sum, t) => sum + parseFloat(t.amount), 0),
        categories: categorySpending,
        transactions: transactions.slice(0, 50),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  listBudgets,
  getBudget,
  createBudget,
  updateBudget,
  deleteBudget,
  getBudgetSpending,
  getBudgetAlerts,
  getBudgetPrediction,
  checkSpendingControls,
};
