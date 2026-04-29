#!/bin/bash
# standup.sh — Ankur Goyal daily standup automation
# v6 — new Jira sprint health format, expanded Asana (all overdue + next 5 days),
#      Gmail 10-day window, tabular GitHub stats, top priorities with urgency tiers
#
# Schedule: 11:30 AM IST = 6:00 AM UTC (Mon–Fri)
# Cron entry:
#   0 6 * * 1-5 /Users/agoyal/CoS/scripts/daily/standup.sh >> /Users/agoyal/CoS/logs/standup.log 2>&1
#
# Prerequisites (unchanged from v5):
#   pip3 install --upgrade certifi
#   echo 'export ASANA_PAT=your_token'    >> ~/.zshrc
#   echo 'export GITHUB_TOKEN=your_token' >> ~/.zshrc

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
LOGDIR="$HOME/CoS/logs"
DATE=$(TZ="Asia/Kolkata" date +"%Y-%m-%d")
YESTERDAY=$(TZ="Asia/Kolkata" date -v-2d +"%Y-%m-%d" 2>/dev/null || date -d "2 days ago" +"%Y-%m-%d")
PLUS5=$(TZ="Asia/Kolkata" date -v+5d    +"%Y-%m-%d" 2>/dev/null || date -d "+5 days"    +"%Y-%m-%d")
DAY=$(TZ="Asia/Kolkata" date +"%a, %b %d")
TIME_IST=$(TZ="Asia/Kolkata" date +"%H:%M IST")
OUTPUT_FILE="$LOGDIR/standup-$DATE.md"

ASANA_WORKSPACE="8437193015852"
ASANA_ASSIGNEE="1211542692184092"
ASANA_TOKEN="${ASANA_PAT:-}"
GITHUB_ORG="groupondev"
GH_TOKEN="${GITHUB_TOKEN:-}"

mkdir -p "$LOGDIR"

echo "========================================"
echo "Standup run: $DAY · $TIME_IST"
echo "Output: $OUTPUT_FILE"
echo "========================================"

# ── Fetch Asana tasks via REST ────────────────────────────────────────────────
# Buckets: overdue (all past), due today, next 5 days
echo "Fetching Asana tasks..."

ASANA_TASKS=$(python3 << PYEOF
import json, urllib.request, ssl, certifi

token     = "$ASANA_TOKEN"
assignee  = "$ASANA_ASSIGNEE"
workspace = "$ASANA_WORKSPACE"
today     = "$DATE"
plus5     = "$PLUS5"

ctx = ssl.create_default_context(cafile=certifi.where())

def asana_get(path, params):
    qs  = "&".join(f"{k}={urllib.request.quote(str(v), safe='')}" for k, v in params.items())
    url = f"https://app.asana.com/api/1.0{path}?{qs}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
            return json.loads(r.read())["data"]
    except Exception as e:
        return []

# Fetch all incomplete tasks (limit 100)
tasks = asana_get("/tasks", {
    "assignee":        assignee,
    "workspace":       workspace,
    "completed_since": "now",
    "opt_fields":      "name,due_on,projects.name,completed",
    "limit":           "100",
})

overdue, due_today, due_soon, no_date = [], [], [], []

for t in tasks:
    if t.get("completed"):
        continue
    d    = t.get("due_on", "") or ""
    name = (t.get("name") or "")[:75]
    proj = t["projects"][0].get("name", "") if t.get("projects") else ""
    proj_str = f" · {proj}" if proj else ""
    line = f"  · {name} · {d}{proj_str}"

    if not d:
        no_date.append(f"  · {name} · (no due date){proj_str}")
    elif d < today:
        overdue.append(line + "  ← OVERDUE")
    elif d == today:
        due_today.append(line)
    elif today < d <= plus5:
        due_soon.append(line)

out = []
out.append(f"OVERDUE: {len(overdue)} tasks")
out += overdue if overdue else ["  None"]

out.append(f"\nDUE TODAY: {len(due_today)} tasks")
out += due_today if due_today else ["  None"]

out.append(f"\nNEXT 5 DAYS (by {plus5}): {len(due_soon)} tasks")
out += due_soon if due_soon else ["  None"]

print("\n".join(out))
PYEOF
)

