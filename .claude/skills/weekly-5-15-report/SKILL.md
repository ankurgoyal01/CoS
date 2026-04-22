---
name: weekly-5-15-report
description: >
  Generate Ankur Goyal's weekly 5/15 status report for his manager, covering the
  SFDC and GSOIT teams. Pulls live data from Jira (SFDC + GSOIT), Asana (projects
  + status updates), Gmail (this week), and Google Calendar (this week), then
  composes the report in Ankur's standard 5-section 5/15 format and creates a
  new Asana task with the report as its notes so Ankur can review and later move
  it under the parent "5/15 - Ankur Goyal" task.

  Use this skill whenever the user asks for any of the following — even casually:
  - "generate my 5/15", "run the 5/15", "weekly 5/15", "friday 5/15"
  - "prepare my weekly status report", "manager weekly update", "weekly report"
  - "what should I report this week", "draft this week's 5/15"
  - Any combination referencing the 5/15 format, the weekly report to manager,
    or the Asana parent task "5/15 - Ankur Goyal".
---

# Weekly 5/15 Report — Ankur Goyal

You are generating Ankur Goyal's weekly 5/15 status report for his manager
(Josef Sima, with Ales Drabek often a follower). Ankur leads the SFDC
engineering team and also drives GSOIT (Bloomreach migration, Encore, Bird,
Twilio, etc.). The report is delivered as an Asana task with notes in the
format Ankur has used for months.

**Key facts (hardcoded):**
- Ankur's Asana user GID: `1211542692184092`
- Ankur's email: `agoyal@groupon.com`
- Parent task "5/15 - Ankur Goyal" GID: `1209669788519378`
- Target audience: Ankur's direct manager (Josef Sima) and Ales Drabek
- Report cadence: Weekly, due Fridays
- Jira Cloud: `groupondev.atlassian.net`
- Jira projects in scope: `SFDC`, `GSOIT`, `QR` (portfolio/epic project used for SFDC + GSOIT initiatives)
- Asana workspace: `groupon.com` (GID `8437193015852`)

---

## Step 0 — Determine the Report Date

Compute **this Friday's date** in `YYYY-MM-DD` format:
- If today is Friday, use today.
- If today is Sat–Thu, use the upcoming Friday (or the most recent Friday if
  the skill is run on a weekend after a missed run — use judgment).

Use that date as `REPORT_DATE`. The week covered is Saturday through Friday
ending on `REPORT_DATE` (i.e., the 7 days ending at `REPORT_DATE`).

Use `bash` + `date` if precise date math is needed.

---

## Step 1 — Load the Previous Report (carry-forward projects)

Fetch the most recent 5/15 subtask under parent `1209669788519378`:

1. Call `get_task` on task `1209669788519378` (the parent) — but that won't
   return its subtasks directly. Instead use Asana search:
   ```
   search_tasks_preview with text="5/15 - Ankur Goyal", assignee_any="me",
     completed=false (or both)
   ```
   OR query the parent's subtasks via `get_task` with `include_subtasks=true`.

2. Pick the most recently-dated subtask whose name matches
   `5/15 - Ankur Goyal - YYYY-MM-DD`. Read its `notes` field.

3. Parse out from the previous report's notes:
   - Every Asana task/project URL referenced under section 1
   - Every Jira key referenced (regex `(QR|SFDC|GSOIT)-\d+`)
   - Each project block's status color, progress %, and "Plan for next week"
     bullets (these become the starting point for what *should* have happened
     this week)

Store this as `CARRY_FORWARD_PROJECTS` — a list of project blocks Ankur was
actively reporting on last week. They remain in this week's report unless
clearly closed (100% + no further updates).

---

## Step 2 — Gather This Week's Data (run in parallel)

Run the following data fetches in parallel. The "this week" window is the
7 days ending on `REPORT_DATE`.

### A) Jira — SFDC, GSOIT, QR activity

Use `searchJiraIssuesUsingJql` with the Groupon cloudId:

1. **Epics/initiatives Ankur drives** — carry-forward Jira keys from Step 1:
   ```
   key in (QR-1460, QR-1421, QR-1614, QR-1588, QR-1595, SFDC-10062, …) 
   ```
   (Use the actual keys from the previous report.) Fetch with fields:
   `summary,status,assignee,priority,updated,customfield_10004` (epic progress
   if present), plus `comment` so you can see what happened this week.

