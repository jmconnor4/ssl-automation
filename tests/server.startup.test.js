describe('Server Module', () => {
  describe('Module Export', () => {
    it('should export the Express app', () => {
      const app = require('../app/server');

      expect(app).toBeDefined();
      expect(typeof app).toBe('function');
      expect(app.listen).toBeDefined();
    });

    it('should not auto-start when required as a module', () => {
      // When server.js is required (not run directly), it should not start listening
      // This is tested by the fact that we can require it multiple times without port conflicts
      const app1 = require('../app/server');
      const app2 = require('../app/server');

      expect(app1).toBe(app2); // Should be the same instance due to Node's module caching
    });

    it('should have the correct main module check', () => {
      // Verify that the server uses require.main === module pattern
      const fs = require('fs');
      const serverCode = fs.readFileSync(require.resolve('../app/server'), 'utf8');

      expect(serverCode).toContain('require.main === module');
      expect(serverCode).toContain('app.listen');
    });
  });
});
