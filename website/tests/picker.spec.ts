import { test, expect } from "@playwright/test";

test.describe("Interactive picker", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/demo");
    await page.locator(".t-prompt").waitFor();
    await page.locator("#terminal-input").focus();
    await page.keyboard.type("hdi");
    await page.keyboard.press("Enter");
    await page.locator(".picker-wrap").waitFor();
  });

  test("renders with title, commands, and footer", async ({ page }) => {
    await expect(page.locator(".picker-wrap")).toBeVisible();
    await expect(
      page.locator(".picker-wrap", { hasText: "express-api" }),
    ).toBeVisible();
    await expect(page.locator(".picker-row.selected")).toHaveCount(1);
    await expect(
      page.locator(".picker-footer", { hasText: "navigate" }),
    ).toBeVisible();
  });

  test("arrow down/up navigates between commands", async ({ page }) => {
    const first = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    await page.keyboard.press("ArrowDown");
    const second = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(second).not.toBe(first);
    await page.keyboard.press("ArrowUp");
    const back = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(back).toBe(first);
  });

  test("j/k vim-style navigation", async ({ page }) => {
    const first = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    await page.keyboard.press("j");
    const second = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(second).not.toBe(first);
    await page.keyboard.press("k");
    const back = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(back).toBe(first);
  });

  test("Tab jumps to next section", async ({ page }) => {
    const first = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    await page.keyboard.press("Tab");
    const jumped = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(jumped).not.toBe(first);
    // Tab should skip past multiple commands, not just move one
    await page.keyboard.press("ArrowUp");
    const oneAbove = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    // If Tab jumped sections, moving up from the jumped position should
    // land on a different command than the first (we skipped over commands)
    expect(oneAbove).not.toBe(first);
  });

  test("Shift+Tab jumps to previous section", async ({ page }) => {
    const first = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    await page.keyboard.press("Tab");
    await page.keyboard.press("Shift+Tab");
    const back = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(back).toBe(first);
  });

  test("Enter shows execute flash", async ({ page }) => {
    await page.keyboard.press("Enter");
    await expect(page.locator(".flash-execute")).toBeVisible();
    await expect(
      page.locator(".flash-execute", { hasText: "would execute" }),
    ).toBeVisible();
  });

  test("c copies and shows flash", async ({ page, context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.keyboard.press("c");
    await expect(
      page.locator(".flash-msg", { hasText: "Copied" }),
    ).toBeVisible();
  });

  test("q quits picker", async ({ page }) => {
    await page.keyboard.press("q");
    await expect(page.locator(".picker-wrap")).toHaveCount(0);
    await expect(page.locator(".t-prompt").last()).toBeVisible();
  });

  test("Escape quits picker", async ({ page }) => {
    await page.keyboard.press("Escape");
    await expect(page.locator(".picker-wrap")).toHaveCount(0);
    await expect(page.locator(".t-prompt").last()).toBeVisible();
  });

  test("cannot navigate past first command", async ({ page }) => {
    const first = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    // Press up many times - should stay on first
    for (let i = 0; i < 10; i++) await page.keyboard.press("ArrowUp");
    const still = await page
      .locator(".picker-row.selected .t-command")
      .textContent();
    expect(still).toBe(first);
  });
});
