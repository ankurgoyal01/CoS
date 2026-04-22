#!/bin/bash
# tdd-specialist.sh — Per-ticket TDD generator with retry, validation, and knowledge base
#
# Called by tdd-watcher.sh — one instance per ticket, runs in parallel.
# Flow:
#   1. Load knowledge base — find similar past tickets for context
#   2. Generate TDD via Claude (up to 3 attempts)
#   3. Validate TDD on each attempt — retry with failure reason if invalid
#   4. On success: generate .docx, attach to Jira, update estimate, save to KB
#   5. On all retries failed: post Jira comment with actual reason

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
TICKET_KEY="$1"
TICKET_JSON="$2"

# ── Config ────────────────────────────────────────────────────────────────────
JIRA_BASE="https://groupondev.atlassian.net"
ATLASSIAN_EMAIL="${ATLASSIAN_EMAIL:-}"
ATLASSIAN_TOKEN="${ATLASSIAN_TOKEN:-}"
CLAUDE_BIN="/opt/homebrew/bin/claude"
MAX_RETRIES=3
DATE=$(TZ="Asia/Kolkata" date +"%Y-%m-%dT%H:%M:%S IST" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%S UTC")
DATE_SHORT=$(TZ="Asia/Kolkata" date +"%Y-%m-%d" 2>/dev/null || date -u +"%Y-%m-%d")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KB_DIR="$SCRIPT_DIR/knowledge"
KB_FILE="$KB_DIR/tdd-kb.json"
TMP_DIR=$(mktemp -d)
DOCX_FILE="$TMP_DIR/TDD-$TICKET_KEY-$DATE_SHORT.docx"

mkdir -p "$KB_DIR"

# Initialise KB if missing
if [ ! -f "$KB_FILE" ]; then
  echo '{"version":"1.0","entries":[]}' > "$KB_FILE"
fi

echo "[$TICKET_KEY] Starting — $(TZ='Asia/Kolkata' date +%H:%M IST)"

# ── Extract ticket details ────────────────────────────────────────────────────
SUMMARY=$(echo  "$TICKET_JSON" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['summary'])")
PRIORITY=$(echo "$TICKET_JSON" | python3 -c "import json,sys; t=json.loads(sys.stdin.read()); p=t.get('priority','Medium'); print(p if isinstance(p,str) else p.get('name','Medium') if isinstance(p,dict) else 'Medium')")
TYPE=$(echo     "$TICKET_JSON" | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['type'])")
DESC=$(echo     "$TICKET_JSON" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('desc','No description provided.'))")
COMMENTS=$(echo "$TICKET_JSON" | python3 -c "
import json, sys
t = json.loads(sys.stdin.read())
c = t.get('comments', [])
print('\n'.join(f'- {x}' for x in c) if c else 'No comments.')
")

echo "[$TICKET_KEY] $SUMMARY ($PRIORITY)"

# ── Load knowledge base — find similar past tickets ───────────────────────────
KB_CONTEXT=$(python3 << PYEOF
import json, re

with open("$KB_FILE") as f:
    kb = json.load(f)

entries = [e for e in kb.get("entries", []) if e.get("outcome") == "success"]
if not entries:
    print("No similar tickets in knowledge base yet.")
    exit(0)

# Keyword extraction from new ticket
summary = """$SUMMARY""".lower()
desc    = """$DESC""".lower()
text    = summary + " " + desc
words   = set(re.findall(r'\b[a-z]{4,}\b', text))
stop    = {"this","that","with","from","have","been","will","when","then",
           "also","into","they","their","there","about","which","were","what"}
words  -= stop

# Score each KB entry by keyword overlap + recency
scored = []
for e in entries:
    kb_text    = (e.get("summary","") + " " + " ".join(e.get("keywords",[]))).lower()
    kb_words   = set(re.findall(r'\b[a-z]{4,}\b', kb_text)) - stop
    overlap    = len(words & kb_words)
    if overlap > 0:
        scored.append((overlap, e))

scored.sort(key=lambda x: -x[0])
top = scored[:3]

if not top:
    print("No similar tickets found in knowledge base.")
    exit(0)

lines = ["SIMILAR PAST TICKETS (use as reference for estimate and approach):"]
for score, e in top:
    lines.append(f"\n--- {e['key']}: {e['summary']}")
    lines.append(f"Type: {e['type']} | Estimate: {e['estimate_hours']}h | Match score: {score}")
    lines.append(f"Solution approach: {e.get('proposed_solution','')[:200]}")
    lines.append(f"Components used: {', '.join(e.get('components',[])[:5])}")

print("\n".join(lines))
PYEOF
)

echo "[$TICKET_KEY] KB context loaded."

# ── Validation function ───────────────────────────────────────────────────────
validate_tdd() {
  local json_str="$1"
  python3 << PYEOF
import json, sys

raw = """$1"""
try:
    tdd = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"INVALID: JSON parse error — {e}")
    sys.exit(1)

errors = []

ps = tdd.get("problem_statement", "")
if not ps or len(ps.strip()) < 30:
    errors.append("problem_statement is empty or too short (< 30 chars)")

sol = tdd.get("proposed_solution", "")
if not sol or len(sol.strip()) < 30:
    errors.append("proposed_solution is empty or too short (< 30 chars)")

impl = tdd.get("technical_implementation", {})
if not isinstance(impl, dict):
    errors.append("technical_implementation must be an object")
else:
    comps = impl.get("components", [])
    steps = impl.get("deployment_steps", [])
    if not comps or len(comps) == 0:
        errors.append("technical_implementation.components is empty — must list at least one component")
    if not steps or len(steps) == 0:
        errors.append("technical_implementation.deployment_steps is empty — must list deployment steps")
    has_detail = (impl.get("apex_classes") or impl.get("flows") or
                  impl.get("objects_fields") or impl.get("integrations"))
    if not has_detail:
        errors.append("technical_implementation must include at least one of: apex_classes, flows, objects_fields, or integrations")

testing = tdd.get("testing_approach", "")
if not testing or len(testing.strip()) < 20:
    errors.append("testing_approach is empty or too vague")

rollback = tdd.get("rollback_plan", "")
if not rollback or len(rollback.strip()) < 20:
    errors.append("rollback_plan is empty or too vague")

hours = tdd.get("estimate_hours")
if hours is None:
    errors.append("estimate_hours is missing")
elif not isinstance(hours, (int, float)) or not (1 <= int(hours) <= 50):
    errors.append(f"estimate_hours must be a whole number between 1 and 50 (got: {hours})")

reasoning = tdd.get("estimate_reasoning", "")
if not reasoning or len(reasoning.strip()) < 20:
    errors.append("estimate_reasoning is empty — explain why this estimate was chosen")

if errors:
    print("INVALID: " + " | ".join(errors))
    sys.exit(1)
else:
    print("VALID")
    sys.exit(0)
PYEOF
}

# ── Retry loop — up to MAX_RETRIES attempts ───────────────────────────────────
TDD_JSON=""
LAST_FAILURE=""
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_RETRIES ]; do
  ATTEMPT=$((ATTEMPT + 1))
  echo "[$TICKET_KEY] Attempt $ATTEMPT of $MAX_RETRIES..."

  # Build retry context for attempts 2+
  RETRY_CONTEXT=""
  if [ $ATTEMPT -gt 1 ] && [ -n "$LAST_FAILURE" ]; then
    RETRY_CONTEXT="PREVIOUS ATTEMPT FAILED — fix these specific issues before responding:
