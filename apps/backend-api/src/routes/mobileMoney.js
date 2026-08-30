const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { connectAccountSchema } = require('../validators/mobileMoney');
const {
  listAccounts,
  connectAccount,
  disconnectAccount,
  triggerSync,
  getSyncStatus,
  getSyncLogs,
} = require('../controllers/mobileMoney');

router.use(authenticate);

router.get('/accounts', listAccounts);
router.post('/accounts', validate(connectAccountSchema), connectAccount);
router.delete('/accounts/:id', disconnectAccount);
router.post('/accounts/:id/sync', triggerSync);
router.get('/accounts/:id/sync-status', getSyncStatus);
router.get('/sync-logs', getSyncLogs);

module.exports = router;
