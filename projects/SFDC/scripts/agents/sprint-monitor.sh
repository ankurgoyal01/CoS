#!/bin/bash
# sprint-monitor.sh — Always-on blocker detection agent
#
# Runs every 6 hours Mon–Fri. Detects tickets that became Blocked or Reopened
# since the last run. Posts a Jira comment on each new blocker with context.
# Sends a summary alert if any new blockers found.
#
# State file: ~/CoS/logs/sprint-monitor/.state.json
#   Tracks which tickets were already flagged so alerts are not repeated.
#   Auto-cleans tickets that left Blocked/Reopened status.
#
# Schedule (launchd — already configured):
#   Every 12 hours Mon–Fri: 02:00, 14:00 UTC
#   = 07:30 IST (morning) and 19:30 IST (evening)
#
# Credentials: ATLASSIAN_EMAIL + ATLASSIAN_TOKEN from launchd env

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
JIRA_BASE="https://groupondev.atlassian.net"
ATLASSIAN_EMAIL="${ATLASSIAN_EMAIL:-}"
ATLASSIAN_TOKEN="${ATLASSIAN_TOKEN:-}"
LOG_DIR="$HOME/CoS/logs/sprint-monitor"
STATE_FILE="$LOG_DIR/.state.json"
TIMESTAMP=$(TZ="Asia/Kolkata" date +"%Y-%m-%dT%H:%M:%S IST" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S UTC")
DATE_SHORT=$(TZ="Asia/Kolkata" date +"%Y-%m-%d" 2>/dev/null || date -u +"%Y-%m-%d")

mkdir -p "$LOG_DIR"

echo "========================================"
echo "Sprint Monitor — $TIMESTAMP"
echo "========================================"

# ── Validate ──────────────────────────────────────────────────────────────────
if [ -z "$ATLASSIAN_TOKEN" ] || [ -z "$ATLASSIAN_EMAIL" ]; then
  echo "ERROR: ATLASSIAN_TOKEN and ATLASSIAN_EMAIL must be set"
  exit 1
fi

# ── Initialise state file ─────────────────────────────────────────────────────
if [ ! -f "$STATE_FILE" ]; then
  echo '{"flagged":{},"last_run":"","runs":0}' > "$STATE_FILE"
  echo "Initialised state file: $STATE_FILE"
fi

# ── Fetch blocked + reopened tickets — both boards ────────────────────────────
echo "Fetching blocked/reopened tickets from SFDC + GSOIT..."

CURRENT_RAW=$(curl -s \
  -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "jql": "project in (SFDC, GSOIT) AND sprint in openSprints() AND status in (Blocked, Reopened) ORDER BY priority ASC, project ASC",
    "maxResults": 50,
    "fields": ["summary", "status", "assignee", "priority", "project", "updated", "comment"],
    "expand": ["changelog"]
  }' \
  "$JIRA_BASE/rest/api/3/search/jql")

# Check for API errors
API_ERR=$(echo "$CURRENT_RAW" | python3 -c "
import json,sys
d=json.load(sys.stdin)
errs=d.get('errorMessages',[])
print(errs[0] if errs else '')
" 2>/dev/null || echo "parse_error")

if [ -n "$API_ERR" ]; then
  echo "Jira API error: $API_ERR"
  exit 1
fi

# ── Parse current blocked/reopened tickets ────────────────────────────────────
CURRENT_TICKETS=$(echo "$CURRENT_RAW" | python3 -c "
import json, sys, re
from datetime import datetime

data   = json.load(sys.stdin)
issues = data.get('issues', [])
result = []

for i in issues:
    f          = i['fields']
    assignee   = f.get('assignee') or {}
    # last comment for context
    comments   = f.get('comment', {}).get('comments', [])
    last_comment = ''
    if comments:
        c    = comments[-1]
        body = c.get('body', {})
        text = ''
        if isinstance(body, dict):
            for block in body.get('content', []):
                for inline in block.get('content', []):
                    if inline.get('type') == 'text':
                        text += inline.get('text', '') + ' '
        author = c.get('author', {}).get('displayName', 'Unknown')
        text   = re.sub(r'[\x00-\x1f\x7f]', ' ', text).strip()[:200]
        last_comment = f'{author}: {text}' if text else ''

    # Find when ticket entered Blocked/Reopened status via changelog
    blocked_since = None
    current_status = f['status']['name']
    changelog = i.get('changelog', {}).get('histories', [])
    # Walk changelog newest→oldest, find last transition INTO blocked/reopened
    for history in reversed(changelog):
        for item in history.get('items', []):
            if item.get('field') == 'status' and item.get('toString') in ('Blocked', 'Reopened'):
                blocked_since = history.get('created', '')
                break
        if blocked_since:
            break

    # Calculate hours in blocked status
    hours_blocked = 0
    if blocked_since:
        try:
            from datetime import timezone
            ts = datetime.fromisoformat(blocked_since.replace('Z', '+00:00'))
            now_utc = datetime.now(timezone.utc)
            hours_blocked = (now_utc - ts).total_seconds() / 3600
        except:
            hours_blocked = 0

    # Only include tickets blocked for more than 12 hours
    if hours_blocked < 12 and blocked_since:
        continue  # Too new — skip, will be picked up in next 12h run

    result.append({
        'key':          i['key'],
        'summary':      re.sub(r'[\x00-\x1f\x7f]', ' ', f['summary']).strip()[:80],
        'status':       current_status,
        'priority':     f.get('priority', {}).get('name', 'Medium'),
        'project':      f['project']['key'],
        'assignee':     assignee.get('displayName', 'Unassigned'),
        'updated':      f.get('updated', '')[:10],
        'last_comment': last_comment,
        'blocked_since': blocked_since[:16].replace('T', ' ') if blocked_since else 'Unknown',
        'hours_blocked': round(hours_blocked, 1),
    })

print(json.dumps(result))
")

TOTAL=$(echo "$CURRENT_TICKETS" | python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))")
echo "Found: $TOTAL blocked/reopened ticket(s) in open sprints"

# ── Diff against state — find NEW blockers ────────────────────────────────────
NEW_BLOCKERS=$(python3 << PYEOF
import json
from datetime import datetime

with open("$STATE_FILE") as f:
    state = json.load(f)

flagged  = state.get("flagged", {})
current  = json.loads("""$CURRENT_TICKETS""")
new_ones = [t for t in current if t["key"] not in flagged]
print(json.dumps(new_ones))
PYEOF
)

NEW_COUNT=$(echo "$NEW_BLOCKERS" | python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))")

# ── Update state — clean tickets that left blocked status ─────────────────────
python3 << PYEOF
import json
from datetime import datetime

with open("$STATE_FILE") as f:
    state = json.load(f)

current_keys = {t["key"] for t in json.loads("""$CURRENT_TICKETS""")}
flagged      = state.get("flagged", {})

# Clean state every 24 hours — forces re-alert on tickets still blocked
# This ensures engineers get a follow-up nudge every 24h, not just on first detection
cleaned = {}
now     = datetime.now()
for k, v in flagged.items():
    if k not in current_keys:
        continue  # ticket resolved — drop immediately
    try:
        ts    = datetime.fromisoformat(v.get("flagged_at", "").replace(" IST", "").replace(" UTC", ""))
        hours = (now - ts).total_seconds() / 3600
        if hours < 24:
            cleaned[k] = v  # flagged less than 24h ago — keep, do not re-alert
        # else: drop — ticket is still blocked but flagged_at > 24h ago
        # dropping means it will be treated as "new" next run → triggers a follow-up Jira comment
    except:
        pass  # malformed entry — drop it

state["flagged"]   = cleaned
state["last_run"]  = "$TIMESTAMP"
state["runs"]      = state.get("runs", 0) + 1
state["total_blocked"] = int("$TOTAL")

with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF

# ── No new blockers — silent exit ─────────────────────────────────────────────
if [ "$NEW_COUNT" -eq 0 ]; then
  echo "$TIMESTAMP — $TOTAL ticket(s) in blocked/reopened. No new blockers since last run."
  echo "========================================"
  exit 0
fi

# ── New blockers detected ─────────────────────────────────────────────────────
echo ""
echo "🔴 NEW BLOCKERS DETECTED: $NEW_COUNT"
echo "$NEW_BLOCKERS" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    print(f\"  {t['project']:5} {t['key']:15} [{t['status']:10}] [{t['priority']:6}] {t['assignee']:20} — {t['summary'][:45]}\")
"
echo ""

# ── Post Jira comment on each new blocker ────────────────────────────────────
echo "Posting alerts to Jira..."

while IFS= read -r ticket; do
  KEY=$(echo "$ticket"      | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['key'])")
  SUMMARY=$(echo "$ticket"  | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['summary'])")
  STATUS=$(echo "$ticket"   | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['status'])")
  ASSIGNEE=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['assignee'])")
  PRIORITY=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['priority'])")
  LAST_CMT=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('last_comment','None'))")

  echo "  Posting alert: $KEY ($STATUS)"

  BLOCKED_SINCE=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('blocked_since','Unknown'))")
  HOURS_BLOCKED=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('hours_blocked',0))")

  COMMENT_TEXT="🔴 Sprint Monitor Alert — $TIMESTAMP

