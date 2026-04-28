#!/bin/bash
# tdd-watcher.sh — Event-driven TDD agent for SFDC grooming sprint
#
# Polls Jira every 5 minutes for new tickets in "Ready for Grooming/Estimation" sprint.
# Fires tdd-specialist.sh immediately for each new ticket detected.
# Maintains a state file to avoid re-processing tickets.
#
# Schedule: every 5 minutes Mon–Fri
#   */5 * * * 1-5 /Users/agoyal/CoS/projects/SFDC/scripts/agents/tdd-watcher.sh >> /Users/agoyal/CoS/logs/tdd-watcher.log 2>&1

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
JIRA_BASE="https://groupondev.atlassian.net"
JIRA_PROJECT="SFDC"
JIRA_SPRINT_NAME="Ready for Grooming/Estimation"
JIRA_SPRINT_FIELD="cf[10105]"
ATLASSIAN_EMAIL="${ATLASSIAN_EMAIL:-}"
ATLASSIAN_TOKEN="${ATLASSIAN_TOKEN:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPECIALIST="$SCRIPT_DIR/tdd-specialist.sh"
LOG_DIR="$HOME/CoS/logs/tdd"
STATE_FILE="$LOG_DIR/.tdd-state.json"
TIMESTAMP=$(TZ="Asia/Kolkata" date +"%Y-%m-%dT%H:%M:%S IST")

mkdir -p "$LOG_DIR"

# ── Validate ──────────────────────────────────────────────────────────────────
if [ -z "$ATLASSIAN_TOKEN" ] || [ -z "$ATLASSIAN_EMAIL" ]; then
  echo "[$TIMESTAMP] ERROR: ATLASSIAN_TOKEN and ATLASSIAN_EMAIL must be set"
  exit 1
fi

if [ ! -f "$SPECIALIST" ]; then
  echo "[$TIMESTAMP] ERROR: tdd-specialist.sh not found at $SPECIALIST"
  exit 1
fi

# ── Initialise state file if missing ─────────────────────────────────────────
if [ ! -f "$STATE_FILE" ]; then
  echo '{"processed":{},"last_run":""}' > "$STATE_FILE"
  echo "[$TIMESTAMP] Initialised state file: $STATE_FILE"
fi

# ── Fetch current grooming sprint tickets via Jira API ───────────────────────
CURRENT_TICKETS=$(curl -s \
  -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"jql\":\"project = $JIRA_PROJECT AND $JIRA_SPRINT_FIELD = \\\"$JIRA_SPRINT_NAME\\\" AND status = \\\"To Do\\\"\",\"maxResults\":50,\"fields\":[\"summary\",\"description\",\"comment\",\"priority\",\"issuetype\",\"created\"]}" \
  "$JIRA_BASE/rest/api/3/search/jql")