$LAST_FAILURE

Do not repeat the same mistakes. Address each issue listed above."
  fi

  PROMPT="You are a senior Salesforce engineer at Groupon writing a Technical Design Document.

TICKET: $TICKET_KEY
TYPE: $TYPE
PRIORITY: $PRIORITY
SUMMARY: $SUMMARY

DESCRIPTION:
$DESC

RECENT COMMENTS:
$COMMENTS

$KB_CONTEXT

$RETRY_CONTEXT

TEAM CONTEXT:
- Stack: Apex, LWC, Flows, Triggers, Sales Cloud, Service Cloud
- Environments: Staging → QA Sandbox → Production (never modify prod directly)
- One trigger per object, handler class mandatory, bulkification required
- Managed packages: Unbabel, AdobeSign, Conga Composer, XFiles Pro, Data Connectiva
- Named Credentials for all external callouts
- Test coverage: 85%+ minimum, meaningful assertions, TestDataFactory

Output ONLY valid JSON — no preamble, no markdown fences, no explanation outside JSON:

{
  \"problem_statement\": \"min 50 chars — clear business problem being solved\",
  \"proposed_solution\": \"min 50 chars — high-level approach and solution overview\",
  \"technical_implementation\": {
    \"components\": [\"at least 1 — Salesforce components to create or modify\"],
    \"apex_classes\": [\"ApexClass names — empty array [] only if genuinely no Apex needed\"],
    \"flows\": [\"Flow names — empty array [] only if genuinely no Flow needed\"],
    \"objects_fields\": [\"Object.Field__c — empty array [] only if no field changes\"],
    \"integrations\": [\"external systems — empty array [] if none\"],
    \"deployment_steps\": [\"at least 2 ordered deployment steps\"]
  },
  \"assumptions\": [\"at least 1 assumption\"],
  \"open_questions\": [\"questions needing stakeholder input, or empty array\"],
  \"dependencies\": [\"other tickets or systems this depends on, or empty array\"],
  \"cross_team_collaboration\": [\"teams to involve, or empty array\"],
  \"testing_approach\": \"min 30 chars — how this will be tested\",
  \"rollback_plan\": \"min 30 chars — how to revert if something goes wrong\",
  \"risks\": [\"technical or delivery risks, or empty array\"],
  \"estimate_hours\": 8,
  \"estimate_reasoning\": \"min 30 chars — why this estimate, what drives complexity\"
}

