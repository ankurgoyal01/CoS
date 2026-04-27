---
name: weekly-515-report
version: 1.0
description: >
  Generates Ankur Goyal's weekly 5/15 consolidated report for Josef Sima.
  Pulls live data from Jira (SFDC + GSOIT sprint), GitHub (PR counts),
  Asana (BET tasks), Gmail (this week), and Google Calendar, then assembles
  the report in Ankur's exact submitted format — KPIs, Delivered (self + team),
  Blocked, AI Signal, BET progress — and creates an Asana task with the draft.

  Trigger phrases (any of these starts the full chain):
  - "generate my 5/15", "run the 5/15", "weekly 5/15", "friday 5/15"
  - "prepare my weekly status report", "manager weekly update", "weekly report"
  - "what should I report this week", "draft this week's 5/15"
  - "generate the consolidated 5/15", "5/15 consolidation"
  - Any combination referencing 5/15, weekly report, or Josef report
---

# Weekly 5/15 Report Skill — v1.0

## What this skill does

Runs a 6-source chain and produces Ankur's weekly 5/15 in the exact format
he submits to Josef Sima every Thursday EOD.

**Chain order (fixed):**
1. Jira — sprint health, delivered tickets, blockers, AI workstreams (SFDC + GSOIT)
2. GitHub — Ankur's own PR count for the week (handle: agoyal)
3. BET status — pull all 5 active BETs from Jira (QR-1624, QR-1612, QR-1614, QR-1631, QR-1658)
4. Gmail — any escalations or blockers needing mention in Section 3
5. Asana — check for any overdue items or action flags
6. Asana task creation — saves draft as an Asana task for review

---

## Chain execution rules

- Run all steps without stopping for confirmation.
- Do not narrate steps — silent execution, single output.
- If a source fails, note inline and continue.
- The Echelon KPI numbers come from Echelon directly — if not available, leave as [pull from Echelon] placeholders.
- Always include ALL five BETs in Section 2 BET Progress Report.
- Total execution target: under 90 seconds.

---

## Step 1 — Jira Sprint Data (SFDC + GSOIT)

**MCP:** Atlassian MCP

Run these queries:

```
1a. Done/In Review/QA/Deploy this week:
    project in (SFDC, GSOIT) AND sprint in openSprints()
    AND status in (Done, "In Review", QA, Deploy)
    AND updated >= -7d ORDER BY assignee ASC

1b. Blocked:
    project in (SFDC, GSOIT) AND sprint in openSprints()
    AND status = Blocked

1c. Ankur's own PRs:
    project in (SFDC, GSOIT) AND sprint in openSprints()
    AND assignee = currentUser() AND updated >= -7d

1d. AI workstream tickets (always surface):
    SFDC-10243, SFDC-10242, SFDC-10221, GSOIT-6400, GSOIT-6429
```

**Compute for Section 2:**
- Team delivery grouped by person
- Ankur's own tickets (SFDC-10215, SFDC-10211, SFDC-10212 pattern — look for his assignments)
- Any carry-over tickets with age > 2 weeks

---

## Step 2 — GitHub PR Count (Ankur)

**MCP:** GitHub (groupon enterprise: github.groupondev.com)

```
Org: sox-inscope, salesforce
Author: agoyal
Date range: this week (Mon–Fri)
Pull: PRs opened + PRs merged
```

Use this as "PR count this week: N" in Section 2 Self.

---

## Step 3 — BET Status

**MCP:** Atlassian MCP — fetch each BET initiative

Fetch these five tickets and cross-reference with Jira sprint data for what happened this week:

| BET | Jira | Engineering owners |
|-----|------|--------------------|
| Margin Control | QR-1624 | Amit Patil, Niveditha Ramegowda |
| SF Cleanup & Optimization | QR-1612 | Nirajkumar Shelke, Ashwinkrishna M |
| Customer AI Agent | QR-1614 | Rakesh Haridas |
| Merchant Lifecycle Engine | QR-1631 | Ravi Kumar, Ravindra Kumar, Datta Maddala |
| PoF Ingresso INTL | QR-1658 | Nirajkumar Shelke |