# Check for API error
API_ERROR=$(echo "$CURRENT_TICKETS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
errs=d.get('errorMessages',[])
print(errs[0] if errs else '')
" 2>/dev/null || echo "parse_error")

if [ -n "$API_ERROR" ]; then
  echo "[$TIMESTAMP] Jira API error: $API_ERROR"
  exit 1
fi

TICKET_COUNT=$(echo "$CURRENT_TICKETS" | python3 -c "
import json,sys
print(len(json.load(sys.stdin).get('issues',[])))
")

# ── Parse tickets into structured JSON ───────────────────────────────────────
PARSED_TICKETS=$(echo "$CURRENT_TICKETS" | python3 -c "
import json,sys

data   = json.load(sys.stdin)
issues = data.get('issues',[])
result = []

for i in issues:
    f = i['fields']

    # Extract description text from ADF
    desc = ''
    d = f.get('description')
    if d and isinstance(d, dict):
        for block in d.get('content',[]):
            for inline in block.get('content',[]):
                if inline.get('type') == 'text':
                    desc += inline.get('text','') + ' '

    # Extract last 5 comments
    comments = []
    for c in f.get('comment',{}).get('comments',[])[-5:]:
        author = c.get('author',{}).get('displayName','Unknown')
        body   = c.get('body',{})
        text   = ''
        if isinstance(body, dict):
            for block in body.get('content',[]):
                for inline in block.get('content',[]):
                    if inline.get('type') == 'text':
                        text += inline.get('text','') + ' '
        if text.strip():
            comments.append(f'{author}: {text.strip()[:300]}')

    import re
    def clean(s):
        s = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', ' ', str(s))
        s = s.replace('\n',' ').replace('\r',' ').replace('\t',' ')
        return ' '.join(s.split())

    result.append({
        'key':      i['key'],
        'summary':  clean(f['summary']),
        'priority': f.get('priority',{}).get('name','Medium'),
        'type':     f.get('issuetype',{}).get('name','Task'),
        'desc':     clean(desc.strip())[:2000],
        'comments': [clean(c) for c in comments],
        'created':  f.get('created',''),
    })

print(json.dumps(result, ensure_ascii=False))
")

# ── Diff against state file — find NEW tickets only ───────────────────────────
NEW_TICKETS=$(echo "$PARSED_TICKETS" | python3 -c "
import json, sys

state_file = '$STATE_FILE'
with open(state_file) as f:
    state = json.load(f)

processed = set(state.get('processed', {}).keys())
tickets   = json.loads(sys.stdin.read())
new_ones  = [t for t in tickets if t['key'] not in processed]
print(json.dumps(new_ones))
")

NEW_COUNT=$(echo "$NEW_TICKETS" | python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))")

# ── Clean up state — remove entries older than 7 days ─────────────────────────
python3 << PYEOF
import json
from datetime import datetime

with open("$STATE_FILE") as f:
    state = json.load(f)

processed = state.get("processed", {})
cleaned   = {}
now       = datetime.now()
for k, v in processed.items():
    try:
        ts   = datetime.strptime(v.get("processed_at","")[:19], "%Y-%m-%dT%H:%M:%S")
        days = (now - ts).days
        if days < 7:
            cleaned[k] = v
    except:
        cleaned[k] = v

state["processed"]        = cleaned
state["last_run"]         = "$TIMESTAMP"
state["tickets_in_queue"] = int("$TICKET_COUNT")

with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF

# ── Nothing new — silent exit ─────────────────────────────────────────────────
if [ "$NEW_COUNT" -eq 0 ]; then
  echo "[$TIMESTAMP] Queue: $TICKET_COUNT tickets — no new tickets"
  exit 0
fi

# ── New tickets — log and spawn specialists in parallel ───────────────────────
echo "[$TIMESTAMP] NEW TICKETS: $NEW_COUNT detected"
echo "$NEW_TICKETS" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    print(f\"  + {t['key']:15} [{t['priority']:6}] {t['summary'][:55]}\")
"

chmod +x "$SPECIALIST"
PIDS=()
KEYS=()

while IFS= read -r ticket; do
  KEY=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['key'])")
  TICKET_LOG="$LOG_DIR/tdd-$KEY-$(TZ='Asia/Kolkata' date +%Y-%m-%d).log"
  echo "[$TIMESTAMP] Launching specialist: $KEY"
  bash "$SPECIALIST" "$KEY" "$ticket" > "$TICKET_LOG" 2>&1 &
  PIDS+=($!)
  KEYS+=("$KEY")
done < <(echo "$NEW_TICKETS" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    print(json.dumps(t))
")

# ── Wait for all specialists ──────────────────────────────────────────────────
FAILED=()
DONE=()

for i in "${!PIDS[@]}"; do
  PID="${PIDS[$i]}"
  KEY="${KEYS[$i]}"
  if wait "$PID"; then
    DONE+=("$KEY")
    echo "[$TIMESTAMP] $KEY — complete"
  else
    FAILED+=("$KEY")
    echo "[$TIMESTAMP] $KEY — FAILED (see $LOG_DIR/tdd-$KEY-*.log)"
  fi
done

# ── Update state file ─────────────────────────────────────────────────────────
python3 << PYEOF
import json

with open("$STATE_FILE") as f:
    state = json.load(f)

processed = state.get("processed", {})
done_keys   = [k for k in "${DONE[@]+"${DONE[@]}"}".split() if k]
failed_keys = [k for k in "${FAILED[@]+"${FAILED[@]}"}".split() if k]

for key in done_keys:
    processed[key] = {"processed_at": "$TIMESTAMP", "status": "done"}
for key in failed_keys:
    processed[key] = {"processed_at": "$TIMESTAMP", "status": "failed"}

state["processed"] = processed
with open("$STATE_FILE", "w") as f:
    json.dump(state, f, indent=2)
PYEOF

echo "[$TIMESTAMP] Done — ${#DONE[@]} succeeded, ${#FAILED[@]:-0} failed"