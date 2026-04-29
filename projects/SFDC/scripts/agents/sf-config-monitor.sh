#!/bin/bash
# sf-config-monitor.sh — Salesforce configuration change risk report
#
# Runs Mon/Wed/Fri. Queries SetupAuditTrail for the period since last run,
# scores each change by risk tier (Critical/High/Medium/Low/Noise),
# saves a markdown report, and creates an Asana task.
#
# Schedule (launchd):
#   Monday    08:30 AM IST = 03:00 UTC  (covers Sat–Mon)
#   Wednesday 08:30 AM IST = 03:00 UTC  (covers Mon–Wed)
#   Friday    08:30 AM IST = 03:00 UTC  (covers Wed–Fri)
#
# Credentials: ATLASSIAN_EMAIL, ATLASSIAN_TOKEN, ASANA_PAT from launchd env
# Salesforce: uses Claude Code with sf_query MCP (Salesforce must be connected)

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
CLAUDE_BIN="/opt/homebrew/bin/claude"
ASANA_PAT="${ASANA_PAT:-}"
LOG_DIR="$HOME/CoS/logs/sf-config-monitor"
SKILL_DIR="$HOME/CoS/.claude/skills/sf-config-monitor"
DATE_SHORT=$(TZ="Asia/Kolkata" date +"%Y-%m-%d" 2>/dev/null || date -u +"%Y-%m-%d")
DAY=$(TZ="Asia/Kolkata" date +"%a" 2>/dev/null || date -u +"%a")
TIMESTAMP=$(TZ="Asia/Kolkata" date +"%Y-%m-%dT%H:%M:%S IST" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S UTC")
OUTPUT_FILE="$LOG_DIR/sf-config-$DATE_SHORT.md"

mkdir -p "$LOG_DIR"

echo "========================================"
echo "SF Config Monitor — $TIMESTAMP"
echo "========================================"

# ── Determine reporting period ────────────────────────────────────────────────
# Mon = covers last 3 days (Fri–Mon), Wed = 2 days (Mon–Wed), Fri = 2 days (Wed–Fri)
case "$DAY" in
  Mon) DAYS_BACK=3 ; PERIOD_LABEL="Fri–Mon" ;;
  Wed) DAYS_BACK=2 ; PERIOD_LABEL="Mon–Wed" ;;
  Fri) DAYS_BACK=2 ; PERIOD_LABEL="Wed–Fri" ;;
  *)   DAYS_BACK=2 ; PERIOD_LABEL="last 2 days" ;;
esac

PERIOD_START=$(python3 -c "
from datetime import datetime, timedelta, timezone
now = datetime.now(timezone.utc)
start = now - timedelta(days=$DAYS_BACK)
print(start.strftime('%Y-%m-%dT00:00:00Z'))
")
PERIOD_END=$(python3 -c "
from datetime import datetime, timezone
print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))
")

echo "Period: $PERIOD_START → $PERIOD_END ($PERIOD_LABEL)"

# ── Build Claude prompt ───────────────────────────────────────────────────────
PROMPT="You are running the sf-config-monitor skill for Ankur Goyal, Engineering Manager at Groupon.

Generate a Salesforce configuration risk report for this period:
- Start: $PERIOD_START
- End: $PERIOD_END
- Day: $DAY (period: $PERIOD_LABEL)
- Report date: $DATE_SHORT

Follow the sf-config-monitor skill exactly:

1. Run these SOQL queries via the sf_query Salesforce MCP tool:

Query 1 — Full SetupAuditTrail:
SELECT Action, Section, Display, CreatedDate, CreatedBy.Name, CreatedBy.Username
FROM SetupAuditTrail
WHERE CreatedDate >= $PERIOD_START AND CreatedDate <= $PERIOD_END
AND Section NOT IN ('Login', 'Logout', 'Password', 'Session', 'API Usage')
ORDER BY CreatedDate DESC LIMIT 2000

Query 2 — High-volume Account changes:
SELECT LastModifiedBy.Name, COUNT(Id) recordCount
FROM Account
WHERE LastModifiedDate >= $PERIOD_START AND LastModifiedDate <= $PERIOD_END
GROUP BY LastModifiedBy.Name HAVING COUNT(Id) > 200 ORDER BY COUNT(Id) DESC

Query 3 — High-volume Opportunity changes:
SELECT LastModifiedBy.Name, COUNT(Id) recordCount
FROM Opportunity
WHERE LastModifiedDate >= $PERIOD_START AND LastModifiedDate <= $PERIOD_END
GROUP BY LastModifiedBy.Name HAVING COUNT(Id) > 200 ORDER BY COUNT(Id) DESC

2. Apply this risk scoring model to every SetupAuditTrail row:

CRITICAL:
- Manage Users + profile/role/permission change for a specific user
- Permission Set created or deleted (especially 'with no license')
- Flow deactivated with no paired re-activation by same actor within 10 min
- User role changed

HIGH (demote paired activate/deactivate < 10min to Medium):
- Flow created/activated/deactivated/deleted
- Apex Class or Apex Trigger changes
- Approval Process changes
- Validation Rule changes
- Customize Accounts / Customize Opportunities (layout changes)
- Inbound Change Set deployments
- Workflow Rule changes

MEDIUM:
- Manage Users bulk property changes
- Lightning Page / FlexiPage changes
- Custom Object / Custom Field changes
- External Client Application changes
- OAuth and OpenID Connect Settings
- Application / Custom App changes

LOW: Reports, Dashboards, Email Templates, general Customize

