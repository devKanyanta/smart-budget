const { z } = require('zod');

const createBudgetSchema = z.object({
  body: z.object({
    category_id: z.string().uuid().nullable().optional(),
    amount: z.number().positive('Budget amount must be positive'),
    period: z.enum(['weekly', 'monthly', 'quarterly', 'yearly']).optional(),
    start_date: z.string().date(),
    end_date: z.string().date().nullable().optional(),
    alert_threshold: z.number().min(0).max(100).optional(),
  }),
});

const updateBudgetSchema = z.object({
  body: z.object({
    amount: z.number().positive().optional(),
    period: z.enum(['weekly', 'monthly', 'quarterly', 'yearly']).optional(),
    end_date: z.string().date().nullable().optional(),
    is_active: z.boolean().optional(),
    alert_threshold: z.number().min(0).max(100).optional(),
  }),
});

module.exports = { createBudgetSchema, updateBudgetSchema };
