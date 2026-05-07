import { defineConfig, devices } from "@playwright/test";

const isCI = !!process.env.CI;

export default defineConfig({
  testDir: "./tests",
  timeout: 30_000,
  retries: isCI ? 2 : 0,
  workers: isCI ? 1 : undefined,
  forbidOnly: isCI,
  reporter: isCI ? "github" : "list",

  use: {
    baseURL: process.env.BASE_URL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },

  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
