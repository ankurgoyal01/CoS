#!/bin/bash
# setup-launchd.sh — Replace all cron jobs with launchd agents
# Launchd wakes the Mac to run jobs even if machine is asleep
# Run once: bash ~/CoS/projects/SFDC/scripts/setup-launchd.sh

set -euo pipefail

PLIST_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/CoS/logs"
SCRIPTS="$HOME/CoS/projects/SFDC/scripts"

# ── Pull tokens from crontab ──────────────────────────────────────────────────
GITHUB_TOKEN=$(crontab -l | grep "^GITHUB_TOKEN" | cut -d= -f2-)
ASANA_PAT=$(crontab -l | grep "^ASANA_PAT" | cut -d= -f2-)
ATLASSIAN_EMAIL=$(crontab -l | grep "^ATLASSIAN_EMAIL" | cut -d= -f2-)
ATLASSIAN_TOKEN=$(crontab -l | grep "^ATLASSIAN_TOKEN" | cut -d= -f2-)

if [ -z "$GITHUB_TOKEN" ] || [ -z "$ASANA_PAT" ]; then
  echo "ERROR: Could not read tokens from crontab. Check crontab -l"
  exit 1
fi

echo "Tokens read from crontab ✓"
echo ""

# ── Helper: write plist ───────────────────────────────────────────────────────
write_plist() {
  local label="$1"
  local script="$2"
  local log="$3"
  local schedule="$4"   # XML fragment for StartCalendarInterval
  local file="$PLIST_DIR/${label}.plist"

  cat > "$file" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${label}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${script}</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
        <key>GITHUB_TOKEN</key>
        <string>${GITHUB_TOKEN}</string>
        <key>ASANA_PAT</key>
        <string>${ASANA_PAT}</string>
        <key>ATLASSIAN_EMAIL</key>
        <string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key>
        <string>${ATLASSIAN_TOKEN}</string>
    </dict>

    ${schedule}

    <key>StandardOutPath</key>
    <string>${log}</string>
    <key>StandardErrorPath</key>
    <string>${log}</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST

  echo "  Written: $file"
}

# ── Unload existing if already loaded ────────────────────────────────────────
unload_if_exists() {
  local label="$1"
  local file="$PLIST_DIR/${label}.plist"
  if [ -f "$file" ]; then
    launchctl unload "$file" 2>/dev/null || true
    echo "  Unloaded existing: $label"
  fi
}

mkdir -p "$PLIST_DIR" "$LOG_DIR"

# ════════════════════════════════════════════════════════════════════════
# 1. STANDUP BRIEF — Daily 9:30 AM IST = 4:00 AM UTC Mon–Fri
# ════════════════════════════════════════════════════════════════════════
echo "Setting up: standup-brief (daily 9:30 AM IST)"
unload_if_exists "com.ankur.standup"

write_plist "com.ankur.standup" \
  "$SCRIPTS/daily/standup.sh" \
  "$LOG_DIR/standup.log" \
  '<key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
    </array>'

launchctl load "$PLIST_DIR/com.ankur.standup.plist"
echo "  Loaded ✓"
echo ""

# ════════════════════════════════════════════════════════════════════════
# 2. SF SCREENSHOT — Monday 11:55 AM IST = 6:25 AM UTC
# ════════════════════════════════════════════════════════════════════════
echo "Setting up: sf-screenshot (Monday 11:55 AM IST)"
unload_if_exists "com.ankur.sf-screenshot"

write_plist "com.ankur.sf-screenshot" \
  "$SCRIPTS/salesforce/sf-screenshot.sh" \
  "$LOG_DIR/sf-screenshots.log" \
  '<key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>6</integer>
        <key>Minute</key><integer>25</integer>
    </dict>'

launchctl load "$PLIST_DIR/com.ankur.sf-screenshot.plist"
echo "  Loaded ✓"
echo ""

# ════════════════════════════════════════════════════════════════════════
# 3. WEEKLY GITHUB REPORT — Monday 12:00 noon IST = 6:30 AM UTC
# ════════════════════════════════════════════════════════════════════════
echo "Setting up: weekly-report (Monday 12:00 noon IST)"
unload_if_exists "com.ankur.weekly-report"

