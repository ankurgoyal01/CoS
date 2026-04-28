#!/bin/bash
# setup-launchd.sh — Full launchd setup for all 6 CoS agents
# Replaces all cron jobs with launchd so Mac wakes to run jobs
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

if [ -z "$GITHUB_TOKEN" ] || [ -z "$ASANA_PAT" ] || [ -z "$ATLASSIAN_TOKEN" ]; then
  echo "ERROR: Could not read tokens from crontab"
  echo "Expected: GITHUB_TOKEN, ASANA_PAT, ATLASSIAN_EMAIL, ATLASSIAN_TOKEN"
  exit 1
fi

echo "Tokens read from crontab ✓"
echo ""

mkdir -p "$PLIST_DIR" "$LOG_DIR"
mkdir -p "$LOG_DIR/tdd" "$LOG_DIR/sprint-monitor"

# ── Helper: unload if exists ──────────────────────────────────────────────────
unload_if_exists() {
  local file="$PLIST_DIR/${1}.plist"
  [ -f "$file" ] && launchctl unload "$file" 2>/dev/null && echo "  Unloaded: $1" || true
}

# ── Helper: load and verify ───────────────────────────────────────────────────
load_agent() {
  local label="$1"
  launchctl load "$PLIST_DIR/${label}.plist"
  if launchctl list | grep -q "$label"; then
    echo "  Loaded ✓ — $label"
  else
    echo "  ⚠️  Load may have failed — $label (check plist syntax)"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 1. STANDUP BRIEF — Daily 9:30 AM IST = 4:00 AM UTC · Mon–Fri
# ══════════════════════════════════════════════════════════════════════════════
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. standup-brief  (daily 9:30 AM IST)"
unload_if_exists "com.ankur.standup"

cat > "$PLIST_DIR/com.ankur.standup.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ankur.standup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPTS}/daily/standup.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key><string>${HOME}</string>
        <key>GITHUB_TOKEN</key><string>${GITHUB_TOKEN}</string>
        <key>ASANA_PAT</key><string>${ASANA_PAT}</string>
        <key>ATLASSIAN_EMAIL</key><string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key><string>${ATLASSIAN_TOKEN}</string>
    </dict>
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>
    </array>
    <key>StandardOutPath</key><string>${LOG_DIR}/standup.log</string>
    <key>StandardErrorPath</key><string>${LOG_DIR}/standup.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
load_agent "com.ankur.standup"

# ══════════════════════════════════════════════════════════════════════════════
# 2. SF SCREENSHOTS — Monday 11:55 AM IST = 6:25 AM UTC
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. sf-screenshot  (Monday 11:55 AM IST)"
unload_if_exists "com.ankur.sf-screenshot"

cat > "$PLIST_DIR/com.ankur.sf-screenshot.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ankur.sf-screenshot</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPTS}/salesforce/sf-screenshot.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key><string>${HOME}</string>
        <key>ATLASSIAN_EMAIL</key><string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key><string>${ATLASSIAN_TOKEN}</string>
    </dict>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>6</integer>
        <key>Minute</key><integer>25</integer>
    </dict>
    <key>StandardOutPath</key><string>${LOG_DIR}/sf-screenshots.log</string>
    <key>StandardErrorPath</key><string>${LOG_DIR}/sf-screenshots.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
load_agent "com.ankur.sf-screenshot"

# ══════════════════════════════════════════════════════════════════════════════
# 3. WEEKLY GITHUB REPORT — Monday 12:00 noon IST = 6:30 AM UTC
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. weekly-report  (Monday 12:00 noon IST)"
unload_if_exists "com.ankur.weekly-report"

cat > "$PLIST_DIR/com.ankur.weekly-report.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ankur.weekly-report</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPTS}/weekly/weekly-report.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key><string>${HOME}</string>
        <key>GITHUB_TOKEN</key><string>${GITHUB_TOKEN}</string>
        <key>ASANA_PAT</key><string>${ASANA_PAT}</string>
        <key>ATLASSIAN_EMAIL</key><string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key><string>${ATLASSIAN_TOKEN}</string>
    </dict>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key><integer>1</integer>
        <key>Hour</key><integer>6</integer>
        <key>Minute</key><integer>30</integer>
    </dict>
    <key>StandardOutPath</key><string>${LOG_DIR}/weekly-report.log</string>
    <key>StandardErrorPath</key><string>${LOG_DIR}/weekly-report.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
load_agent "com.ankur.weekly-report"

# ══════════════════════════════════════════════════════════════════════════════
# 4. TDD ORCHESTRATOR — Daily 8:00 AM IST = 2:30 AM UTC · Mon–Fri
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. tdd-orchestrator  (daily 8:00 AM IST)"
unload_if_exists "com.ankur.tdd-orchestrator"

cat > "$PLIST_DIR/com.ankur.tdd-orchestrator.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ankur.tdd-orchestrator</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPTS}/agents/tdd-orchestrator.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key><string>${HOME}</string>
        <key>ATLASSIAN_EMAIL</key><string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key><string>${ATLASSIAN_TOKEN}</string>
        <key>ASANA_PAT</key><string>${ASANA_PAT}</string>
    </dict>
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>30</integer></dict>
    </array>
    <key>StandardOutPath</key><string>${LOG_DIR}/tdd-orchestrator.log</string>
    <key>StandardErrorPath</key><string>${LOG_DIR}/tdd-orchestrator.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
load_agent "com.ankur.tdd-orchestrator"

# ══════════════════════════════════════════════════════════════════════════════
# 5. TDD WATCHER — Every 4 hours Mon–Fri
#    02:00, 06:00, 10:00, 14:00, 18:00 UTC = 07:30, 11:30, 15:30, 19:30, 23:30 IST
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. tdd-watcher  (every 4 hours Mon–Fri)"
unload_if_exists "com.ankur.tdd-watcher"

cat > "$PLIST_DIR/com.ankur.tdd-watcher.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ankur.tdd-watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPTS}/agents/tdd-watcher.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key><string>${HOME}</string>
        <key>ATLASSIAN_EMAIL</key><string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key><string>${ATLASSIAN_TOKEN}</string>
        <key>ASANA_PAT</key><string>${ASANA_PAT}</string>
    </dict>
    <key>StartCalendarInterval</key>
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
    </array>
    <key>StandardOutPath</key><string>${LOG_DIR}/tdd-watcher.log</string>
    <key>StandardErrorPath</key><string>${LOG_DIR}/tdd-watcher.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
load_agent "com.ankur.tdd-watcher"

# ══════════════════════════════════════════════════════════════════════════════
# 6. SPRINT MONITOR — Every 12 hours Mon–Fri
#    02:00 + 14:00 UTC = 07:30 AM IST + 19:30 PM IST
#    Detects tickets blocked > 12h · Re-alerts every 24h while still blocked
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. sprint-monitor  (every 12 hours Mon–Fri · 07:30 + 19:30 IST)"
unload_if_exists "com.ankur.sprint-monitor"

cat > "$PLIST_DIR/com.ankur.sprint-monitor.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ankur.sprint-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPTS}/agents/sprint-monitor.sh</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
        <key>HOME</key><string>${HOME}</string>
        <key>ATLASSIAN_EMAIL</key><string>${ATLASSIAN_EMAIL}</string>
        <key>ATLASSIAN_TOKEN</key><string>${ATLASSIAN_TOKEN}</string>
    </dict>
    <key>StartCalendarInterval</key>
    <array>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>2</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>3</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>4</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
        <dict><key>Weekday</key><integer>5</integer><key>Hour</key><integer>14</integer><key>Minute</key><integer>0</integer></dict>
    </array>
    <key>StandardOutPath</key><string>${LOG_DIR}/sprint-monitor.log</string>
    <key>StandardErrorPath</key><string>${LOG_DIR}/sprint-monitor.log</string>
    <key>RunAtLoad</key><false/>
</dict>
</plist>
PLIST
load_agent "com.ankur.sprint-monitor"

# ── Remove old cron jobs now handled by launchd ───────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Removing old cron jobs..."
crontab -l \
  | grep -v "^0 4 \* \* 1-5.*standup" \
  | grep -v "^30 6 \* \* 1.*weekly-report" \
  | grep -v "^25 6 \* \* 1.*sf-screenshot" \
  | grep -v "^30 2 \* \* 1-5.*tdd-orchestrator" \
  | grep -v "^\*/5 \* \* \* 1-5.*tdd-watcher" \
  | grep -v "^0 \*/4 \* \* 1-5.*tdd-watcher" \
  | grep -v "^0 \*/4 \* \* 1-5.*sprint-monitor" \
  | grep -v "^\*/6 \* \* \* 1-5.*sprint-monitor" \
  | crontab -
echo "  Cron entries removed ✓"

# ── Final verification ────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "All 6 launchd agents:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AGENTS=(
  "com.ankur.standup         → Daily 9:30 AM IST"
  "com.ankur.sf-screenshot   → Monday 11:55 AM IST"
  "com.ankur.weekly-report   → Monday 12:00 noon IST"
  "com.ankur.tdd-orchestrator→ Daily 8:00 AM IST"
  "com.ankur.tdd-watcher     → Every 4h Mon–Fri"
  "com.ankur.sprint-monitor  → Every 12h Mon–Fri (07:30 + 19:30 IST)"
)

ALL_OK=true
for entry in "${AGENTS[@]}"; do
  label=$(echo "$entry" | awk '{print $1}')
  schedule=$(echo "$entry" | cut -d'→' -f2)
  if launchctl list | grep -q "$label"; then
    echo "  ✅ $label$schedule"
  else
    echo "  ❌ $label — NOT LOADED"
    ALL_OK=false
  fi
done

echo ""
echo "Plist files:"
ls -1 "$PLIST_DIR"/com.ankur.*.plist | while read f; do echo "  $f"; done

echo ""
if $ALL_OK; then
  echo "✅ All 6 agents loaded and running."
else
  echo "⚠️  Some agents failed to load. Check plist syntax above."
fi

echo ""
echo "Logs:"
echo "  tail -f ~/CoS/logs/standup.log"
echo "  tail -f ~/CoS/logs/weekly-report.log"
echo "  tail -f ~/CoS/logs/tdd-watcher.log"
echo "  tail -f ~/CoS/logs/sprint-monitor.log"
echo ""
echo "Test sprint-monitor now:"
echo "  ~/CoS/projects/SFDC/scripts/agents/sprint-monitor.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"