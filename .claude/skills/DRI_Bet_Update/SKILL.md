---
name: DRI_Bet_Update
description: >
  Generic iteration report generator for any PM who is DRI of a Groupon bet.
  Collects Jira deliverables, Tempo time logs, Asana meeting notes, roadmap, and
  team 5/15s; synthesizes a GROW² plan + Retrospective; outputs an HTML report and
  posts to Asana. Invoke when a PM says "run DRI update", "generate iteration report",
  or "/DRI_Bet_Update". Requires bet configuration to be filled in (see BET CONFIG
  section). The giq-report skill is a pre-configured instance of this pattern for GIQ.

  MCP setup (Groupon CoS standard):
  - Jira/Confluence: Atlassian MCP (groupondev.atlassian.net)
  - Asana: Asana MCP (groupon.com workspace, GID 8437193015852)
  - Tempo: direct Echelon API via bash curl (not MCP — requires Echelon endpoint access)
---

# DRI Bet Update

Generates bi-weekly (or sprint-cadence) iteration reports for any Groupon bet.
Produces a GROW² plan for the next sprint and a Retrospective for the completed one.

**Setup guide (MCPs, Asana IDs, Jira IDs, Tempo):** see [README.md](README.md)

## Usage
/DRI_Bet_Update [start_date] [end_date] [iteration_name]

Example: /DRI_Bet_Update 2026-04-01 2026-04-14 "HBW Sign-Up — AI Draft V2"

---

## ① BET CONFIGURATION

**This is a template. Do not fill this in manually — run `/DRI_Bet_Update` and the
setup wizard will configure it for you and write a new skill to your workspace.**

```yaml
__status__: UNCONFIGURED
bet_slug: "my-bet-report"
bet_name: "Bet Name Here"
jira_cloud_id: "d22269b5-12fa-4277-9276-734d96c6467d"
jira_projects:
  - key: "PROJ"
    parent_epic: "PROJ-XXXX"
jira_metric_baseline_ticket: "QR-XXXX"
asana_iteration_project: "XXXX"
asana_meeting_tasks:
  - gid: "XXXX"
    label: "Team Meetings"
asana_515_tasks:
  - name: "Name Surname"
    gid: "XXXX"
streams:
  - name: "Stream 1 Name"
    keywords: ["keyword1", "keyword2"]
  - name: "Stream 2 Name"
    keywords: ["keyword3", "keyword4"]
  - name: "Both / Platform"
    keywords: ["architecture", "infrastructure", "shared"]
team:
  product:
    - name: "Name Surname"
      jira_account_id: "712020:xxxx"
  engineering:
    - name: "Name Surname"
      jira_account_id: "712020:xxxx"
tempo_giq_issue_overrides: []
asana_additional_sources: []
asana_additional_515s: []
```

---

## Wizard Mode

**Triggered when:** the BET CONFIG block contains `__status__: UNCONFIGURED`.

When this skill is invoked and the sentinel is present, ignore the rest of this file and run the setup wizard instead. Do not attempt to generate a report.

### Detection

Before doing anything else, read the BET CONFIG yaml block above. If `__status__: UNCONFIGURED` is present as the first line → run the wizard below. If absent → skip to `## Steps` and generate the report normally.

---

### Setup Wizard

Greet the PM:

```
Welcome to DRI Bet Update setup.
I'll ask you a few questions to configure this plugin for your bet.
This will create a new skill ready to use — nothing is written until you confirm.

Type 'cancel' at any time to abort without writing anything.
```

Then collect values one at a time, in this order. For **required multi-entry fields**, a minimum of one entry is needed — re-prompt if the PM tries to skip. For **optional fields**, zero entries is valid.

#### Block 1 — Identity

**Question 1 — Bet name**
> "What is the name of your bet? (e.g. 'HBW Sign-Up', 'Merchant Tools')"

Store as `bet_name`.

**Question 2 — Skill slug**
> "What slug should I use for the skill command? I'll suggest one based on your bet name.
> Suggested: `{bet_name_lowercased_hyphenated}-report` — confirm or type a different slug:"