# ── Fetch GitHub activity for previous day ────────────────────────────────────
echo "Fetching GitHub stats for $YESTERDAY..."

GITHUB_STATS=$(python3 << PYEOF
import json, urllib.request, urllib.error, ssl, certifi, time

ctx   = ssl.create_default_context(cafile=certifi.where())
token = "$GH_TOKEN"
org   = "$GITHUB_ORG"
date  = "$YESTERDAY"

# SFDC + GSOIT full team (display name → GitHub handle)
TEAM = {
    "Ashwinkrishna": "akrishnam",
    "Niveditha":     "niver",
    "Nirajkumar":    "nshelke",
    "Kumar Ankit":   "kankit",
    "Amit":          "amipatil",
    "Srilakshmi":    "sriks",
    "Utkarsh":       "upathak",
    "Ravi Kumar":    "kumarra",
    "Rakesh":        "rharidas",
    "Datta":         "dmaddala",
    "Ravindra":      "ravikumar",
}

def gh_get(url, accept="application/vnd.github+json"):
    req = urllib.request.Request(url, headers={
        "Authorization":        f"Bearer {token}",
        "Accept":               accept,
        "X-GitHub-Api-Version": "2022-11-28",
    })
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=10) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError:
        return {"items": [], "total_count": 0}
    except Exception:
        return {"items": []}

def count(q):
    url = f"https://api.github.com/search/issues?q={urllib.request.quote(q)}&per_page=1"
    return gh_get(url).get("total_count", 0)

def commits_for(handle, date):
    q   = f"author:{handle} org:{org} author-date:{date}"
    url = f"https://api.github.com/search/commits?q={urllib.request.quote(q)}&per_page=20"
    return gh_get(url, "application/vnd.github.cloak-preview+json").get("items", [])

def lines_changed(commits):
    total = 0
    for c in commits[:8]:
        repo = c.get("repository", {}).get("full_name", "")
        sha  = c.get("sha", "")
        if repo and sha:
            data  = gh_get(f"https://api.github.com/repos/{repo}/commits/{sha}")
            stats = data.get("stats", {})
            total += stats.get("additions", 0) + stats.get("deletions", 0)
            time.sleep(0.2)
    return total

COL = "{:<16} {:>4} {:>8} {:>9} {:>8} {:>8}"
header  = COL.format("Engineer", "PRs", "Reviews", "Comments", "Lines Δ", "Rcvd")
divider = "─" * len(header)
rows    = [f"Git activity — {date} (last 48h)", header, divider]

for name, handle in TEAM.items():
    prs      = count(f"is:pr author:{handle} org:{org} created:{date}")
    reviews  = count(f"is:pr reviewed-by:{handle} org:{org} updated:{date}")
    comments = count(f"is:pr commenter:{handle} org:{org} updated:{date}")
    commits  = commits_for(handle, date)
    loc      = lines_changed(commits)
    rcvd     = count(f"is:pr author:{handle} org:{org} commenter:*")
    rows.append(COL.format(name, prs, reviews, comments, loc, rcvd))
    time.sleep(0.4)

print("\n".join(rows))
PYEOF
)

echo "GitHub stats fetched."

# ── Generate full brief via Claude Code (Jira + Gmail + Calendar via MCP) ─────
echo "Generating standup brief via Claude Code..."

