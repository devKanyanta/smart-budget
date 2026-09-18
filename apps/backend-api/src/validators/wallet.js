const { z } = require('zod');

const topUpSchema = z.object({
  body: z.object({
    amount: z.number().positive('Top-up amount must be positive').max(50000, 'Top-up amount exceeds maximum'),
    phone_number: z.string().min(9).max(20),
    network: z.enum(['airtel_money', 'mtn_momo']),
    description: z.string().max(255).optional(),
  }),
});

const paySchema = z.object({
  body: z.object({
    amount: z.number().positive('Payment amount must be positive'),
    description: z.string().max(255).optional(),
  }),
});

const limitsSchema = z.object({
  body: z.object({
    daily_limit: z.number().positive().nullable().optional(),
    monthly_limit: z.number().positive().nullable().optional(),
  }),
});

module.exports = { topUpSchema, paySchema, limitsSchema };