For each BET produce the standard block (see Output Format → Section 2 BET).

**Progress baselines (update from memory when running):**
- QR-1624 Margin Control: 80% baseline (Apr 24)
- QR-1612 SF Cleanup: 40% baseline (Apr 24)
- QR-1614 Customer AI Agent: 55% baseline (Apr 24)
- QR-1631 Merchant Lifecycle: 50% baseline (Apr 24)
- QR-1658 PoF INTL: 65% baseline (Apr 24)

---

## Step 4 — Gmail (Blockers + Escalations)

**MCP:** Gmail MCP

Pull unread emails from the last 7 days from:
- Dennis Bertelkamp, Josef Sima, Michal Jilka, Chris Hill, Maciej Kołodziej, Zeph Buck

Flag any that represent a blocker or escalation needing mention in Section 3.
Skip automated notifications. Max 3 items.

---

## Step 5 — Asana

**MCP:** Asana MCP

Pull tasks assigned to Ankur (GID: 1211542692184092) that are:
- Overdue
- Due this week
- Any tasks where Ankur is mentioned in a comment in the last 48 hours

Use as signal for Section 3 if any are blocked or overdue.

---

## Step 6 — Create Asana Draft Task

**MCP:** Asana MCP

After full report is assembled:
- **Name:** `5/15 Draft — Ankur Goyal — [Day, Date]`
- **Assignee:** me (GID: 1211542692184092)
- **Workspace:** groupon.com (GID: 8437193015852)
- **Due date:** Thursday this week
- **Description:** Full report content
- **No project** — My Tasks only
- Do NOT ask for confirmation — create immediately

---

## Output Format

Produce exactly this structure. No preamble. No "here is your 5/15":

```
Updating the format as per new guidelines

5/15 — Ankur Goyal — Week of [Mon Date]–[Fri Date], [Year]
SFDC + GSOIT Engineering · [Sprint context e.g. Q2 Sprint 2, Week N]

────────────────────────────────────────
SECTION 1: ECHELON KPIs
────────────────────────────────────────
KPI                      | This Week | Last Week | Action if Off-Track
AI ROI %                 | [value]   | [value]   | Below 0% → review agent delegation quality
Review Coverage %        | [value]   | [value]   | Below 80% → process fix this week
Estimation Adherence %   | [value]   | [value]   | Below 70% → grooming quality issue
Bugs : Feature ratio     | [value]   | [value]   | Above average → slow down, focus Quality Wednesday
Rework Rate %            | [value]   | [value]   | Above 15% → improve spec quality or agent guidance
MTTV — AI PR review time | [value]   | [value]   | Above 3 days → identify and resolve bottleneck
Jira Linkage %           | [value]   | [value]   | Below 90% → call out in standup
Time Tracking %          | [value]   | [value]   |

[If any KPI is off-track, add a one-line note explaining root cause and action being taken]

────────────────────────────────────────
SECTION 2 — DELIVERED
────────────────────────────────────────
SELF (Ankur):
[Ticket key] [Status] — [Summary] : [PR status] :: [BET reference if applicable]
[Ticket key] [Status] — [Summary] : [PR status]
AI infrastructure: [N] automated scripts live on cron (see Section 4)
PR count this week: [N]

[Any operational actions taken as EM — deprecations, process changes, team comms]

BET PROGRESS REPORT
SFDC + GSOIT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[QR-XXXX] [BET Name]
https://groupondev.atlassian.net/browse/QR-XXXX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Status: 🟢/🟡/🔴 [label]
2. Progress: [N]%
3. What happened this week:
   • [ticket + what happened]
   • [ticket + what happened]
4. Plan for next week:
   • [ticket + target]
   • [ticket + target]

[Repeat for all 5 BETs: QR-1624, QR-1612, QR-1614, QR-1631, QR-1658]

────────────────────────────────────────
SECTION 3 — BLOCKED
────────────────────────────────────────
[If none: NA]

[If blocked:]
🔴 [Ticket] — [Summary] ([Owner])
Blocked on: [specific dependency]
Action: [what is being done + timeline]
Risk: [what happens if not resolved]

────────────────────────────────────────
SECTION 4 — AI SIGNAL
────────────────────────────────────────
AGENTIC WORKFLOW THIS WEEK:
[Description of the most significant agentic workflow Ankur ran or shipped this week.
Format: what it does, how many components, validated on which ticket, outcome measured.]

META-REPOSITORY UPDATE:
[What was added/changed in CoS repo, team meta-repo, skills, memory files this week]

CoS setup
[Current CoS state — what's live, what's new]

INFRASTRUCTURE RUNNING (cron jobs, no human trigger):
• Daily 9:30 AM IST — standup brief (Jira + Gmail + Calendar → Asana task)
• Monday 12:00 noon — 8-week GitHub performance PDF → Asana attachment
• Monday 11:55 AM — Salesforce Audit Trail + Deployment Status screenshots (Playwright headless)
• Every 4 hours Mon–Fri — TDD watcher (grooming queue → TDD generation → Jira attachment)
[Add any new cron jobs that came live this week]

AI MATURITY — TEAM SIGNAL:
TEAM AI USAGE THIS WEEK
• [Engineer]: [specific AI usage — what they delegated, what outcome, what they had to fix]
• [Engineer]: [specific AI usage]
[Include all engineers who had notable AI usage. Skip those with no signal.]

TEAM AI MATURITY — CURRENT SIGNALS:
• L[N]–[N] ([Stage labels]): [Names]
• L[N] ([Stage label]): [Names]
• L[N] ([Stage label]): [Names]
Full [N]-engineer maturity baseline assessment targeting [date].

---
_5/15 draft created in Asana: [task name] · [date]_
```

