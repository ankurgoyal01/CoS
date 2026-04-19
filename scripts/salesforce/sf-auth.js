// sf-auth.js — One-time Salesforce SSO session saver
// Run this interactively whenever your session expires:
//   node ~/playwright-scripts/sf-auth.js
//
// It opens a real browser window, you log in via Google SSO manually,
// then it saves the session to ~/.salesforce-session.json
// sf-screenshot.sh uses that saved session silently (no login needed)

const { chromium } = require('playwright');
const path = require('path');
const os   = require('os');

const SF_URL       = 'https://groupon-dev.my.salesforce.com/';
const SESSION_FILE = path.join(os.homedir(), '.salesforce-session.json');

(async () => {
  console.log('Opening browser for Salesforce SSO login...');
  console.log('Log in with your Groupon Google account, then wait.');
  console.log('The browser will close automatically once login is detected.\n');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 100,
  });

  const context = await browser.newContext();
  const page    = await context.newPage();

  await page.goto(SF_URL);

  console.log('Waiting for you to complete SSO login...');

  // Wait until the URL contains Lightning or the SF home path
  // Uses waitForFunction so it receives a string from window.location, not a URL object
  await page.waitForFunction(
    () => {
      const u = window.location.href;
      return (
        u.includes('/lightning/') ||
        u.includes('/home/home.jsp') ||
        (u.includes('groupon-dev.my.salesforce.com') && !u.includes('login'))
      );
    },
    { timeout: 120000, polling: 1000 }
  );

  // Extra settle time for all cookies to be written
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(3000);

  // Save session state (cookies + localStorage)
  await context.storageState({ path: SESSION_FILE });
  console.log(`\nSession saved to: ${SESSION_FILE}`);
  console.log('You can now run sf-screenshot.sh headlessly.');

  await browser.close();
})();
