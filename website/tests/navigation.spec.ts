import { test, expect } from "@playwright/test";

test.describe("Page navigation", () => {
  test("navigates to demo page via link", async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
    await page
      .locator('a.button, a[href*="demo"], .demo-link a')
      .first()
      .click();
    expect(page.url()).toContain("/demo");
  });

  test("navigates back to main page from demo", async ({ page }) => {
    await page.goto("/demo", { waitUntil: "domcontentloaded" });
    await page.locator(".t-prompt").waitFor();
    await page.locator("a.nav-back").click();
    await page.waitForURL("/");
    await expect(page.locator("#about")).toBeVisible();
  });

  test("direct navigation to /demo shows demo view", async ({ page }) => {
    await page.goto("/demo", { waitUntil: "domcontentloaded" });
    await expect(page.locator("#demo-view")).toBeVisible();
  });
});

test.describe("Sidebar", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/demo", { waitUntil: "domcontentloaded" });
    await page.locator(".t-prompt").waitFor();
  });

  test("shows projects with first active", async ({ page }) => {
    const items = page.locator(".sidebar-item");
    await expect(items).toHaveCount(5);
    await expect(items.first()).toHaveClass(/active/);
  });

  test("clicking a project switches context", async ({ page }) => {
    const items = page.locator(".sidebar-item");
    await items.nth(1).click();
    await expect(items.nth(1)).toHaveClass(/active/);
    await expect(items.first()).not.toHaveClass(/active/);
    await expect(page.locator(".t-prompt")).toBeVisible();
  });
});