This ticket has been in $STATUS status for ${HOURS_BLOCKED} hours (since $BLOCKED_SINCE) and requires attention.

Ticket: $KEY — $SUMMARY
Status: $STATUS | Blocked since: $BLOCKED_SINCE (${HOURS_BLOCKED}h)
Assignee: $ASSIGNEE
Priority: $PRIORITY
Last comment: $LAST_CMT

Action required:
1. Add a comment explaining what is blocking this ticket
2. Link to the blocking dependency (another ticket, team, or external system)
3. Escalate to EM (Ankur Goyal) if not unblocked within 24 hours

This alert fires when a ticket has been Blocked or Reopened for more than 12 hours.
Follow-up alerts are posted every 24 hours while the ticket remains blocked.
Sprint monitor runs every 12 hours."

  # Build ADF paragraphs
  PAYLOAD=$(python3 -c "
import json
text = '''$COMMENT_TEXT'''
paragraphs = [
    {'type': 'paragraph', 'content': [{'type': 'text', 'text': line}]}
    for line in text.split('\n')
    if line.strip()
]
print(json.dumps({'body': {'type': 'doc', 'version': 1, 'content': paragraphs}}))
")

  RESP=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$JIRA_BASE/rest/api/3/issue/$KEY/comment")

  if [ "$RESP" = "201" ] || [ "$RESP" = "200" ]; then
    echo "  $KEY — comment posted ✓"
  else
    echo "  $KEY — comment failed (HTTP $RESP)"
  fi

done < <(echo "$NEW_BLOCKERS" | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    print(json.dumps(t))
")

# ── Update state with newly flagged tickets ───────────────────────────────────
python3 << PYEOF
import json

with open("$STATE_FILE") as f:
    state = json.load(f)

flagged = state.get("flagged", {})

for ticket_json in """$NEW_BLOCKERS""".split('\n'):
    ticket_json = ticket_json.strip()
    if not ticket_json:
        continue
    try:
        import json as j
        t = j.loads(ticket_json)
        flagged[t["key"]] = {
            "flagged_at":    "$TIMESTAMP",
            "status":        t["status"],
            "assignee":      t["assignee"],
            "summary":       t["summary"][:60],
            "blocked_since": t.get("blocked_since", ""),
            "hours_blocked": t.get("hours_blocked", 0),
        }
    except:
        pass

state["flagged"] = flagged
with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF

# ── Write daily summary log ───────────────────────────────────────────────────
SUMMARY_LOG="$LOG_DIR/blockers-$DATE_SHORT.log"
{
  echo "Sprint Monitor Summary — $TIMESTAMP"
  echo "New blockers: $NEW_COUNT"
  echo "Total in sprints: $TOTAL"
  echo ""
  echo "$NEW_BLOCKERS" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    print(f\"{t['key']:15} [{t['status']:10}] {t['assignee']:20} — {t['summary']}\")
"
} >> "$SUMMARY_LOG"

echo ""
echo "========================================"
echo "Done — $NEW_COUNT new blocker(s) flagged"
echo "Jira alerts posted. State updated."
echo "Summary log: $SUMMARY_LOG"
echo "========================================"