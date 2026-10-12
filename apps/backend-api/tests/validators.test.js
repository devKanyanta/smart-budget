const {
  registerSchema,
  loginSchema,
} = require('../src/validators/auth');
const {
  createBudgetSchema,
} = require('../src/validators/budgets');
const {
  createTransactionSchema,
  transactionQuerySchema,
} = require('../src/validators/transactions');
const {
  createSavingsGoalSchema,
  addSavingsEntrySchema,
} = require('../src/validators/savings');
const { paySchema, limitsSchema } = require('../src/validators/wallet');

/** Run a zod body-only validator and return { passes, details, code } */
const runBody = (schema, body) => {
  const result = schema.safeParse({ body, query: {}, params: {} });
  if (result.success) return { passes: true, data: result.data };
  return {
    passes: false,
    details: result.error.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    })),
  };
};

describe('auth validator — registration', () => {
  const valid = {
    email: 'student@unza.zm',
    full_name: 'Chanda Mwansa',
    password: 'Passw0rd1',
    confirm_password: 'Passw0rd1',
  };

  test('accepts a valid registration', () => {
    expect(runBody(registerSchema, valid).passes).toBe(true);
  });

  test('accepts optional phone number', () => {
    expect(runBody(registerSchema, { ...valid, phone_number: '0977123456' }).passes).toBe(true);
  });

  test('rejects invalid email', () => {
    const r = runBody(registerSchema, { ...valid, email: 'not-an-email' });
    expect(r.passes).toBe(false);
    expect(r.details.some((d) => d.field === 'body.email')).toBe(true);
  });

  test('rejects short names', () => {
    const r = runBody(registerSchema, { ...valid, full_name: 'A' });
    expect(r.details[0].message).toContain('at least 2');
  });

  test('rejects short passwords', () => {
    const r = runBody(registerSchema, { ...valid, password: 'Aa1', confirm_password: 'Aa1' });
    expect(r.details.some((d) => d.message.includes('at least 8'))).toBe(true);
  });

  test('rejects passwords without a number', () => {
    const r = runBody(registerSchema, { ...valid, password: 'Password', confirm_password: 'Password' });
    expect(r.details.some((d) => d.message.includes('number'))).toBe(true);
  });

  test('rejects mismatched confirm_password', () => {
    const r = runBody(registerSchema, { ...valid, confirm_password: 'Passw0rd2' });
    expect(r.details.some((d) => d.field === 'body.confirm_password')).toBe(true);
  });
});

describe('auth validator — login', () => {
  test('accepts valid login payload', () => {
    expect(runBody(loginSchema, { email: 'a@b.com', password: 'whatever' }).passes).toBe(true);
  });

  test('rejects missing password', () => {
    const r = runBody(loginSchema, { email: 'a@b.com', password: '' });
    expect(r.passes).toBe(false);
  });
});

describe('budget validator — create', () => {
  const categoryId = 'bd444654-dbe3-42d8-8fcd-b8f34cc52589';
  const valid = {
    name: 'October Budget',
    amount: 3000,
    period: 'monthly',
    start_date: '2026-10-01',
    allocations: [{ category_id: categoryId, amount: 2000 }],
  };

  test('accepts a valid budget with allocations', () => {
    expect(runBody(createBudgetSchema, valid).passes).toBe(true);
  });

  test('accepts budget without allocations (plain budget)', () => {
    const { allocations, ...noAlloc } = valid;
    expect(runBody(createBudgetSchema, noAlloc).passes).toBe(true);
  });

  test('rejects non-positive amount', () => {
    const r = runBody(createBudgetSchema, { ...valid, amount: 0 });
    expect(r.details.some((d) => d.message.includes('positive'))).toBe(true);
  });

  test('rejects allocations exceeding budget amount', () => {
    const r = runBody(createBudgetSchema, {
      ...valid,
      amount: 1000,
      allocations: [
        { category_id: categoryId, amount: 800 },
        { category_id: categoryId, amount: 500 },
      ],
    });
    expect(r.passes).toBe(false);
  });

  test('rejects allocation sums just over the budget (rounding guard)', () => {
    const r = runBody(createBudgetSchema, {
      ...valid,
      amount: 10,
      allocations: [{ category_id: categoryId, amount: 10.01 }],
    });
    expect(r.passes).toBe(false);
  });

  test('rejects invalid frequency', () => {
    const r = runBody(createBudgetSchema, { ...valid, frequency: 'fortnightly' });
    expect(r.passes).toBe(false);
  });

  test('rejects funding day outside 1-28', () => {
    const r = runBody(createBudgetSchema, { ...valid, funding_day: 31 });
    expect(r.passes).toBe(false);
  });

  test('rejects non-uuid category in allocation', () => {
    const r = runBody(createBudgetSchema, {
      ...valid,
      allocations: [{ category_id: 'food', amount: 100 }],
    });
    expect(r.passes).toBe(false);
  });
});