BRIEF=$(claude -p "Generate today's standup brief. Today is $DAY · $TIME_IST.

══════════════════════════════════════════════════
PRE-FETCHED DATA — use as-is, do not re-fetch
══════════════════════════════════════════════════

ASANA — MY TASKS:
$ASANA_TASKS

GITHUB ACTIVITY:
$GITHUB_STATS

══════════════════════════════════════════════════
LIVE DATA — fetch now via MCP
══════════════════════════════════════════════════

JIRA: Use the Atlassian MCP to run these JQL queries across SFDC + GSOIT:
  Blocked:    project in (SFDC,GSOIT) AND sprint in openSprints() AND status = Blocked ORDER BY priority ASC
  Reopened:   project in (SFDC,GSOIT) AND sprint in openSprints() AND status = Reopened
  Done 24h:   project in (SFDC,GSOIT) AND sprint in openSprints() AND status = Done AND updated >= -1d
  In Progr.:  project in (SFDC,GSOIT) AND sprint in openSprints() AND status = 'In Progress' ORDER BY assignee ASC
  Stale 1d+:  project in (SFDC,GSOIT) AND sprint in openSprints() AND status not in (Done,Cancelled) AND updated < -1d
  All sprint: project in (SFDC,GSOIT) AND sprint in openSprints()

  Always surface regardless of status:
  - SFDC-10103, SFDC-10055 (Niveditha — INTL CDA recurring blocker)
  - GSOIT-6369 (Datta — Cyclops latency — do NOT clear until resolved)
  - SFDC-10144, SFDC-10161 🤖, GSOIT-6331, GSOIT-6332, GSOIT-6334 (AI workstreams)

GMAIL: Use the Gmail MCP. Fetch unread from last 10 days. Exclude automated
  Asana/Jira notifications, calendar invites, newsletters, Gemini notes, no-reply.
  Prioritise: SF Flow errors [Error/Alert]; real-person emails with subject/snippet
  containing blocker/urgent/action required/approval/escalation/prod/incident/error/failed.
  Group repeated approvals from same sender into one line: '[Name] sent N approval requests'.
  Max 7 items, most critical first. Tags: [Reply needed][Approval][Escalation][Error/Alert][FYI][Admin]

CALENDAR: Use the Google Calendar MCP. List all events today (IST), excluding
  focus-time blocks, OOO, commute, and dinner markers.
  Flag: ⚠️ CONFLICT (overlap) | ⚡ BACK-TO-BACK (<5 min gap) | 📭 NO AGENDA | ❓ NO RESPONSE

══════════════════════════════════════════════════
OUTPUT FORMAT — produce this exactly, no preamble
══════════════════════════════════════════════════

## Standup brief — $DAY · $TIME_IST

### 🏃 Sprint Health — Jira

\`\`\`
═══════════════════════════════════════════════════════
 GSOIT — [sprint name]                      [dates]
═══════════════════════════════════════════════════════
 Total: N | Done: N | Deploy: N | QA: N | Review: N
 In Progress: N | Reopened: N | To Do: N | Blocked: N
 Completion: N% [ASCII bar — 1 block per 5%, e.g. 25%=█████░░░░░░░░░░]

 ✅ COMPLETED (last 24h)
  TICKET-XXXX  Summary (≤50 chars)              Assignee

 📦 MOVED / ACTIVE (status changed today or NEW)
  TICKET-XXXX  Summary                           Assignee  → Status  ← NEW if created today

 ⚠️ STUCK (no update 1+ biz day)
  TICKET-XXXX  Summary                           Assignee  N days (Apr DD)  🚩 if >14 days

 🔴 BLOCKED
  TICKET-XXXX  Summary                           Assignee  since Apr DD

 🚩 RISK FLAGS
  [one line per risk: WIP concentration, long-running items, sprint overload]
  [flag AI workstream tickets with 🤖 and their current status]

═══════════════════════════════════════════════════════
 SFDC — [sprint name]                       [dates]
═══════════════════════════════════════════════════════
 [same structure as GSOIT above]

═══════════════════════════════════════════════════════
 COMBINED: N tickets | N% done | N stuck | N blocked
═══════════════════════════════════════════════════════
\`\`\`

### 💻 Git Activity (last 48h)

\`\`\`
[paste the GitHub table from pre-fetched data verbatim]
\`\`\`

### 📋 Asana — My Tasks

[paste the Asana buckets from pre-fetched data verbatim, grouped as:
 Overdue (N) → Due Today (N) → Next 5 Days (N)]

### 📧 Email — Needs attention (last 10 days, unread)

· Sender · \"Subject truncated to 60 chars\" · One-line: what's needed · [Tag]
(or: None requiring action)

### 📅 Calendar — Today

\`\`\`
HH:MM–HH:MM  Event name  (Xm)  [flags if any]
Free window: HH:MM–HH:MM (Xm) — use for: [recommendation]
\`\`\`

### 🎯 Top Priorities

🔴 Immediate (action before EOD or next meeting)
  N. Action — why urgent (source: Jira/Email/Asana/Cal)

🟡 Today's meetings (prep or decisions needed)
  N. Meeting at HH:MM — what to bring/decide

🔵 This week (own or unblock)
  N. Action — context" 2>&1) || true

if [ -z "$BRIEF" ]; then
  echo "ERROR: Claude Code returned empty output."
  exit 1
fi

# ── Save brief ────────────────────────────────────────────────────────────────
{
  echo "# Standup Brief — $DAY · $TIME_IST"
  echo ""
  echo "$BRIEF"
} > "$OUTPUT_FILE"

echo "Brief generated."

# ── Create Asana task ─────────────────────────────────────────────────────────
if [ -z "$ASANA_TOKEN" ]; then
  echo "WARNING: ASANA_PAT not set — skipping Asana task creation."
  echo "Brief saved to: $OUTPUT_FILE"
  exit 0
fi

echo "Creating Asana task..."

TASK_NAME="Standup Brief — $DAY"

RESPONSE=$(python3 << PYEOF
import json, urllib.request, urllib.error, ssl, certifi

token      = "$ASANA_TOKEN"
date_str   = "$DATE"
time_str   = "$TIME_IST"
task_name  = "$TASK_NAME"
workspace  = "$ASANA_WORKSPACE"
assignee   = "$ASANA_ASSIGNEE"
brief_file = "$OUTPUT_FILE"

with open(brief_file, "r") as f:
    brief_content = f.read()

notes = (
    f"Auto-generated standup brief — {date_str} · {time_str}\n"
    f"Generated by: standup.sh v6 · Claude Code + MCP + GitHub API\n\n"
    f"{brief_content}"
)

payload = json.dumps({
    "data": {
        "name":      task_name,
        "assignee":  assignee,
        "workspace": workspace,
        "due_on":    date_str,
        "notes":     notes,
    }
}).encode("utf-8")

ctx = ssl.create_default_context(cafile=certifi.where())
req = urllib.request.Request(
    "https://app.asana.com/api/1.0/tasks",
    data=payload,
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type":  "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, context=ctx) as resp:
        result = json.loads(resp.read().decode("utf-8"))
        gid    = result.get("data", {}).get("gid", "")
        print(f"TASK_GID={gid}")
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8")
    print(f"HTTP_ERROR={e.code} {body}")
except Exception as e:
    print(f"ERROR={e}")
PYEOF
)

if echo "$RESPONSE" | grep -q "^TASK_GID="; then
  TASK_GID=$(echo "$RESPONSE" | grep "^TASK_GID=" | cut -d= -f2)
  TASK_URL="https://app.asana.com/0/0/$TASK_GID/f"
  echo "Asana task created: $TASK_NAME"
  echo "Link: $TASK_URL"
  {
    echo ""
    echo "---"
    echo "_Asana task created: $TASK_NAME · $TASK_URL"
  } >> "$OUTPUT_FILE"
else
  echo "WARNING: Asana task creation failed."
  echo "$RESPONSE"
  echo "Brief still saved to: $OUTPUT_FILE"
fi

echo "Done. Brief at: $OUTPUT_FILE"
echo "========================================"
