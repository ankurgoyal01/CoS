#!/bin/bash
# tdd-orchestrator.sh — Daily safety net for TDD generation
#
# Runs daily as a backup to the watcher — processes any tickets
# in the grooming sprint that the watcher may have missed.
# Works alongside tdd-watcher.sh — does not duplicate work.
#
# Schedule: 8:00 AM IST Mon–Fri (2:30 AM UTC)
#   30 2 * * 1-5 /Users/agoyal/CoS/projects/SFDC/scripts/agents/tdd-orchestrator.sh >> /Users/agoyal/CoS/logs/tdd-orchestrator.log 2>&1

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
DATE=$(TZ="Asia/Kolkata" date +"%Y-%m-%d")
TIMESTAMP=$(TZ="Asia/Kolkata" date +"%Y-%m-%dT%H:%M:%S IST")

mkdir -p "$LOG_DIR"

echo "========================================"
echo "TDD Orchestrator — $DATE · $TIMESTAMP"
echo "========================================"

if [ -z "$ATLASSIAN_TOKEN" ] || [ -z "$ATLASSIAN_EMAIL" ]; then
  echo "ERROR: ATLASSIAN_TOKEN and ATLASSIAN_EMAIL must be set"
  exit 1
fi

if [ ! -f "$SPECIALIST" ]; then
  echo "ERROR: tdd-specialist.sh not found at $SPECIALIST"
  exit 1
fi

# Initialise state file if missing
if [ ! -f "$STATE_FILE" ]; then
  echo '{"processed":{},"last_run":""}' > "$STATE_FILE"
fi

# ── Fetch grooming sprint tickets ─────────────────────────────────────────────
echo "Fetching tickets from '$JIRA_SPRINT_NAME' sprint..."

RAW=$(curl -s \
  -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"jql\":\"project = $JIRA_PROJECT AND $JIRA_SPRINT_FIELD = \\\"$JIRA_SPRINT_NAME\\\" AND status = \\\"To Do\\\" AND originalEstimate is EMPTY\",\"maxResults\":50,\"fields\":[\"summary\",\"description\",\"comment\",\"priority\",\"issuetype\",\"timeoriginalestimate\"]}" \
  "$JIRA_BASE/rest/api/3/search/jql")

TICKET_COUNT=$(echo "$RAW" | python3 -c "
import json,sys
d=json.load(sys.stdin)
errs=d.get('errorMessages',[])
if errs: print(f'ERROR: {errs[0]}'); exit(1)
print(len(d.get('issues',[])))
")

echo "Found: $TICKET_COUNT tickets"

if [ "$TICKET_COUNT" -eq 0 ]; then
  echo "No tickets in grooming sprint. Nothing to do."
  exit 0
fi

# ── Parse all tickets ─────────────────────────────────────────────────────────
ALL_TICKETS=$(echo "$RAW" | python3 -c "
import json,sys
issues = json.load(sys.stdin).get('issues',[])
result = []
for i in issues:
    f = i['fields']
    desc = ''
    d = f.get('description')
    if d and isinstance(d,dict):
        for block in d.get('content',[]):
            for inline in block.get('content',[]):
                if inline.get('type')=='text':
                    desc+=inline.get('text','')+' '
    comments=[]
    for c in f.get('comment',{}).get('comments',[])[-5:]:
        author=c.get('author',{}).get('displayName','Unknown')
        body=c.get('body',{})
        text=''
        if isinstance(body,dict):
            for block in body.get('content',[]):
                for inline in block.get('content',[]):
                    if inline.get('type')=='text':
                        text+=inline.get('text','')+' '
        if text.strip():
            comments.append(f'{author}: {text.strip()[:300]}')
    import re
    def clean(s):
        s = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]', ' ', str(s))
        s = s.replace('\n',' ').replace('\r',' ').replace('\t',' ')
        return ' '.join(s.split())
    result.append({'key':i['key'],'summary':clean(f['summary']),
        'priority':f.get('priority',{}).get('name','Medium'),
        'type':f.get('issuetype',{}).get('name','Task'),
        'desc':clean(desc.strip())[:2000],'comments':[clean(c) for c in comments]})
print(json.dumps(result, ensure_ascii=False))
")

# ── Find unprocessed tickets (watcher may have done some already) ─────────────
# Write ALL_TICKETS to temp file to avoid heredoc/pipe stdin conflict
_TMP_TICKETS=$(mktemp)
echo "$ALL_TICKETS" > "$_TMP_TICKETS"

UNPROCESSED=$(python3 - "$_TMP_TICKETS" "$STATE_FILE" << 'PYEOF'
import json, sys

tickets_file = sys.argv[1]
state_file   = sys.argv[2]

with open(tickets_file) as f:
    tickets = json.load(f)

try:
    with open(state_file) as f:
        state = json.load(f)
except FileNotFoundError:
    state = {"processed": {}}

processed = state.get("processed", {})
remaining = [t for t in tickets
             if t["key"] not in processed
             or processed[t["key"]].get("status") == "failed"]
print(json.dumps(remaining))
PYEOF
)
rm -f "$_TMP_TICKETS"
)

TODO_COUNT=$(echo "$UNPROCESSED" | python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))")

if [ "$TODO_COUNT" -eq 0 ]; then
  echo "All $TICKET_COUNT tickets already processed by watcher. Nothing to do."
  exit 0
fi

echo "Unprocessed: $TODO_COUNT tickets (watcher handled the rest)"
echo "$UNPROCESSED" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    print(f\"  {t['key']:15} [{t['priority']:6}] {t['summary'][:55]}\")
"

# ── Spawn specialists in parallel ─────────────────────────────────────────────
chmod +x "$SPECIALIST"
PIDS=()
KEYS=()

while IFS= read -r ticket; do
  KEY=$(echo "$ticket" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['key'])")
  TICKET_LOG="$LOG_DIR/tdd-$KEY-$DATE.log"
  echo "Launching: $KEY"
  bash "$SPECIALIST" "$KEY" "$ticket" > "$TICKET_LOG" 2>&1 &
  PIDS+=($!)
  KEYS+=("$KEY")
done < <(echo "$UNPROCESSED" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    print(json.dumps(t))
")

FAILED=()
DONE=()
for i in "${!PIDS[@]}"; do
  PID="${PIDS[$i]}"
  KEY="${KEYS[$i]}"
  if wait "$PID"; then
    DONE+=("$KEY")
    echo "$KEY — done"
  else
    FAILED+=("$KEY")
    echo "$KEY — FAILED"
  fi
done

echo ""
echo "========================================"
echo "Orchestrator complete — ${#DONE[@]} done, ${#FAILED[@]} failed"
echo "Logs: $LOG_DIR/"
echo "========================================"