Estimate scale (whole number 1-50):
1-4h:   trivial config, single field, simple formula
5-10h:  moderate Apex class, simple Flow, LWC component
11-20h: complex Apex + integration, trigger + handler pattern
21-35h: multi-object feature, new integration endpoint, complex orchestration
36-50h: major architectural change spanning multiple components and teams"

  # Call Claude
  RAW_RESPONSE=$("$CLAUDE_BIN" -p "$PROMPT" 2>&1) || {
    LAST_FAILURE="Claude CLI failed to execute on attempt $ATTEMPT"
    echo "[$TICKET_KEY] Attempt $ATTEMPT — Claude CLI error"
    sleep 5
    continue
  }

  # Extract JSON
  TDD_JSON=$(python3 << PYEOF
import re, sys
raw = """$RAW_RESPONSE"""
raw = re.sub(r'^\`\`\`json\s*', '', raw.strip())
raw = re.sub(r'\`\`\`\s*$',     '', raw.strip())
match = re.search(r'\{.*\}', raw, re.DOTALL)
if not match:
    print("")
else:
    print(match.group(0))
PYEOF
)

  if [ -z "$TDD_JSON" ]; then
    LAST_FAILURE="Attempt $ATTEMPT: Claude did not return valid JSON. Response was: $(echo "$RAW_RESPONSE" | head -c 200)"
    echo "[$TICKET_KEY] Attempt $ATTEMPT — no JSON in response"
    sleep 5
    continue
  fi

  # Validate TDD
  VALIDATION=$(python3 << PYEOF
import json, sys

raw = """$TDD_JSON"""
try:
    tdd = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"INVALID: JSON parse error — {e}")
    sys.exit(0)

errors = []
ps = tdd.get("problem_statement", "")
if not ps or len(ps.strip()) < 30:
    errors.append("problem_statement is empty or too short")
sol = tdd.get("proposed_solution", "")
if not sol or len(sol.strip()) < 30:
    errors.append("proposed_solution is empty or too short")
impl = tdd.get("technical_implementation", {})
if not isinstance(impl, dict):
    errors.append("technical_implementation must be an object")
else:
    if not impl.get("components"):
        errors.append("technical_implementation.components is empty")
    if not impl.get("deployment_steps"):
        errors.append("technical_implementation.deployment_steps is empty")
    if not (impl.get("apex_classes") or impl.get("flows") or
            impl.get("objects_fields") or impl.get("integrations")):
        errors.append("must include apex_classes, flows, objects_fields, or integrations")
if not tdd.get("testing_approach","") or len(tdd.get("testing_approach","").strip()) < 20:
    errors.append("testing_approach is empty or too vague")
