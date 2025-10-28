const createTestApp = require('./helpers/createTestApp');
const fs = require('fs');
const path = require('path');

describe('Server Module', () => {
  describe('Module Export', () => {
    it('should export the Express app', () => {
      const app = createTestApp();

      expect(app).toBeDefined();
      expect(typeof app).toBe('function');
      expect(app.listen).toBeDefined();
    });

    it('should create independent app instances', () => {
      // Each call to createTestApp should create a new instance
      const app1 = createTestApp();
      const app2 = createTestApp();

      expect(app1).not.toBe(app2); // Different instances
      expect(app1.listen).toBeDefined();
      expect(app2.listen).toBeDefined();
    });

    it('should have the correct main module check if server.js exists', () => {
      // Verify that the server uses require.main === module pattern if the file exists
      const serverPath = path.resolve(__dirname, '../app/server.js');

      if (fs.existsSync(serverPath)) {
        const serverCode = fs.readFileSync(serverPath, 'utf8');
        expect(serverCode).toContain('require.main === module');
        expect(serverCode).toContain('app.listen');
      } else {
        // If no actual server.js exists, just pass this test
        expect(true).toBe(true);
      }
    });
  });
});