Rules for the suggestion: lowercase, spaces → hyphens, remove special characters, append `-report`.
Example: "HBW Sign-Up" → `hbw-sign-up-report`.

Store as `bet_slug`.

**Slug collision check:** Before proceeding, check whether `.claude/skills/{bet_slug}/` already exists in the workspace. If it does:
> "A skill already exists at `.claude/skills/{bet_slug}/`. Continuing will overwrite it. Proceed? (yes/no)"

Wait for response. If no → re-ask Question 2 for a different slug.

#### Block 2 — Jira

**Question 3 — Jira cloud ID**
> "Jira cloud ID — this is the same for all Groupon bets. Confirm or override:
> `d22269b5-12fa-4277-9276-734d96c6467d`"

Default to the Groupon ID if the PM just presses Enter / says yes.

**Question 4 — Jira project keys** (required, minimum one)
> "What Jira project key(s) track delivery work for this bet? Enter one key (e.g. 'MCE'):"

After each entry: "Add another project key? (Enter key or press Enter to continue)"
Loop until the PM skips.

**Question 5 — Epic scope** (per project, optional)
For each project key collected in Question 4:
> "Does another bet also use the '{KEY}' project? If so, enter the parent epic key to scope to (e.g. 'MCE-1234'), or press Enter to skip:"

If a key is provided, attach as `parent_epic` to that project entry.

**Question 6 — Metric baseline ticket**
> "Enter the Jira ticket key that holds your GRO targets and kill-gate thresholds (e.g. 'QR-1234'):"

**Question 7 — Tempo issue overrides** (optional)
> "Are there Jira issues outside your listed projects that should count as bet work (e.g. a cross-team ticket)? Enter a numeric issue ID and a short note, or press Enter to skip:"

After each entry: "Add another override? (Enter numeric ID or press Enter to continue)"
Numeric ID only — not the ticket key (e.g. `5010744`, not `MBNXT-32154`).

#### Block 3 — Asana

**Question 8 — Iteration reports project GID** (required)
> "What is the GID of your iteration reports Asana project?
> Hint: open the project in Asana → copy the number from the URL (app.asana.com/0/**{GID}**/...)"

**Question 9 — Meeting notes parent task GIDs** (required, minimum one)
> "Enter the GID of a meeting notes parent task and a short label (e.g. 'Team Meetings'):"

After each entry: "Add another meeting notes task? (Enter GID and label or press Enter to continue)"

**Question 10 — 5/15 parent task GIDs** (required, minimum one)
> "Enter the name and GID of a 5/15 parent task (format: 'Name Surname, GID'):"

After each entry: "Add another 5/15 task? (Enter name, GID or press Enter to continue)"

#### Block 4 — Team & Streams

**Question 11 — Team members** (required, minimum one)

Collect each team member via three separate prompts in sequence:
> "Team member name: (e.g. 'Jane Smith')"
> "Product or Engineering?"
> "Jira account ID: (format: `712020:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)"

After all three: "Add another team member? (yes/no)"
No format validation on account ID — trust user input.

**Question 12 — Work streams** (required, minimum one)
> "Enter a work stream name and its classification keywords (format: 'Stream Name, keyword1, keyword2, ...'):"

After each entry: "Add another stream? (Enter details or press Enter to continue)"

#### Block 5 — Optionals

**Question 13 — Additional Asana sources** (optional)
> "Do you have extra Asana project sections to pull as completed/in-progress items (e.g. a PM planning board)? (yes/no)"

If yes, collect each source via four separate prompts in sequence:
> "Project GID:"
> "Section GID:"
> "Stream name: (must match one of the streams you entered above)"
> "Display label: (e.g. 'AI Deal Creation Iteration Input')"

After all four: "Add another Asana source? (yes/no)"

**Question 14 — Additional 5/15s** (optional)
> "Do you have 5/15 tasks from people outside your core bet team (e.g. a Sales PM)? (yes/no)"