if not tdd.get("rollback_plan","") or len(tdd.get("rollback_plan","").strip()) < 20:
    errors.append("rollback_plan is empty or too vague")
hours = tdd.get("estimate_hours")
if hours is None or not (1 <= int(hours) <= 50):
    errors.append(f"estimate_hours must be 1-50 (got: {hours})")
if not tdd.get("estimate_reasoning","") or len(tdd.get("estimate_reasoning","").strip()) < 20:
    errors.append("estimate_reasoning is empty")

if errors:
    print("INVALID: " + " | ".join(errors))
else:
    print("VALID")
PYEOF
)

  if echo "$VALIDATION" | grep -q "^VALID$"; then
    echo "[$TICKET_KEY] Attempt $ATTEMPT — validation passed"
    break
  else
    LAST_FAILURE="Attempt $ATTEMPT validation failed: $VALIDATION"
    echo "[$TICKET_KEY] Attempt $ATTEMPT — $VALIDATION"
    TDD_JSON=""
    sleep 5
  fi
done

# ── All retries failed — post failure comment to Jira ─────────────────────────
if [ -z "$TDD_JSON" ]; then
  echo "[$TICKET_KEY] All $MAX_RETRIES attempts failed. Posting failure comment to Jira..."

  FAILURE_REASON="$LAST_FAILURE"

  python3 -c "
import json, subprocess, os

reason = os.environ.get('FAILURE_REASON', '$FAILURE_REASON')
key    = '$TICKET_KEY'
base   = '$JIRA_BASE'
date   = '$DATE'
retries= '$MAX_RETRIES'

comment_text = (
    f'TDD Auto-Generation Failed

'
    f'The TDD agent attempted to generate a Technical Design Document for this ticket '
    f'{retries} times but could not produce a valid TDD.

'
    f'Reason: {reason}

'
    f'Action required: Please add more detail to the ticket description — '
    f'include the business problem, expected behaviour, affected objects/fields, '
    f'and any known technical constraints. Then move the ticket back to '
    f'Ready for Grooming/Estimation to trigger a new attempt.

'
    f'Attempted: {date}'
)

