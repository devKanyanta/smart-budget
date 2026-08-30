const { z } = require('zod');

const connectAccountSchema = z.object({
  body: z.object({
    provider: z.enum(['airtel_money', 'mtn_momo']),
    phone_number: z.string().min(10, 'Invalid phone number').max(20),
    display_name: z.string().max(255).optional(),
  }),
});

module.exports = { connectAccountSchema };