If yes, collect each person via three separate prompts in sequence:
> "Person's name:"
> "Parent task GID:"
> "Filter keywords: (comma-separated — only 5/15 content mentioning these words will be extracted, e.g. 'GIQ Sales Rollout, GrouponIQ')"

After all three: "Add another person? (yes/no)"

---

### Confirmation

Render the full collected config as a YAML block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONFIG SUMMARY — {bet_name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[full yaml block]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Does this look right?
  [yes]    → write the file
  [edit]   → change a specific field
  [cancel] → abort, nothing written
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If edit:** Display a numbered list of all collected fields. PM enters a number; re-prompt that field using the same question as the original collection step. After the new value is entered, regenerate the full summary and ask again (yes / edit / cancel). No limit on edit rounds.

**If cancel:** Output "Setup cancelled. No files written." and stop.

---

### Writing the Output File

On confirmation, write `.claude/skills/{bet_slug}/SKILL.md` as follows:

1. Copy the full content of this file (DRI_Bet_Update/SKILL.md) verbatim.
2. Locate the BET CONFIG replacement range: find the section header `## ① BET CONFIGURATION`, then find the ` ```yaml` fence immediately following it, then find the closing ` ``` ` fence. This is the range to replace.
3. Replace that range (including the fences) with the collected config as a yaml block. The sentinel line (`__status__: UNCONFIGURED`) is omitted. No inline comments. Field order: `bet_slug`, `bet_name`, then Jira fields, then Asana fields, then team/streams, then optionals.
4. Replace the instructional text immediately above the yaml block with: `**Configured for {bet_name}. To reconfigure, delete this skill folder and re-run setup from the DRI_Bet_Update template.**`
5. Delete this entire `## Wizard Mode` section from the output file (from `## Wizard Mode` through the `---` separator immediately before `## Steps`). The output skill file goes straight to `## Steps`.
6. All other content is copied unchanged.

After writing, output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plugin configured for "{bet_name}".

New skill created: .claude/skills/{bet_slug}/SKILL.md

To run your first iteration report:
  /{bet_slug} 2026-04-01 2026-04-14 "Iteration Name"

To reconfigure: delete .claude/skills/{bet_slug}/, copy
DRI_Bet_Update/ again, run /DRI_Bet_Update, choose a new slug.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Steps

1. Parse inputs (start_date, end_date, iteration_name)
2. Dispatch four parallel subagents
3. Synthesize GROW² + Retrospective draft
4. Show draft for review
5. Generate HTML report → post to Asana on approval

---

## Subagent 1: Meeting Notes

Dispatch as a parallel subagent with the following prompt:

---
You are collecting meeting notes for the {bet_name} iteration from {start_date} to {end_date}.

### Source: Asana Meeting Notes

Use the **Asana MCP** (`Asana:get_task`).

Query each parent task listed in `asana_meeting_tasks`:
- Call `Asana:get_task` with the task GID
- **Do NOT filter by title** — all subtasks are bet-related meetings
- Parse the date from the subtask name (expected: "[Title] — YYYY-MM-DD")
- Skip subtasks whose date cannot be parsed (log a warning)
- Include only subtasks where the parsed date falls within [{start_date}, {end_date}]
- For each included subtask: call `Asana:get_task` with the subtask GID; extract SUMMARY, ACTION ITEMS, DECISIONS, and BLOCKERS sections from the notes field

### Output
```json
{
  "meetings": [
    {
      "date": "YYYY-MM-DD",
      "title": "string",
      "source": "asana",
      "summary": "string",
      "decisions": ["string"],
      "action_items": ["string"],
      "blockers": ["string"],
      "prototype_links": ["string"]
    }
  ]
}
```
For `prototype_links`: scan all text for URLs containing "figma", "staging", "prototype", "demo", "preview".
If no meetings found, return `{ "meetings": [] }` — do not fail.
---

## Subagent 2: Jira + Tempo

Dispatch as a parallel subagent with the following prompt:

---
You are collecting Jira deliverables and Tempo time logs for the {bet_name} iteration from {start_date} to {end_date}.

**Team classification (from config):**
- Product: {team.product names}
- Engineering: {team.engineering names}
- Other: anyone not in the above lists

**Stream classification (from config):**
Classify each ticket and roadmap item into one of the configured streams using keyword matching on the ticket summary. Use assignee as tiebreaker when keywords are ambiguous.

**Run Steps 1, 2, 2b, 2c, and 3 in parallel.**

### Step 1: Metric baselines

Use the **Atlassian MCP** (`Atlassian:getJiraIssue`) with:
- cloudId: {jira_cloud_id}
- issueIdOrKey: {jira_metric_baseline_ticket}

Extract all GRO/metric targets, kill-gate thresholds, and milestone dates from the description.

### Step 2: Resolved + in-progress tickets — primary project(s)

Use the **Atlassian MCP** (`Atlassian:searchJiraIssuesUsingJql`).

For each project in `jira_projects` (without a parent_epic):

Resolved:
- cloudId: {jira_cloud_id}
- jql: `project = {PROJECT_KEY} AND status in (Done, Released) AND resolutiondate >= "{start_date}" AND resolutiondate <= "{end_date}"`
- fields: ["summary", "assignee", "status", "issuetype", "id"]

In-progress:
- cloudId: {jira_cloud_id}
- jql: `project = {PROJECT_KEY} AND status in ("In Progress", "In Review")`
- fields: ["summary", "assignee", "status", "issuetype", "id"]

### Step 2b: Resolved + in-progress tickets — epic-scoped project(s)

Use `Atlassian:searchJiraIssuesUsingJql` for each project in `jira_projects` with a `parent_epic`:

Resolved:
- cloudId: {jira_cloud_id}
- jql: `parent = {PARENT_EPIC} AND status in (Done, Released) AND statusCategoryChangedDate >= "{start_date}" AND statusCategoryChangedDate <= "{end_date}"`
- fields: ["summary", "assignee", "status", "issuetype", "id", "resolutiondate"]
- Fallback if zero results: `parent = {PARENT_EPIC} AND status changed to Done AFTER "{start_date}" AND status changed to Done BEFORE "{end_date}"`

In-progress:
- cloudId: {jira_cloud_id}
- jql: `parent = {PARENT_EPIC} AND status in ("In Progress", "In Review", "Review", "Merge")`
- fields: ["summary", "assignee", "status", "issuetype", "id"]

### Step 2c: Additional Asana sources (optional)

If the bet config includes `asana_additional_sources`, query each one using the **Asana MCP** (`Asana:get_tasks`):
- Pass the project GID and section GID
- Read full task details for each returned task using `Asana:get_task`
- Include tasks completed within [{start_date}, {end_date}] as additional completed items
- Include uncompleted tasks as additional in-progress items
- Use the configured stream classification when presenting in the report

```yaml
asana_additional_sources:
  - project: "1213884046770720"
    section: "1213884046770741"
    stream: "AI Deal Creation"
    label: "AI Deal Creation Iteration Input"
```

### Step 3: Tempo worklogs via Echelon

> **Note:** Tempo is accessed via a direct Echelon API endpoint, not via MCP.
> This step requires access to the Echelon service at octopus-app-zcwpc.ondigitalocean.app.
> If the endpoint is unavailable, skip this step and return `"time_spent": null`.

Call the Echelon endpoint directly via Bash:

```bash
curl -s -X POST https://octopus-app-zcwpc.ondigitalocean.app/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "jira.worklogs.getWorklogsForUsers",
      "arguments": {
        "jiraUserIds": ["{all team jira_account_ids}"],
        "startDate": "{start_date}",
        "endDate": "{end_date}"
      }
    }
  }'
```
Parse the worklog array from `result.content[0].text`.

### Step 4: Filter to bet epics and aggregate hours

**Scope:** Only count time logged against issues that belong to this bet's Jira projects/epics. Time on other projects is excluded.

**Step 4a: Identify bet issue IDs**
1. Collect all unique `jiraIssueId` values from the raw worklogs
2. Add any IDs listed in `tempo_giq_issue_overrides` unconditionally
3. For the remaining IDs, split into batches of 60 and run JQL per batch using `Atlassian:searchJiraIssuesUsingJql`:
   - cloudId: {jira_cloud_id}
   - jql: `project in ({PROJECT_KEYS}) AND id in (<batch>)`
   - If an epic scope applies: also include `parent = {PARENT_EPIC} AND id in (<batch>)`
   - Only fields `["id", "key"]` needed
4. Build the final set: all IDs returned by JQL queries + override IDs

**Step 4b: Filter and aggregate**
- Keep only worklogs where `jiraIssueId` is in the bet issue set
- For each kept worklog: look up the author, classify as Product/Engineering/Other
- Sum `timeSpentSeconds` per person ÷ 3600 = hours
- Sum Product total and Engineering total (Other shown in breakdown only)

### Output
```json
{
  "metric_baselines": {
    "targets": ["string"],
    "kill_gates": ["string"],
    "milestones": ["string"]
  },
  "completed_tickets": [
    {
      "key": "string",
      "summary": "string",
      "assignee": "string",
      "team": "Product | Engineering | Other",
      "stream": "string",
      "issue_type": "string"
    }
  ],
  "in_progress_tickets": [
    { "key": "string", "summary": "string", "assignee": "string", "stream": "string" }
  ],
  "time_spent": {
    "product_hours": 0.0,
    "engineering_hours": 0.0,
    "total_hours": 0.0,
    "by_person": [
      { "name": "string", "team": "string", "hours": 0.0 }
    ]
  }
}
```
If Tempo returns no data or is unavailable, return `"time_spent": null` — master agent omits the section entirely.
---

## Subagent 3: Roadmap

Dispatch as a parallel subagent with the following prompt:

---
You are collecting the {bet_name} roadmap to inform the GROW² plan for the next iteration.

Use the **Asana MCP** for all queries.

### Doing tasks

First call `Asana:get_project` with the project GID `{asana_iteration_project}` to retrieve all sections and their GIDs. Find the section named "Doing".

Then call `Asana:get_tasks` with:
- project: {asana_iteration_project}
- section: the "Doing" section GID

### Planned tasks

Using the same project sections from `Asana:get_project`, find the section named "Planned".

Call `Asana:get_tasks` with:
- project: {asana_iteration_project}
- section: the "Planned" section GID

For each task in both sections, call `Asana:get_task` to read the full description and notes.

### Output
```json
{
  "roadmap_items": [
    {
      "name": "string",
      "status": "Doing | Planned",
      "stream": "string",
      "assignee": "string",
      "due_date": "YYYY-MM-DD | null",
      "description": "string",
      "prototype_links": ["string"]
    }
  ]
}
```
Order: Doing tasks first, then Planned ordered by due_date ascending (nulls last).
Classify stream using the keywords defined in the bet config.
For `prototype_links`: scan task description for URLs containing "figma", "staging", "prototype", "demo", "preview".
If both sections are empty, return `{ "roadmap_items": [] }`.
---

## Subagent 4: 5/15 Reviews

Dispatch as a parallel subagent with the following prompt:

---
You are collecting 5/15 weekly updates for the {bet_name} team members for the week that overlaps with or immediately follows {end_date}. The 5/15 deadline is Friday — pick the Friday on or just after {end_date}.

Use the **Asana MCP** for all queries.

### People and their parent task GIDs
{asana_515_tasks: name → gid}

### Step 1: Get subtask lists
For each person, call `Asana:get_task` with their parent GID. The response includes subtasks — retrieve them.

### Step 2: Find the target week
Identify the subtask dated closest to and no earlier than {end_date}. Expected format: "5/15 - Name - YYYY-MM-DD". Accept any subtask within 7 days after {end_date}; if none, take the most recent before {end_date}.

### Step 3: Read subtask content
Call `Asana:get_task` on each identified subtask. Read the `notes` field.

### Step 4: Filter for bet-relevant content only
Extract ONLY information directly related to {bet_name} and its work streams ({stream names from config}). Exclude: other bets, personal items, KTLO unrelated to this bet, generic AI tips.

### Output
```json
{
  "five_fifteens": [
    {
      "person": "string",
      "week_ending": "YYYY-MM-DD",
      "bet_relevant": [
        {
          "topic": "string",
          "stream": "string",
          "content": "string",
          "status": "Done | In Progress | Blocked | Risk | New",
          "action_items": ["string"]
        }
      ],
      "submitted": true
    }
  ]
}
```
If a person did not submit, set `"submitted": false` and `"bet_relevant": []`.
If their 5/15 has no bet-relevant content, set `"bet_relevant": []` and note it silently.
---

## Master Agent: Parallel Dispatch + Synthesis

### Step 1: Parse inputs
Extract start_date, end_date, iteration_name from the invocation.
If any are missing, prompt the user before proceeding.
Load the BET CONFIGURATION block from this skill file.

### Step 2: Dispatch subagents in parallel
Launch all four subagents simultaneously using the Agent tool.
Wait for all four before proceeding.

### Step 3: Synthesize GROW²

**Goal**
1–3 sentences describing what the next iteration achieves and how it advances the bet's GRO targets. Draw from the top Doing + Planned roadmap items. Write as an outcome (what changes), not a task list.

**Results**
Select 1–3 metrics from `metric_baselines.targets` that this iteration's deliverables can move. For each: metric name, baseline → target, kill-gate threshold.

**Owners**
RASCI table:
- R (Responsible): assignees from Doing + Planned roadmap items, grouped as Product / Engineering
- A (Accountable): Marie Havlíčková (always)
- S/C/I: leave blank

**Workplan**
Doing + Planned roadmap items grouped by stream. Sequential steps with brief duration estimates per step. Warn if total estimated scope across all streams exceeds 30 MD.

### Step 4: Synthesize Retrospective

**1. Iteration Results**
Completed tickets grouped by stream. Include key, summary, assignee. Flag any Doing roadmap items with no corresponding completed ticket. Note milestones due in this period.

**2. Key Learnings**
Three sources combined:
1. Meeting decisions, blockers, action items (Subagent 1)
2. Completed vs. in-progress ticket gap analysis (Subagent 2)
3. 5/15 bet-relevant items that add new signal not already captured (Subagent 4)

- "What worked": decisions made, features shipped, positive signals
- "What didn't work": blockers, slipped items, adoption risks, delivery risks

**3. Gate Decision (Recommendation)**
Delivery rate = resolved / (resolved + in-progress) × 100

| Rate | Recommendation |
|---|---|
| ≥ 80% | CONTINUE or SCALE |
| 50–79% | CONTINUE (flag for review) |
| < 50% | STOP |
| 0% | CONTINUE (low confidence — flag) |

Present as: "Recommended gate decision: [X] — [one sentence rationale]"
Always label as a recommendation. DRI confirms before posting.

**4. Next Steps**
If CONTINUE or SCALE: "Next iteration section and GROW² created in this run."
If STOP: "[PLACEHOLDER — DRI to document rationale and alternative approach]"

**5. Time Spent**
Omit entirely if `time_spent` is null.
If present:
```
Product:     XX.X hours
Engineering: XX.X hours
Total:       XX.X hours  ← Product + Engineering only

By person:
- [Name] (Product): X.X hrs
- [Name] (Engineering): X.X hrs
```

---

## Draft Review

Render the full draft in this format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{bet_name} ITERATION REPORT DRAFT
{start_date} → {end_date} | {iteration_name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

── GROW² ──────────────────────────────────
Goal:
[content]

Results:
[content]

Owners:
[content]

Workplan:
[content]

── RETROSPECTIVE ───────────────────────────
1. Iteration Results
[content]

2. Key Learnings
[content]

3. Gate Decision
[content]

4. Next Steps
[content]

[5. Time Spent — omit heading if time_spent is null]
[content]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
What would you like to do?
  [P] Post to Asana + generate HTML
  [E] Edit first
  [C] Cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for input:
- **P**: generate HTML report (see below), then post to Asana
- **E**: prompt for edited content (GROW² first, then Retrospective); show updated draft; ask for final confirmation
- **C**: output "Cancelled. No changes made." and stop

### HTML Report Generation (runs before Asana write on P)

Save to `docs/plans/{bet_slug}-report-{start_date}-{end_date}.html` and copy to `~/Downloads/`.

**Structure:** Single-page HTML, max-width 900px, white card on gray background, dark green header (`#1d3a2e`). Sections in order:
1. **Header** — bet name, iteration name, date range, generated date
2. **Executive Summary** — Gate decision badge (green=CONTINUE/SCALE, amber=flag, red=STOP), delivery rate, 2–3 sentence narrative
3. **Iteration Results** — completed tickets grouped by stream; each with key, summary, assignee
4. **Time Spent** — three stat cards (Product / Engineering / Total); omit if null
5. **Key Learnings** — two-column grid (What worked / What didn't work)
6. **Next Steps** — numbered priority list
7. **Appendix: Roadmap** — Doing then Planned, with stream badges and due dates
8. **Appendix: Time Spent Breakdown** — per-person table; greyed rows for 0h; footnote explaining scope
9. **Appendix: Ticket Reference** — full ticket list sortable by stream

Stream badges: colour-coded pills per stream name (first stream = green, second = blue, platform/both = gray).
Gate decision: prominent badge at top of Executive Summary.

---

## Asana Write Operations

Execute in sequence after approval. Use the **Asana MCP** for all write operations.

### Section naming
Format: `[MM/DD/YY-MM/DD/YY] {iteration_name}`
Example: `[04/01/26-04/14/26] HBW Sign-Up — AI Draft V2`

### Step 1: Check for existing section
Call `Asana:get_project` with project GID `{asana_iteration_project}` to retrieve all sections.
If a section with this name already exists, warn the user and ask whether to proceed or cancel.

### Step 2: Create parent task
Use `Asana:create_task_preview` to show a preview first, then confirm:
- Name: `[MM/DD/YY-MM/DD/YY] {iteration_name}`
- Project: {asana_iteration_project}

### Step 3: Create Iteration GROW² task
Use `Asana:create_task_preview`:
- Name: "Iteration GROW²"
- Notes: [synthesized GROW² content]
- Parent: GID from Step 2

### Step 4: Create Iteration Retrospective task
Use `Asana:create_task_preview`:
- Name: "Iteration Retrospective"
- Notes: [synthesized Retrospective content]
- Parent: GID from Step 2

### Step 5: Confirm success
Output links to the created tasks and parent task URL.

---

## Edge Cases

- **No meetings in window:** Continue; Key Learnings flagged as sparse.
- **5/15 not submitted:** Set `submitted: false`; note in Key Learnings.
- **5/15 has no bet-relevant content:** Silently skip that person.
- **No Tempo data / Echelon unavailable:** Omit Time Spent section entirely — set `time_spent: null`.
- **No resolved Jira tickets:** Delivery rate = 0; Gate = CONTINUE (low confidence — flag).
- **Iteration scope > 30 MD:** Warn in draft that workplan exceeds GROW² limit.
- **Gate Decision = STOP:** Next Steps left as placeholder.
- **Assignee not in team config:** Classified as Other; excluded from totals.
- **Meeting date unparseable:** Skip with log warning; continue.
- **Section already exists in Asana:** Warn user, ask to proceed or cancel.
- **Metric baseline ticket not found:** Note in Results section; continue without targets.
- **Atlassian MCP returns error:** Log inline, continue with available data.
- **Asana MCP returns error:** Log inline, continue with available data.
