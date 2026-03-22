import { test, expect } from '@playwright/test';

test.describe('Tab navigation', () => {
  test('defaults to About tab', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('#about')).toBeVisible();
    await expect(page.locator('#demo-view')).toBeHidden();
    await expect(page.locator('.tab[data-tab="about"]')).toHaveClass(/active/);
  });

  test('clicking Demo tab switches view', async ({ page }) => {
    await page.goto('/');
    await page.locator('.tab[data-tab="demo"]').click();
    await expect(page.locator('#demo-view')).toBeVisible();
    await expect(page.locator('#about')).toBeHidden();
    expect(new URL(page.url()).hash).toBe('#demo');
  });

  test('clicking About tab switches back', async ({ page }) => {
    await page.goto('/#demo');
    await page.locator('.tab[data-tab="about"]').click();
    await expect(page.locator('#about')).toBeVisible();
    await expect(page.locator('#demo-view')).toBeHidden();
  });

  test('direct #demo URL shows demo view', async ({ page }) => {
    await page.goto('/#demo');
    await expect(page.locator('#demo-view')).toBeVisible();
    await expect(page.locator('#about')).toBeHidden();
  });

  test('browser back/forward updates tabs', async ({ page }) => {
    await page.goto('/');
    await page.locator('.tab[data-tab="demo"]').click();
    await expect(page.locator('#demo-view')).toBeVisible();
    await page.goBack();
    await expect(page.locator('#about')).toBeVisible();
    await page.goForward();
    await expect(page.locator('#demo-view')).toBeVisible();
  });
});

test.describe('Sidebar', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/#demo');
    await page.locator('.t-prompt').waitFor();
  });

  test('shows projects with first active', async ({ page }) => {
    const items = page.locator('.sidebar-item');
    await expect(items).toHaveCount(5);
    await expect(items.first()).toHaveClass(/active/);
  });

  test('clicking a project switches context', async ({ page }) => {
    const items = page.locator('.sidebar-item');
    await items.nth(1).click();
    await expect(items.nth(1)).toHaveClass(/active/);
    await expect(items.first()).not.toHaveClass(/active/);
    await expect(page.locator('.t-prompt')).toBeVisible();
  });
});
