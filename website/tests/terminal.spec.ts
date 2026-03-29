import { test, expect } from "@playwright/test";

test.describe("Terminal simulator", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/demo");
    await page.locator(".t-prompt").waitFor();
    await page.locator("#terminal-input").focus();
  });

  test("typing shows in prompt", async ({ page }) => {
    await page.keyboard.type("hdi");
    await expect(page.locator("#prompt-input")).toHaveText("hdi");
  });

  test("enter executes command", async ({ page }) => {
    await page.keyboard.type("hdi --version");
    await page.keyboard.press("Enter");
    await expect(page.locator(".t-line", { hasText: /^hdi \d/ })).toBeVisible();
    // A new prompt should appear after output
    await expect(page.locator(".t-prompt").last()).toBeVisible();
  });

  test("unknown command shows error", async ({ page }) => {
    await page.keyboard.type("foo");
    await page.keyboard.press("Enter");
    await expect(
      page.locator(".t-line", { hasText: "Command not found: foo" }),
    ).toBeVisible();
  });

  test("clear resets terminal and accepts input", async ({ page }) => {
    await page.keyboard.type("hdi --version");
    await page.keyboard.press("Enter");
    await page.locator(".t-prompt").last().waitFor();
    await page.keyboard.type("clear");
    await page.keyboard.press("Enter");
    // Welcome text should reappear
    await expect(
      page.locator(".t-line", { hasText: 'Type "hdi" to get started' }),
    ).toBeVisible();
    // Should be able to type after clear
    await page.keyboard.type("hdi");
    await expect(page.locator("#prompt-input")).toHaveText("hdi");
  });

  test("Ctrl+L clears terminal", async ({ page }) => {
    await page.keyboard.type("hdi --version");
    await page.keyboard.press("Enter");
    await page.locator(".t-prompt").last().waitFor();
    await page.keyboard.press("Control+l");
    await expect(page.locator(".t-prompt")).toBeVisible();
  });

  test("cat README.md shows readme content", async ({ page }) => {
    await page.keyboard.type("cat README.md");
    await page.keyboard.press("Enter");
    // Default project is express-api
    await expect(
      page.locator(".t-line", { hasText: "# express-api" }),
    ).toBeVisible();
  });

  test("hdi --help shows help text", async ({ page }) => {
    await page.keyboard.type("hdi --help");
    await page.keyboard.press("Enter");
    await expect(page.locator(".t-line", { hasText: "Usage:" })).toBeVisible();
  });

  test("hint bar buttons fill prompt", async ({ page }) => {
    await page.locator("#hints code", { hasText: "hdi install" }).click();
    await expect(page.locator("#prompt-input")).toHaveText("hdi install");
  });

  test("empty enter shows new prompt without error", async ({ page }) => {
    const promptCount = await page.locator(".t-prompt").count();
    await page.keyboard.press("Enter");
    await expect(page.locator(".t-prompt")).toHaveCount(promptCount + 1);
    // No error line should appear
    await expect(
      page.locator(".t-yellow", { hasText: "Command not found" }),
    ).toHaveCount(0);
  });
});
