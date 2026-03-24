import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 15_000,
  retries: 0,
  reporter: [["html", { open: "never" }]],
  use: {
    baseURL: "http://localhost:3123",
  },
  webServer: {
    command: "npx serve . -l 3123 --no-clipboard",
    port: 3123,
    reuseExistingServer: !process.env.CI,
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