NOISE:
- System actor or Automated Process
- Paired activate/deactivate < 10 min same actor same flow
- system-generated Apex Class changes

3. Output the full report in this exact markdown format:

# Salesforce Config Risk Report
**Period:** [period] · **Total events:** [N]
**Risk:** Critical [N] · High [N] · Medium [N] · Low [N] · Noise [N]
[any demotions note]

---

## Executive Summary
[2-4 sentences covering critical count, key actors, flags]

---

## 🔴 Critical ([N])
[DATE TIME IST] · [Actor] · [Section]
    ↳ [what changed]

---

## 🟠 High ([N])
[Actor] · [verb] in [Section] · [N]x ([items])

---

## 🟡 Medium ([N])
[Section] · [N] changes by [Actors]

---

## 📊 Top Actors This Period
[Actor] · [total] changes · Critical [N] · High [N]

---

## ⚠️ Flags
[patterns, issues to investigate, or 'No flags this period.']

For EVERY event in the report, append a Salesforce deep link on the line after the display text.
Use base URL: https://groupon-dev.my.salesforce.com

Link mapping (use the most specific URL possible):
- Flow events          → /lightning/setup/Flows/home
- Apex Class           → /lightning/setup/ApexClasses/home
- Apex Trigger         → /lightning/setup/ApexTriggers/home
- Permission Set       → /lightning/setup/PermSets/home
- Profile change       → /lightning/setup/Profiles/home
- Manage Users (user)  → /lightning/setup/ManageUsers/home
- Validation Rule      → /lightning/setup/ValidationRules/home
- Approval Process     → /lightning/setup/ApprovalProcesses/home
- Workflow Rule        → /lightning/setup/WorkflowRules/home
- Customize Accounts   → /lightning/setup/ObjectManager/Account/PageLayouts/view
- Customize Opps       → /lightning/setup/ObjectManager/Opportunity/PageLayouts/view
- Customize Cases      → /lightning/setup/ObjectManager/Case/PageLayouts/view
- Inbound Change Set   → /lightning/setup/InboundChangeSet/home
- Lightning/FlexiPage  → /lightning/setup/FlexiPageList/home
- Custom Object/Field  → /lightning/setup/ObjectManager/home
- External Client App  → /lightning/setup/ConnectedApplication/home
- OAuth                → /lightning/setup/OauthCustomScopes/home
- SetupAuditTrail      → /lightning/setup/SetupAuditTrail/home (fallback)

Format each event exactly like this:
[DATE TIME IST] · [Actor] · [Section]
    ↳ [Display — what changed]
    🔗 [Setup Page](https://groupon-dev.my.salesforce.com/lightning/setup/...)

For grouped High events, add the link once after the group line:
[Actor] · [verb] in [Section] · [N]x ([items])
    🔗 [Setup Page](https://groupon-dev.my.salesforce.com/lightning/setup/...)

Output ONLY the markdown report. No preamble. Start with '# Salesforce Config Risk Report'."

# ── Call Claude Code ──────────────────────────────────────────────────────────
echo "Generating report via Claude..."

REPORT=$("$CLAUDE_BIN" -p "$PROMPT" 2>&1) || {
  echo "ERROR: Claude call failed"
  echo "Check Salesforce MCP is connected in Claude Desktop settings"
  exit 1
}

# ── Save report to log ────────────────────────────────────────────────────────
echo "$REPORT" > "$OUTPUT_FILE"
echo "Report saved: $OUTPUT_FILE"

# ── Extract summary stats for console ────────────────────────────────────────
echo ""
echo "--- Report Summary ---"
echo "$REPORT" | grep -E "^\*\*Risk:|^Total events:|Critical [0-9]" | head -5
echo "---"

# ── Create Asana task with full report ───────────────────────────────────────
if [ -z "$ASANA_PAT" ]; then
  echo "ASANA_PAT not set — skipping Asana task creation"
else
  echo "Creating Asana task..."

  TASK_NAME="SF Config Report — $DAY, $DATE_SHORT"
  NOTES_ESCAPED=$(echo "$REPORT" | python3 -c "
import sys, json
content = sys.stdin.read()
# Truncate to 64KB Asana limit
if len(content) > 60000:
    content = content[:60000] + '\n\n[Report truncated — full version in ~/CoS/logs/sf-config-monitor/]'
print(json.dumps(content))
")

  TASK_PAYLOAD=$(python3 -c "
import json
name     = '$TASK_NAME'
notes    = $NOTES_ESCAPED
workspace= '8437193015852'
assignee = '1211542692184092'
due      = '$DATE_SHORT'
print(json.dumps({
    'data': {
        'name':         name,
        'notes':        notes,
        'workspace':    workspace,
        'assignee':     assignee,
        'due_on':       due,
    }
}))
")

  TASK_RESP=$(curl -s \
    -u "$ASANA_PAT:" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$TASK_PAYLOAD" \
    "https://app.asana.com/api/1.0/tasks")

  TASK_ID=$(echo "$TASK_RESP" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('data',{}).get('gid','error'))
" 2>/dev/null || echo "error")

  if [ "$TASK_ID" != "error" ] && [ -n "$TASK_ID" ]; then
    echo "Asana task created: $TASK_NAME (GID: $TASK_ID)"
    echo "Link: https://app.asana.com/0/0/$TASK_ID/f"
  else
    echo "Warning: Asana task creation failed"
    echo "$TASK_RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('errors','unknown error'))" 2>/dev/null
  fi
fi

echo ""
echo "========================================"
echo "SF Config Monitor complete — $TIMESTAMP"
echo "Report: $OUTPUT_FILE"
echo "========================================"