module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'app/**/*.js',
    '!app/node_modules/**',
    '!app/coverage/**',
    '!app/jest.config.js'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  testMatch: [
    '**/tests/**/*.test.js',
    '**/tests/**/*.spec.js'
  ],
  verbose: true,
  // Root directory for tests
  roots: ['<rootDir>/tests'],
  // Module directories
  moduleDirectories: ['node_modules', 'app/node_modules']
};