---

## Status emoji rules

- 🟢 On Track — delivery proceeding as planned, no escalation needed
- 🟡 Watch — risk present, EM monitoring, may need escalation
- 🔴 At Risk — blocked or behind, escalation active or needed

## Progress % rules

- Based on GRO targets in the BET ticket, not just tickets closed
- QR-1624: measured against Margin Control feature scope
- QR-1612: measured against storage/field/automation cleanup targets
- QR-1614: measured against chatbot API coverage
- QR-1631: measured against Phase 1 deliverables (Apr–May 2026)
- QR-1658: measured against SF-side done + UAT status

---

## Partial variants

- `"just my 5/15"` → run Steps 1, 2 only. Output Section 1 + Section 2 Self only. No BET section.
- `"just BETs"` → run Step 3 only. Output BET Progress Report only.
- `"5/15 AI section"` → run Steps 1, 2, 3. Output Section 4 only, pre-populated with this week's data.
- `"quick 5/15"` → run all steps, truncate each BET to 2 bullets max, no Asana task created.

---

## Skill constants

- Ankur's Asana GID: 1211542692184092
- Asana workspace GID: 8437193015852
- Jira cloud ID: d22269b5-12fa-4277-9276-734d96c6467d
- GitHub org: sox-inscope, salesforce (enterprise: github.groupondev.com)
- GitHub handle: agoyal
- Active BETs: QR-1624, QR-1612, QR-1614, QR-1631, QR-1658
- AI workstream tickets to always surface: SFDC-10243, SFDC-10242, SFDC-10221, GSOIT-6400, GSOIT-6429
- Sprint cadence: SFDC + GSOIT both 2-week sprints starting Apr 23
- 5/15 due: every Thursday EOD IST

## KPI baselines (last submitted — Apr 24, 2026)

| KPI | Value |
|-----|-------|
| AI ROI % | 99.3 |
| Review Coverage % | 71.9 |
| Estimation Adherence % | 73.8 |
| Bugs : Feature | 2.6 |
| Rework Rate % | 3.1 |
| MTTV | 6.6 |
| Jira Linkage % | 87.5 |
| Time Tracking % | 97.9 |

Use these as "Last Week" values when generating next week's report.

## Changelog

- v1.0 (Apr 24, 2026): Initial skill created from submitted 5/15 format.
  Format based on: "Updating the format as per new guidelines" header.
  Sections: KPIs → Delivered (Self + BET Progress) → Blocked → AI Signal.
  BETs: QR-1624, QR-1612, QR-1614, QR-1631, QR-1658.
