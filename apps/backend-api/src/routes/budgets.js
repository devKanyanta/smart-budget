const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const validate = require('../middleware/validate');
const { createBudgetSchema, updateBudgetSchema } = require('../validators/budgets');
const {
  listBudgets,
  getBudget,
  createBudget,
  updateBudget,
  deleteBudget,
  getBudgetSpending,
} = require('../controllers/budgets');

router.use(authenticate);

router.get('/', listBudgets);
router.get('/:id', getBudget);
router.post('/', validate(createBudgetSchema), createBudget);
router.put('/:id', validate(updateBudgetSchema), updateBudget);
router.delete('/:id', deleteBudget);
router.get('/:id/spending', getBudgetSpending);

module.exports = router;