2. **New activity this week in SFDC/GSOIT**:
   ```
   project in (SFDC, GSOIT, QR) AND updated >= -7d AND 
   (assignee = currentUser() OR reporter = currentUser() OR 
    watcher = currentUser() OR "Epic Link" in (…carry-forward epics…))
   ```
   Look for:
   - Issues moved to **Done / Closed / Resolved** this week → feed into
     "What happened this week"
   - Issues with status **In Progress** under a carry-forward epic → feed into
     ongoing projects
   - Any **Blocked** issues → feed into "What was planned and wasn't done"
   - High-priority items (P1/Critical) — always surface

3. **For each carry-forward epic**, compute a rough progress signal:
   `(# Done child issues) / (# total child issues) * 100` → informs the
   progress % bullet.

### B) Asana — projects & status updates

1. For each carry-forward Asana task URL, call `get_task` with
   `include_comments=true` to read the latest comments / status discussion.

2. For portfolios Ankur follows, use `get_portfolios` then
   `get_items_for_portfolio` to identify all active SFDC/GSOIT projects.

3. For each active project, call `get_status_overview` with the project
   keyword to pull the latest `project_status_update` posted this week (green/
   yellow/red, title, body).

4. Also call `get_my_tasks` with `completed_since="now"` to see Ankur's own
   open tasks — useful for "Plan for next week".

### C) Gmail — this week's project-relevant email

Run these `gmail_search_messages` queries in parallel (maxResults=25 each):

- `newer_than:7d is:important` — likely containing manager/Ales messages
- `newer_than:7d from:(-noreply)` — inbound that may include decisions,
  escalations, demos, UAT feedback
- `newer_than:7d subject:(UAT OR demo OR launch OR rollout OR Bloomreach OR 
  "5/15" OR Salesforce OR GSOIT)` — topical signal

For each thread that looks project-relevant, call `gmail_read_thread` to
extract: sender, subject, short summary, any commitments Ankur made, any
asks from stakeholders. Filter out newsletters, autogenerated notifications,
and internal tool alerts.

### D) Google Calendar — this week's meetings

Call `gcal_list_events` with:
- `timeMin` = REPORT_DATE minus 6 days at 00:00 local
- `timeMax` = REPORT_DATE at 23:59 local
- `condenseEventDetails=true`
- `maxResults=100`

Focus on:
- Business demos, UAT reviews, launch calls, steer-co/BET reviews
- Syncs with named stakeholders: Preethi, Keith H, Michal, Ales, Josef,
  Bloomreach / MC / Bird / Twilio / Finance teams
- Any meeting whose title matches a carry-forward project

Attribute decisions/outcomes from these meetings to the relevant project
block ("had alignment with Keith on…", "business demo completed Wed").

---

## Step 3 — Compose the Report

Use **this exact 5-section template** and Ankur's writing style. Match the
tone, status emojis, and structure from his sample reports. Plain text in
the Asana task notes — no markdown headers, no bullets beyond his natural
indentation style.

Status emojis used by Ankur:
- 🟢 on track / completed
- 🟠 at risk
- 🔴 off track / blocked

Progress is expressed as `Progress : NN%`.

### Template

