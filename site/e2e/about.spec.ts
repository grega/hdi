import { test, expect } from '@playwright/test';

test.describe('About page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('renders hero and install section', async ({ page }) => {
    await expect(page.locator('h1', { hasText: 'How do I' })).toBeVisible();
    await expect(page.locator('.install-section')).toBeVisible();
    await expect(page.locator('.install-method')).toHaveCount(2);
  });

  test('copy button works', async ({ page, context }) => {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']);
    const btn = page.locator('.copy-btn').first();
    await btn.click();
    await expect(btn).toHaveText('Copied!');
    await expect(btn).toHaveClass(/copied/);
    // Reverts after timeout
    await expect(btn).toHaveText('Copy', { timeout: 3000 });
    await expect(btn).not.toHaveClass(/copied/);
  });
});
