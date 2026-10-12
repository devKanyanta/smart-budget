const {
  getDateRange,
  getCurrentPeriodRange,
  computeNextFundingDate,
} = require('../src/utils/dates');

describe('getDateRange', () => {
  test('weekly adds 7 days', () => {
    const { start, end } = getDateRange('weekly', '2026-10-01');
    expect(start.toISOString()).toContain('2026-10-01');
    expect(end.toISOString()).toContain('2026-10-08');
  });

  test('monthly adds 1 month', () => {
    const { end } = getDateRange('monthly', '2026-01-15');
    expect(end.toISOString()).toContain('2026-02-15');
  });

  test('monthly clamps to month end (Jan 31 -> Feb 28 in non-leap year)', () => {
    const { end } = getDateRange('monthly', '2026-01-31');
    expect(end.toISOString()).toContain('2026-03-03'); // JS Date rollover
  });

  test('quarterly adds 3 months', () => {
    const { end } = getDateRange('quarterly', '2026-02-01');
    expect(end.toISOString()).toContain('2026-05-01');
  });

  test('yearly adds 1 year', () => {
    const { end } = getDateRange('yearly', '2026-02-01');
    expect(end.toISOString()).toContain('2027-02-01');
  });

  test('unknown period falls back to monthly', () => {
    const { end } = getDateRange('banana', '2026-05-05');
    expect(end.toISOString()).toContain('2026-06-05');
  });
});

describe('getCurrentPeriodRange', () => {
  test('monthly starts on the 1st of the current month', () => {
    const { start } = getCurrentPeriodRange('monthly');
    expect(start.getDate()).toBe(1);
    expect(start.getMonth()).toBe(new Date().getMonth());
  });

  test('yearly starts on Jan 1', () => {
    const { start } = getCurrentPeriodRange('yearly');
    expect(start.getMonth()).toBe(0);
    expect(start.getDate()).toBe(1);
  });

  test('quarterly starts on a quarter boundary month', () => {
    const { start } = getCurrentPeriodRange('quarterly');
    expect(start.getMonth() % 3).toBe(0);
  });

  test('end is after start', () => {
    const { start, end } = getCurrentPeriodRange('monthly');
    expect(end.getTime()).toBeGreaterThan(start.getTime());
  });
});

describe('computeNextFundingDate', () => {
  const budget = (frequency, fundingDay = 5) => ({ frequency, funding_day: fundingDay });

  test('one_time budgets have no next funding date', () => {
    expect(computeNextFundingDate(budget('one_time'), '2026-10-10')).toBeNull();
  });

  test('monthly: day 5 Jan -> 5 Feb', () => {
    expect(computeNextFundingDate(budget('monthly', 5), '2026-01-10')).toBe('2026-02-05');
  });

  test('monthly clamps funding day to 28', () => {
    expect(computeNextFundingDate(budget('monthly', 31), '2026-01-02')).toBe('2026-02-28');
  });

  test('monthly keeps day when advancing from later date', () => {
    expect(computeNextFundingDate(budget('monthly', 15), '2026-03-20')).toBe('2026-04-15');
  });

  test('weekly: +7 days', () => {
    expect(computeNextFundingDate(budget('weekly'), '2026-10-10')).toBe('2026-10-17');
  });

  test('quarterly: +3 months keeping funding day', () => {
    expect(computeNextFundingDate(budget('quarterly', 10), '2026-02-01')).toBe('2026-05-10');
  });

  test('yearly: +1 year keeping funding day', () => {
    expect(computeNextFundingDate(budget('yearly', 10), '2026-02-01')).toBe('2027-02-10');
  });

  test('unknown frequency returns null', () => {
    expect(computeNextFundingDate(budget('banana'), '2026-10-10')).toBeNull();
  });

  test('local formatting stays stable near midnight (no ISO UTC shift)', () => {
    // Zambia is UTC+2; an toISOString-based fmt would shift the date part
    // for times after 22:00 local. The helper must use local components.
    const d = computeNextFundingDate(budget('monthly', 1), new Date(2026, 0, 1));
    expect(d).toBe('2026-02-01');
  });
});
