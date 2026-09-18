const express = require('express');
const rateLimit = require('express-rate-limit');
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const {
  topUpSchema,
  paySchema,
  limitsSchema,
} = require('../validators/wallet');
const {
  getWallet,
  topUp,
  listWalletTransactions,
  payFromWallet,
  updateLimits,
  webhook,
} = require('../controllers/wallet');

const router = express.Router();

// Stricter rate limiting on payment endpoints
const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: { code: 'RATE_LIMIT', message: 'Too many payment requests, please try again later.' } },
});

// Public routes (no auth) — webhook must be reachable by the provider
router.post('/webhook', webhook);

// Authenticated routes
router.use(authenticate);

router.get('/', getWallet);
router.post('/topup', paymentLimiter, validate(topUpSchema), topUp);
router.post('/pay', paymentLimiter, validate(paySchema), payFromWallet);
router.get('/transactions', listWalletTransactions);
router.put('/limits', validate(limitsSchema), updateLimits);

module.exports = router;
