#!/bin/bash
# sf-screenshot.sh — Headless Salesforce screenshots
# Captures Audit Trail + Deployment Status using saved SSO session
#
# Prerequisites:
#   1. Run sf-auth.js once to save your session:
#        node ~/CoS/scripts/salesforce/sf-auth.js
#   2. Session stored at ~/.salesforce-session.json
#
# Usage:
#   ~/sf-screenshot.sh                    # both pages
#   ~/sf-screenshot.sh audit              # audit trail only
#   ~/sf-screenshot.sh deploy             # deployment status only
#
# Schedule (optional — e.g. every Monday with weekly report):
#   30 6 * * 1 /Users/agoyal/CoS/scripts/salesforce/sf-screenshot.sh >> /Users/agoyal/CoS/logs/sf-screenshots.log 2>&1

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SF_URL="https://groupon-dev.my.salesforce.com"
SESSION_FILE="$HOME/.salesforce-session.json"
OUTPUT_DIR="$HOME/CoS/logs/sf-screenshots"
DATE=$(TZ="Asia/Kolkata" date +"%Y-%m-%d")
TIME_IST=$(TZ="Asia/Kolkata" date +"%H%M")
TARGET="${1:-both}"   # audit | deploy | both

mkdir -p "$OUTPUT_DIR"

echo "========================================"
echo "SF Screenshot: $DATE · $TIME_IST IST"
echo "Target: $TARGET"
echo "========================================"

# ── Check session file exists ─────────────────────────────────────────────────
if [ ! -f "$SESSION_FILE" ]; then
  echo "ERROR: No saved session found at $SESSION_FILE"
  echo "Run this first: node ~/CoS/scripts/salesforce/sf-auth.js"
  exit 1
fi

# ── Run Playwright via Node inline script ─────────────────────────────────────
node - << JSEOF
const { chromium } = require('/Users/agoyal/CoS/playwright/node_modules/playwright');
const path  = require('path');
const fs    = require('fs');

const SF_URL     = '$SF_URL';
const SESSION    = '$SESSION_FILE';
const OUTPUT_DIR = '$OUTPUT_DIR';
const DATE       = '$DATE';
const TIME       = '$TIME_IST';
const TARGET     = '$TARGET';

const PAGES = {
  audit: {
    name:  'audit-trail',
    url:   SF_URL + '/lightning/setup/SetupAuditTrail/home',
    title: 'Setup Audit Trail',
    wait:  '.slds-spinner_container, table.slds-table, .forceListViewManager',
  },
  deploy: {
    name:  'deployment-status',
    url:   SF_URL + '/lightning/setup/DeployStatus/home',
    title: 'Deployment Status',
    wait:  '.slds-spinner_container, .deployStatusPage, table',
  },
};

async function screenshot(page, config) {
  const filename = path.join(OUTPUT_DIR, \`sf-\${config.name}-\${DATE}-\${TIME}.png\`);
  console.log(\`Navigating to \${config.title}...\`);

  await page.goto(config.url, { waitUntil: 'networkidle', timeout: 30000 });

  // Wait for page content to render
  try {
    await page.waitForSelector(config.wait, { timeout: 15000 });
  } catch (e) {
    console.log(\`  Warning: selector timeout — taking screenshot anyway\`);
  }

  // Extra settle time for Lightning components
  await page.waitForTimeout(2500);

  // Full page screenshot
  await page.screenshot({
    path: filename,
    fullPage: true,
  });

  console.log(\`  Saved: \${filename}\`);
  return filename;
}

async function checkSessionValid(page) {
  // If session expired, Salesforce redirects to login page
  const url = page.url();
  if (url.includes('/login') || url.includes('login.salesforce.com')) {
    console.error('Session expired. Run: node ~/CoS/scripts/salesforce/sf-auth.js');
    process.exit(1);
  }
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    storageState: SESSION,
    viewport: { width: 1440, height: 900 },
  });
  const page = await context.newPage();

  // Navigate to SF home first to validate session
  await page.goto(SF_URL, { waitUntil: 'networkidle', timeout: 20000 });
  await checkSessionValid(page);
  console.log('Session valid. Starting screenshots...\n');

  const results = [];

  if (TARGET === 'audit' || TARGET === 'both') {
    const f = await screenshot(page, PAGES.audit);
    results.push(f);
  }

  if (TARGET === 'deploy' || TARGET === 'both') {
    const f = await screenshot(page, PAGES.deploy);
    results.push(f);
  }

  await browser.close();

  console.log('\nDone.');
  results.forEach(f => console.log('  ' + f));
})();
JSEOF

echo "========================================"
echo "Screenshots saved to: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR" | grep "$DATE" || echo "(no files found for today)"
echo "========================================"
