import { test, expect } from "@playwright/test";

/**
 * Smoke test — verifies the home page is reachable.
 *
 * Skips gracefully when BASE_URL is unset, which is the expected state for
 * freshly generated repos that do not yet have a running web app.
 *
 * To run against a local dev server:
 *   BASE_URL=http://localhost:3000 npx playwright test
 *
 * See docs/testing-e2e.md for full usage guidance.
 */
test("home page is reachable", async ({ page }) => {
  if (!process.env.BASE_URL) {
    test.skip(
      true,
      "BASE_URL is not set — set it to run against a running app (e.g. BASE_URL=http://localhost:3000).",
    );
    return;
  }

  const response = await page.goto("/");
  expect(response?.ok()).toBe(true);
  await expect(page.locator("body")).toBeVisible();
});
