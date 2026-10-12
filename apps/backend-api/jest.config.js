/** Jest config for Student Kwacha backend API */
module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/**/*.test.js'],
  // Unit tests only touch pure modules — no DB required.
  // Integration-style tests that need Postgres can be added later and
  // would live under tests/integration/ and require DB env vars.
  collectCoverageFrom: ['src/**/*.js', '!src/app.js', '!src/models/**', '!src/config/**'],
  coverageThreshold: {
    global: { statements: 20, branches: 10 },
  },
  verbose: true,
};