```
1) What happened this week?

    [LEAD PARAGRAPH — 1–3 sentences summarising the overarching theme of the
     week. Usually calls out the biggest initiative (e.g., Bloomreach setup,
     AI chatbot rollout, Q2 planning). Match Ankur's style — he leads with
     a high-level sentence then indents supporting bullets.]

    [Cross-cutting theme 1 — e.g., Bloomreach deep dive:]
        [sub-bullet 1]
        [sub-bullet 2]

    [Cross-cutting theme 2 — e.g., AI chatbot progress:]
        [sub-bullet]
        [sub-bullet]

[For EACH carry-forward project AND any new project with material activity
 this week, render a block in this exact shape:]

[Full Asana task URL]
    Status : 🟢 (or 🟠 / 🔴)
    Progress : NN%
    Jira: https://groupondev.atlassian.net/browse/<KEY>
    What happened this week:
        [bullet 1 — concrete outcome, include Jira sub-keys where relevant]
        [bullet 2]
    Plan for next week:
        [bullet 1 — derived from Jira "In Progress" + Asana open tasks]
        [bullet 2]

 2) What was planned and wasn't done?

    [List items from LAST week's "Plan for next week" that did NOT happen
     this week. Be honest — pull from Jira tickets that slipped or weren't
     completed. If nothing slipped, say "All planned items delivered." but
     only if that's actually true.]

3) What are the key priorities for next week (3-5 tasks)?

    [3–5 concrete priorities. Pull from:
     - Each project block's "Plan for next week" bullets (consolidated)
     - Known upcoming milestones (launches, demos, UAT dates) from calendar
     - Q2 planning / BET work
     - Ongoing SFDC-9644 / SFDC-9645 if still active]

4) Top achievement/breakthrough (include best use of AI if nothing else)

    [Lead with the single biggest achievement. Then follow with an "AI usage"
     sub-section — Ankur always includes AI wins. Reference:
     - Salesforce MCP usage
     - Salesforce bot / SF chatbot rollout progress
     - Claude Code + Cowork automations (standup brief, this 5/15 skill, etc.)
     - Any new AI experiment this week]

5) Suggestions and improvement ideas (include AI opportunity if nothing else)

    [1–3 forward-looking ideas — process improvements, AI opportunities,
     tooling suggestions. Keep brief; this section is often short in his
     samples.]
```

### Style notes (critical — match Ankur's voice)

- Indentation matters: Ankur uses 4-space indentation within a project block,
  8-space for sub-bullets under "What happened this week".
- Jira URLs always appear as full `https://groupondev.atlassian.net/browse/<KEY>`.
- Asana task URLs appear as full `https://app.asana.com/...?focus=true` links,
  not as the shorter `app.asana.com/0/…` form when possible.
- He often writes "Plan for next week" even if that week's block is 100% done
  (for closing/handover tasks), but can omit it if truly closed.
- He includes Google Docs links, Google Chat room links, and cross-references
  between Asana tasks — preserve all such links from the previous report
  unless they're clearly stale.
- He will sometimes include a status transition note like "🟢 🟠 (moved to
  green now)" to signal recovery — preserve that pattern when applicable.
- Do not invent achievements or numbers. If the data doesn't support a claim
  from the previous report, leave the corresponding bullet out.

---

## Step 4 — Create the Asana Task

Create a **new Asana task** (NOT a subtask of the parent yet — Ankur will
move it himself after review):

- **name**: `5/15 - Ankur Goyal - <REPORT_DATE>`  (e.g. `5/15 - Ankur Goyal - 2026-04-24`)
- **assignee**: `me` (Ankur's GID: `1211542692184092`)
- **due_on**: `REPORT_DATE`
- **notes**: the composed report from Step 3 (plain text — Asana renders URLs
  as links automatically)
- **followers**: include Josef Sima (`1211542696692321`) and Ales Drabek
  (`1210132382629153`) — matching the pattern in prior reports
- **workspace**: `8437193015852`

Use `create_tasks` (not `create_task_preview`) — Ankur wants this created
directly so he can review in Asana and decide when to move it under the
parent 5/15 task.

After creation, return to the user (or chat log if scheduled):
- The Asana task permalink URL
- A 4–6 line summary of what the report covered (counts: # projects, # Jira
  tickets closed this week, # meetings attended, # emails triaged)
- A note: "Review in Asana, then move under parent task '5/15 - Ankur Goyal'
  when ready."

---

## Step 5 — Fail-soft handling

If any data source is unavailable (Jira timing out, Gmail auth error, etc.):
- Proceed with what you have.
- In section 2 ("What wasn't done?"), add a one-liner noting which source
  was unavailable so Ankur knows to manually fill that gap.
- Never block the report on a single source failure.

If there are zero new activity signals (e.g., Ankur was on PTO), produce a
short report that says so plainly in section 1, carry forward unchanged
project statuses, and set section 3 to "resume planned work from previous
week" referencing the carry-forward plan bullets.

---

## Tips for good output

- **Be specific.** "Cases API completed QA (GSOIT-6283)" beats "progress made
  on Cases API".
- **Match the density** of Ankur's samples — each project block is 4–8 lines,
  not a paragraph.
- **Preserve continuity.** This is a weekly report; the manager is reading
  the same project names week after week. Using the same project titles and
  links as prior weeks is a feature, not repetition.
- **AI section always gets content.** If no big AI win this week, mention
  the automations already in production (standup brief, SF chatbot, MCP).
