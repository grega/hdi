import { test, expect } from "@playwright/test";

test.describe("About page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/", { waitUntil: "domcontentloaded" });
  });

  test("renders hero", async ({ page }) => {
    await expect(
      page.locator("h1", { hasText: "No more searching the README." }),
    ).toBeVisible();
  });

  test("renders install section", async ({ page }) => {
    await expect(page.locator("#install-section")).toBeVisible();
  });

  test.describe("install tabs", () => {
    test.beforeEach(async ({ page }) => {
      await page.waitForLoadState("load");
    });

    test("renders", async ({ page }) => {
      await expect(page.locator("[role=tablist]")).toBeVisible();
      await expect(page.locator("[role=tab]")).toHaveCount(2);
    });

    test("brew tab is selected by default", async ({ page }) => {
      const brewTab = page.locator("[role=tab]", { hasText: "brew" });
      await expect(brewTab).toHaveAttribute("aria-selected", "true");
      await expect(
        page.locator("code", { hasText: "brew install grega/tap/hdi" }),
      ).toBeVisible();
    });

    test("clicking curl tab shows curl panel", async ({ page }) => {
      const curlTab = page.locator("[role=tab]", { hasText: "curl" });
      await curlTab.click();
      await expect(curlTab).toHaveAttribute("aria-selected", "true");
      await expect(page.locator("#tabpanel-2")).not.toHaveClass(/is-hidden/);
      await expect(page.locator("#tabpanel-1")).toHaveClass(/is-hidden/);
    });

    test("clicking brew tab after curl restores brew panel", async ({
      page,
    }) => {
      await page.locator("[role=tab]", { hasText: "curl" }).click();
      const brewTab = page.locator("[role=tab]", { hasText: "brew" });
      await brewTab.click();
      await expect(brewTab).toHaveAttribute("aria-selected", "true");
      await expect(page.locator("#tabpanel-1")).not.toHaveClass(/is-hidden/);
      await expect(page.locator("#tabpanel-2")).toHaveClass(/is-hidden/);
    });

    test("ArrowRight moves focus to curl tab", async ({ page }) => {
      const brewTab = page.locator("[role=tab]", { hasText: "brew" });
      await brewTab.focus();
      await page.keyboard.press("ArrowRight");
      const curlTab = page.locator("[role=tab]", { hasText: "curl" });
      await expect(curlTab).toHaveAttribute("aria-selected", "true");
      await expect(page.locator("#tabpanel-2")).not.toHaveClass(/is-hidden/);
    });

    test("ArrowLeft moves from curl back to brew", async ({ page }) => {
      await page.locator("[role=tab]", { hasText: "curl" }).click();
      const curlTab = page.locator("[role=tab]", { hasText: "curl" });
      await curlTab.focus();
      await page.keyboard.press("ArrowLeft");
      const brewTab = page.locator("[role=tab]", { hasText: "brew" });
      await expect(brewTab).toHaveAttribute("aria-selected", "true");
      await expect(page.locator("#tabpanel-1")).not.toHaveClass(/is-hidden/);
    });

    test("ArrowLeft wraps from brew back to curl", async ({ page }) => {
      const brewTab = page.locator("[role=tab]", { hasText: "brew" });
      await brewTab.focus();
      await page.keyboard.press("ArrowLeft");
      const curlTab = page.locator("[role=tab]", { hasText: "curl" });
      await expect(curlTab).toHaveAttribute("aria-selected", "true");
    });
  });

  test("copy button works", async ({ page, context, browserName }) => {
    test.skip(
      browserName !== "chromium",
      "Real clipboard permission support is inconsistent in Firefox/WebKit.",
    );

    const btn = page.locator(".code-block-btn").first();
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