describe('transaction validator — create', () => {
  const valid = {
    amount: 250,
    type: 'expense',
    transaction_date: '2026-10-12T08:00:00.000Z',
  };

  test('accepts a valid transaction', () => {
    expect(runBody(createTransactionSchema, valid).passes).toBe(true);
  });

  test('accepts local date-only strings', () => {
    // z.string().datetime().or(z.string().date()) allows both
    expect(runBody(createTransactionSchema, { ...valid, transaction_date: '2026-10-12' }).passes)
      .toBe(true);
  });

  test('rejects timezone-less full timestamps (the Flutter bug)', () => {
    const r = runBody(createTransactionSchema, {
      ...valid,
      transaction_date: '2026-10-12T09:00:00.000',
    });
    expect(r.passes).toBe(false);
  });

  test('rejects invalid type', () => {
    const r = runBody(createTransactionSchema, { ...valid, type: 'donation' });
    expect(r.passes).toBe(false);
  });

  test('rejects negative amounts', () => {
    const r = runBody(createTransactionSchema, { ...valid, amount: -5 });
    expect(r.passes).toBe(false);
  });

  test('list query schema coerces page numbers', () => {
    const result = transactionQuerySchema.safeParse({ query: { page: '2', limit: '50' } });
    expect(result.success).toBe(true);
    expect(result.data.query.page).toBe(2);
  });

  test('list query rejects limit above 100', () => {
    const result = transactionQuerySchema.safeParse({ query: { limit: '250' } });
    expect(result.success).toBe(false);
  });
});

describe('savings validator', () => {
  test('accepts a valid goal', () => {
    expect(
      runBody(createSavingsGoalSchema, {
        name: 'Laptop',
        target_amount: 8000,
        target_date: '2026-12-31',
        frequency: 'monthly',
      }).passes
    ).toBe(true);
  });

  test('rejects invalid target date', () => {
    const r = runBody(createSavingsGoalSchema, {
      name: 'Laptop',
      target_amount: 100,
      target_date: 'tomorrow',
    });
    expect(r.passes).toBe(false);
  });

  test('rejects non-positive entry amount', () => {
    const r = runBody(addSavingsEntrySchema, { amount: 0, entry_date: '2026-10-12' });
    expect(r.passes).toBe(false);
  });
});

describe('wallet validator', () => {
  test('pay requires positive amount', () => {
    expect(runBody(paySchema, { amount: 50 }).passes).toBe(true);
    expect(runBody(paySchema, { amount: 0 }).passes).toBe(false);
  });

  test('pay accepts nullable category', () => {
    expect(runBody(paySchema, { amount: 50, category_id: null }).passes).toBe(true);
  });

  test('pay rejects non-uuid category', () => {
    expect(runBody(paySchema, { amount: 50, category_id: 'food' }).passes).toBe(false);
  });

  test('limits accepts nullable limits', () => {
    expect(runBody(limitsSchema, { daily_limit: null, monthly_limit: null }).passes).toBe(true);
  });

  test('limits rejects negative values', () => {
    expect(runBody(limitsSchema, { daily_limit: -1 }).passes).toBe(false);
  });
});