write_plist "com.ankur.weekly-report" \
  "$SCRIPTS/weekly/weekly-report.sh" \
  "$LOG_DIR/weekly-report.log" \
  '<key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>6</integer>
        <key>Minute</key><integer>30</integer>
    </dict>'

launchctl load "$PLIST_DIR/com.ankur.weekly-report.plist"
echo "  Loaded ✓"
echo ""

# ════════════════════════════════════════════════════════════════════════
# 4. TDD ORCHESTRATOR — Daily 8:00 AM IST = 2:30 AM UTC Mon–Fri
#    (safety net — catches anything tdd-watcher missed)
# ════════════════════════════════════════════════════════════════════════
echo "Setting up: tdd-orchestrator (daily 8:00 AM IST)"
unload_if_exists "com.ankur.tdd-orchestrator"

write_plist "com.ankur.tdd-orchestrator" \
  "$SCRIPTS/agents/tdd-orchestrator.sh" \
  "$LOG_DIR/tdd-orchestrator.log" \
  '<key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
    </array>'

launchctl load "$PLIST_DIR/com.ankur.tdd-orchestrator.plist"
echo "  Loaded ✓"
echo ""

# ════════════════════════════════════════════════════════════════════════
# 5. TDD WATCHER — Every 4 hours Mon–Fri
#    launchd doesn't support */4 directly — schedule at 4 fixed times
#    02:00, 06:00, 10:00, 14:00, 18:00 UTC
#    = 07:30, 11:30, 15:30, 19:30, 23:30 IST
# ════════════════════════════════════════════════════════════════════════
echo "Setting up: tdd-watcher (every 4 hours Mon–Fri)"
unload_if_exists "com.ankur.tdd-watcher"

write_plist "com.ankur.tdd-watcher" \
  "$SCRIPTS/agents/tdd-watcher.sh" \
  "$LOG_DIR/tdd-watcher.log" \
  '<key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>6</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>6</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>6</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>6</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>6</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
    </array>'

launchctl load "$PLIST_DIR/com.ankur.tdd-watcher.plist"
echo "  Loaded ✓"
echo ""

# ════════════════════════════════════════════════════════════════════════
# DISABLE OLD CRON JOBS (comment them out if not already commented)
# ════════════════════════════════════════════════════════════════════════
echo "Disabling cron jobs (now handled by launchd)..."

# Remove the active cron lines — keep commented ones as history
crontab -l | grep -v "^0 4 \* \* 1-5.*standup" \
           | grep -v "^30 6 \* \* 1.*weekly-report" \
           | grep -v "^25 6 \* \* 1.*sf-screenshot" \
           | grep -v "^30 2 \* \* 1-5.*tdd-orchestrator" \
           | grep -v "^\*/5 \* \* \* 1-5.*tdd-watcher" \
           | grep -v "^0 \*/4 \* \* 1-5.*tdd-watcher" \
           | crontab -
echo "  Cron jobs removed ✓"
echo ""

# ════════════════════════════════════════════════════════════════════════
# VERIFY ALL LOADED
# ════════════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════"
echo "All launchd agents loaded:"
echo "════════════════════════════════════════"
for label in com.ankur.standup com.ankur.sf-screenshot com.ankur.weekly-report com.ankur.tdd-orchestrator com.ankur.tdd-watcher; do
  status=$(launchctl list | grep "$label" | awk '{print $1}')
  if [ -n "$status" ]; then
    echo "  ✅ $label (PID/status: $status)"
  else
    echo "  ⚠️  $label — not found in launchctl list"
  fi
done
echo ""
echo "Plist files:"
ls -1 "$PLIST_DIR"/com.ankur.*.plist
echo ""
echo "════════════════════════════════════════"
echo "Setup complete."
echo ""
echo "Key difference from cron:"
echo "  launchd WILL wake your Mac to run jobs."
echo "  If the machine is asleep, it runs when it wakes."
echo "  Cron simply skipped the job if the Mac was asleep."
echo ""
echo "To run standup manually right now:"
echo "  ~/CoS/projects/SFDC/scripts/daily/standup.sh"
echo ""
echo "To check logs:"
echo "  tail -f ~/CoS/logs/standup.log"
echo "  tail -f ~/CoS/logs/weekly-report.log"
echo "  tail -f ~/CoS/logs/tdd-watcher.log"
echo "════════════════════════════════════════"
