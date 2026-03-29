import { test, expect } from "@playwright/test";

test.describe("About page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("renders hero and install section", async ({ page }) => {
    await expect(
      page.locator("h1", { hasText: "No more searching the README." }),
    ).toBeVisible();
    await expect(page.locator(".install-section")).toBeVisible();
    await expect(page.locator(".install-method")).toHaveCount(2);
  });

  test("copy button works", async ({ page, context, browserName }) => {
    test.skip(
      browserName !== "chromium",
      "Real clipboard permission support is inconsistent in Firefox/WebKit.",
    );

    const btn = page.locator(".copy-btn").first();
    const expected = await btn.getAttribute("data-copy");
    expect(expected).toBeTruthy();

    await context.grantPermissions(["clipboard-read", "clipboard-write"], {
      origin: new URL(page.url()).origin,
    });

    await btn.click();
    await expect(btn).toHaveText("Copied!");
    await expect(btn).toHaveClass(/copied/);

    const copied = await page.evaluate(() => navigator.clipboard.readText());
    expect(copied).toBe(expected);

    // Reverts after timeout
    await expect(btn).toHaveText("Copy", { timeout: 3000 });
    await expect(btn).not.toHaveClass(/copied/);
  });
});
