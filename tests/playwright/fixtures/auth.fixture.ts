import { expect, test as base, type Page } from '@playwright/test';

type AuthFixtures = {
  authenticatedPage: Page;
};

export const test = base.extend<AuthFixtures>({
  authenticatedPage: async ({ page }, use) => {
    const username = process.env.GC_TEST_USERNAME;
    const password = process.env.GC_TEST_PASSWORD;

    if (!username || !password) {
      throw new Error('Set GC_TEST_USERNAME and GC_TEST_PASSWORD in the local test environment.');
    }

    await page.goto('/');
    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByLabel('Password').fill(password);
    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page.getByRole('link', { name: 'Gestion commerciale' })).toBeVisible();

    await use(page);
  },
});

test.use({ trace: 'off', screenshot: 'off' });

export { expect };