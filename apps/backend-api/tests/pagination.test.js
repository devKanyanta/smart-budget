const { paginate, buildPaginationResponse } = require('../src/utils/pagination');

describe('paginate', () => {
  test('page 1 has zero offset', () => {
    const q = paginate({ where: { id: 'x' } }, 1, 20);
    expect(q.offset).toBe(0);
    expect(q.limit).toBe(20);
    expect(q.where).toEqual({ id: 'x' });
  });

  test('page 3, limit 20 -> offset 40', () => {
    expect(paginate({}, 3, 20).offset).toBe(40);
  });

  test('limit is capped at 100', () => {
    expect(paginate({}, 1, 500).limit).toBe(100);
  });

  test('default page/limit when omitted', () => {
    const q = paginate({});
    expect(q.offset).toBe(0);
    expect(q.limit).toBe(20);
  });
});

describe('buildPaginationResponse', () => {
  test('computes totalPages, hasNext, hasPrev', () => {
    const r = buildPaginationResponse([1, 2, 3], 45, 2, 20);
    expect(r.data).toEqual([1, 2, 3]);
    expect(r.pagination).toEqual({
      total: 45,
      page: 2,
      limit: 20,
      totalPages: 3,
      hasNext: true,
      hasPrev: true,
    });
  });

  test('empty result set has zero totalPages and no next/prev', () => {
    const r = buildPaginationResponse([], 0, 1, 20);
    expect(r.pagination.totalPages).toBe(0);
    expect(r.pagination.hasNext).toBe(false);
    expect(r.pagination.hasPrev).toBe(false);
  });

  test('last page has no next', () => {
    const r = buildPaginationResponse([1], 41, 3, 20);
    expect(r.pagination.hasNext).toBe(false);
    expect(r.pagination.hasPrev).toBe(true);
  });
});