paragraphs = [
    {'type': 'paragraph', 'content': [{'type': 'text', 'text': line}]}
    for line in comment_text.split('
') if line.strip()
]

payload = json.dumps({'body': {'type': 'doc', 'version': 1, 'content': paragraphs}})

result = subprocess.run([
    'curl', '-s', '-u', f'$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN',
    '-X', 'POST',
    '-H', 'Content-Type: application/json',
    '-d', payload,
    f'{base}/rest/api/3/issue/{key}/comment'
], capture_output=True, text=True)

d = json.loads(result.stdout)
print(f'Failure comment posted: {d.get(chr(105)+chr(100), chr(63))}')
"

  # Save failure to KB for pattern analysis
  python3 << PYEOF
import json, re
from datetime import datetime

with open("$KB_FILE") as f:
    kb = json.load(f)

summary  = """$SUMMARY"""
keywords = list(set(re.findall(r'\b[A-Za-z]{4,}\b', summary)))[:10]

kb["entries"].append({
    "key":           "$TICKET_KEY",
    "summary":       summary,
    "type":          "$TYPE",
    "priority":      "$PRIORITY",
    "keywords":      keywords,
    "outcome":       "failed",
    "failure_reason":"$FAILURE_REASON",
    "attempts":      int("$MAX_RETRIES"),
    "created_at":    "$DATE"
})

with open("$KB_FILE", "w") as f:
    json.dump(kb, f, indent=2)

print("Failure recorded in knowledge base.")
PYEOF

  rm -rf "$TMP_DIR"
  echo "[$TICKET_KEY] Failed after $MAX_RETRIES attempts — comment posted, KB updated"
  exit 1
fi

# ── Success — extract fields ───────────────────────────────────────────────────
HOURS=$(echo "$TDD_JSON" | python3 -c "
import json,sys
t=json.loads(sys.stdin.read())
print(max(1,min(50,int(t.get('estimate_hours',8)))))")

echo "[$TICKET_KEY] Validated — $HOURS hours estimated"

# ── Generate .docx ────────────────────────────────────────────────────────────
echo "[$TICKET_KEY] Generating TDD document..."

python3 << PYEOF
import json
from docx import Document
from docx.shared import Pt, RGBColor, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH

tdd    = json.loads("""$TDD_JSON""")
key    = "$TICKET_KEY"
date   = "$DATE_SHORT"
summ   = """$SUMMARY"""
pri    = "$PRIORITY"
typ    = "$TYPE"
impl   = tdd.get("technical_implementation", {})
path   = "$DOCX_FILE"

doc = Document()
for section in doc.sections:
    section.top_margin    = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin   = Inches(1.2)
    section.right_margin  = Inches(1.2)

# Title
title = doc.add_heading("Technical Design Document", 0)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
for run in title.runs:
    run.font.color.rgb = RGBColor(0x1A, 0x3A, 0x2E)

# Metadata table
meta = doc.add_table(rows=5, cols=2)
meta.style = "Table Grid"
for i, (lbl, val) in enumerate([
    ("Ticket",    f"{key} — {summ}"),
    ("Type",      typ),
    ("Priority",  pri),
    ("Date",      date),
    ("Estimate",  f"{tdd.get('estimate_hours', 8)} hours"),
]):
    meta.rows[i].cells[0].text = lbl
    meta.rows[i].cells[1].text = val
    meta.rows[i].cells[0].paragraphs[0].runs[0].font.bold = True
    for cell in meta.rows[i].cells:
        for para in cell.paragraphs:
            for run in para.runs:
                run.font.size = Pt(10)

doc.add_paragraph()

def section(heading, content):
    h = doc.add_heading(heading, level=1)
    for run in h.runs:
        run.font.color.rgb = RGBColor(0x1A, 0x3A, 0x2E)
    if isinstance(content, list):
        for item in content:
            p = doc.add_paragraph(style="List Bullet")
            p.add_run(str(item)).font.size = Pt(10)
    elif content and isinstance(content, str):
        p = doc.add_paragraph(content)
        for run in p.runs:
            run.font.size = Pt(10)
    else:
        p = doc.add_paragraph("—")
        for run in p.runs:
            run.font.size = Pt(10)

def impl_section():
    h = doc.add_heading("Technical Implementation", level=1)
    for run in h.runs:
        run.font.color.rgb = RGBColor(0x1A, 0x3A, 0x2E)
    for sub, items in [
        ("Components",        impl.get("components", [])),
        ("Apex Classes",      impl.get("apex_classes", [])),
        ("Flows",             impl.get("flows", [])),
        ("Objects / Fields",  impl.get("objects_fields", [])),
        ("Integrations",      impl.get("integrations", [])),
        ("Deployment Steps",  impl.get("deployment_steps", [])),
    ]:
        if items:
            doc.add_heading(sub, level=2)
            for item in items:
                p = doc.add_paragraph(style="List Bullet")
                p.add_run(str(item)).font.size = Pt(10)

section("Problem Statement",        tdd.get("problem_statement", ""))
section("Proposed Solution",        tdd.get("proposed_solution", ""))
impl_section()
section("Assumptions",              tdd.get("assumptions", []))
section("Open Questions",           tdd.get("open_questions", []))
section("Dependencies",             tdd.get("dependencies", []))
section("Cross-team Collaboration", tdd.get("cross_team_collaboration", []))
section("Testing Approach",         tdd.get("testing_approach", ""))
section("Rollback Plan",            tdd.get("rollback_plan", ""))
section("Risks",                    tdd.get("risks", []))

# Estimate section
h = doc.add_heading("Estimate", level=1)
for run in h.runs:
    run.font.color.rgb = RGBColor(0x1A, 0x3A, 0x2E)
p = doc.add_paragraph()
r = p.add_run(f"{tdd.get('estimate_hours',8)} hours")
r.font.size = Pt(14); r.font.bold = True
r.font.color.rgb = RGBColor(0x1A, 0x3A, 0x2E)
p2 = doc.add_paragraph(tdd.get("estimate_reasoning",""))
for run in p2.runs:
    run.font.size = Pt(10)

doc.add_paragraph()
footer = doc.add_paragraph(
    f"Auto-generated by TDD Agent on {date}. "
    "Review and update before sprint commitment. "
    f"Jira: {key}"
)
footer.runs[0].font.size = Pt(9)
footer.runs[0].font.color.rgb = RGBColor(0x88, 0x87, 0x80)
footer.alignment = WD_ALIGN_PARAGRAPH.CENTER

doc.save(path)
print(f"Document saved: {path}")
PYEOF

# ── Attach .docx to Jira ──────────────────────────────────────────────────────
echo "[$TICKET_KEY] Attaching TDD document..."

FNAME=$(basename "$DOCX_FILE")
ATTACH_RESULT=$(curl -s   -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN"   -X POST   -H "X-Atlassian-Token: no-check"   -F "file=@$DOCX_FILE;type=application/vnd.openxmlformats-officedocument.wordprocessingml.document"   "$JIRA_BASE/rest/api/3/issue/$TICKET_KEY/attachments")
ATT_ID=$(echo "$ATTACH_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0].get('id','?') if isinstance(d,list) else '?')" 2>/dev/null || echo "?")
echo "Attached: $FNAME (ID: $ATT_ID)"

# ── Update Original Estimate ───────────────────────────────────────────────────
echo "[$TICKET_KEY] Setting estimate: $HOURS hours..."

# Try timetracking first
EST_RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
  -X PUT \
  -H "Content-Type: application/json" \
  -d "{\"fields\":{\"timetracking\":{\"originalEstimate\":\"${HOURS}h\"}}}" \
  "$JIRA_BASE/rest/api/3/issue/$TICKET_KEY")

if [ "$EST_RESULT" = "204" ] || [ "$EST_RESULT" = "200" ]; then
  echo "Estimate set via timetracking: ${HOURS}h"
else
  # Fallback: post estimate as comment so it's not lost
  curl -s -u "$ATLASSIAN_EMAIL:$ATLASSIAN_TOKEN" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"body\":{\"type\":\"doc\",\"version\":1,\"content\":[{\"type\":\"paragraph\",\"content\":[{\"type\":\"text\",\"text\":\"TDD Agent estimate: ${HOURS} hours. Time tracking field not enabled — please set Original Estimate manually.\"}]}]}}" \
    "$JIRA_BASE/rest/api/3/issue/$TICKET_KEY/comment" > /dev/null
  echo "Estimate posted as comment: ${HOURS}h (time tracking not enabled — set manually)"
fi

# ── Save success to knowledge base ────────────────────────────────────────────
echo "[$TICKET_KEY] Saving to knowledge base..."

python3 << PYEOF
import json, re

with open("$KB_FILE") as f:
    kb = json.load(f)

tdd      = json.loads("""$TDD_JSON""")
summary  = """$SUMMARY"""
impl     = tdd.get("technical_implementation", {})
keywords = list(set(re.findall(r'\b[A-Za-z]{4,}\b', summary)))[:15]
comps    = (impl.get("components", []) +
            impl.get("apex_classes", []) +
            impl.get("flows", []))[:8]

# Remove old entry for same key if exists (re-run scenario)
kb["entries"] = [e for e in kb["entries"] if e.get("key") != "$TICKET_KEY"]

kb["entries"].append({
    "key":              "$TICKET_KEY",
    "summary":          summary,
    "type":             "$TYPE",
    "priority":         "$PRIORITY",
    "keywords":         keywords,
    "estimate_hours":   int("$HOURS"),
    "problem_statement":tdd.get("problem_statement","")[:300],
    "proposed_solution":tdd.get("proposed_solution","")[:300],
    "components":       comps,
    "testing_approach": tdd.get("testing_approach","")[:200],
    "outcome":          "success",
    "attempts":         $ATTEMPT,
    "created_at":       "$DATE"
})

# Keep KB lean — max 200 successful entries, oldest first to drop
successes = [e for e in kb["entries"] if e.get("outcome") == "success"]
failures  = [e for e in kb["entries"] if e.get("outcome") != "success"]
if len(successes) > 200:
    successes = successes[-200:]
kb["entries"] = failures + successes

with open("$KB_FILE", "w") as f:
    json.dump(kb, f, indent=2)

print(f"KB updated — {len(successes)} successful entries")
PYEOF

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"
echo "[$TICKET_KEY] Complete — TDD attached, $HOURS hours set, KB updated"
echo "[$TICKET_KEY] $JIRA_BASE/browse/$TICKET_KEY"