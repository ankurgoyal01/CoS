---
name: standup-brief
description: >
  On-demand standup brief and team status analysis for Ankur Goyal's SFDC engineering team.
  Pulls live data from Jira (SFDC sprint), Asana, Google Calendar, and Gmail unread emails,
  then surfaces blockers, overdue items, urgent emails, and follow-ups in a structured report.

  Use this skill whenever the user asks for any of the following — even casually or partially:
  - "give me the standup brief", "morning brief", "run the standup", "team standup"
  - "what's the team working on", "team status", "team update", "what's happening with the team"
  - "show me the Jira blockers", "any blockers today", "what's blocked"
  - "check my unread emails", "email triage", "what needs my attention in email"
  - "what's [team member] working on", "show me [name]'s status"
  - "anything I need to follow up on", "what needs my attention today"
  - "full standup", "quick standup", "partial standup"
  - Any combination of the above, e.g. "just email and calendar" or "Jira only"
---

# On-Demand Standup Brief

You are generating a live standup brief for Ankur Goyal (agoyal@groupon.com) covering his SFDC engineering team. This skill is flexible — the user may want the full brief or just specific sections. Read their request carefully and scope the analysis accordingly.

## Step 0 — Determine Scope

Before gathering data, parse the user's request to determine which sections to run:

| User asks for… | Sections to include |
|---|---|
| "full brief" / "standup brief" / no qualifier | ALL sections |
| "Jira" / "blockers" / "sprint status" | Jira only |
| "Asana" / "tasks" / "to-dos" | Asana only |
| "calendar" / "meetings today" | Calendar only |
| "email" / "inbox" / "unread" / "follow-ups" | Email only |
| "just [name]" / "[name]'s status" | All sections, filtered to that person |
| Mixed e.g. "email and Jira" | Those two sections only |

When in doubt, run the full brief — it's better to give more than less.

---

## Step 1 — Identify the Team (skip if only Calendar or Email requested)

Use `searchJiraIssuesUsingJql` with:
```
project = SFDC AND sprint in openSprints()
```
Collect all unique assignees. These are the team members. Always include Ankur himself.

If the user asked for a specific person only, filter all subsequent steps to just that person.

**Known team** (use as fallback if Jira is unavailable):
- Ankur Goyal — agoyal@groupon.com
- Amit Patil — amipatil@groupon.com
- Ashwinkrishna M — akrishnam@groupon.com
- Kumar Ankit — kankit@groupon.com
- Nirajkumar Shelke — nshelke@groupon.com
- Niveditha Ramegowda — niver@groupon.com
- Srilakshmi K S — sriks@groupon.com
- Utkarsh Pathak — upathak@groupon.com

---

## Step 2 — Gather Data (run all applicable sections in parallel)

### Jira (SFDC sprint)
For each person in scope:
- Fetch their issues from the current SFDC open sprint
- Flag: **BLOCKED** status, overdue due dates, no update in 2+ days, stuck in same status for 2+ days
- Note issue key, summary, status, priority

### Asana
Search tasks in the main SFDC-related Asana projects (SPL-SF Requests, Technical Debt, Customer Support AI Agent). For each person in scope:
- Find incomplete tasks assigned to them
- Flag: overdue (due_on < today), due today, no recent activity (modified > 3 days ago), high priority stalled

### Calendar (Ankur only)
Use `gcal_list_events` for today (full day range, condenseEventDetails=false):
- List all meetings with times and attendees
- Flag: overlapping meetings, back-to-back blocks with no buffer, meetings with no agenda/description, meetings with no-agenda from external parties

### Email (Ankur only)
Use `gmail_search_messages` in parallel:
- Query 1: `is:unread in:inbox` (limit 30)
- Query 2: `is:unread in:inbox is:important` (limit 20)

For each unique email, use `gmail_read_message` to read subject, sender, and body. Classify:
- 🔴 **Urgent / Action Required** — explicit ask, deadline, escalation, approval request, external stakeholder waiting. Signals: "urgent", "ASAP", "waiting on you", "please confirm", "by EOD", "blocked on you"
- 🟡 **Follow-Up Needed** — thread where a response is overdue (no reply in 2+ days), or Ankur's team was expected to act and hasn't
- 🔵 **FYI** — newsletters, automated notifications, CC'd with no action. **Omit these from the output.**

---

## Step 3 — Compose the Brief

Use only the sections that were requested. Always lead with the most actionable information.

---

### 🗓 Today's Meetings — [Date]
*(Include only if Calendar was in scope)*

List meetings chronologically with times (user's local timezone). For each:
- Meeting name, time range, key attendees
- ⚠️ flag any overlaps, conflicts, or agenda-less external meetings

---

### 📧 Email Triage
*(Include only if Email was in scope)*

#### 🔴 Urgent — Action Required Today
- **From:** Name (email)
- **Subject:** …
- **What's needed:** One sentence
- **Urgency signal:** The specific phrase or context

*If none: "No urgent emails requiring action today."*

#### 🟡 Follow-Up Needed
- **From:** Name (email)
- **Subject:** …
- **What's needed:** One sentence

*If none: "No pending follow-ups identified."*

---

### 👥 Team Status
*(Include only if Jira or Asana was in scope)*

For each person in scope (Ankur first, then alphabetically by first name):

**[Full Name]**
- **Jira (SFDC Sprint):** Issues with status. Bold any 🚨 BLOCKED or ⚠️ flagged items.
- **Asana:** Overdue or due-today tasks. Note anything stalled.
- **Status:** One sentence — where do they stand right now?

---

### 🚨 Needs Attention

A consolidated, prioritised list of the most critical items. Include only real flags — don't pad with minor items.

Format: `[Name] — [Source] — [Item] — [Why flagged]`

Rank order:
1. Blockers (need unblocking today)
2. Overdue items
3. Urgent emails awaiting response
4. Capacity gaps (anyone with nothing assigned)
5. Calendar conflicts

---

### 📋 Today's Focus
*(Include always, even in partial briefs)*

3–5 sentences. Synthesise what Ankur should actually do first when he starts work. Reference the single highest-priority item from each active section. Be direct — don't hedge.

---

## Delivery

Output the brief **inline in the conversation** (not as a file, not as an Asana task — that's the scheduled version's job). Use clean markdown formatting. Keep it scannable — the user is reading this at the start of their day.

If the user explicitly asks to also create an Asana task, do so using `create_task_preview` with today's date and the full brief as the description, assigned to agoyal@groupon.com.

---

## Tips for Good Output

- **Be specific, not generic.** "SFDC-9808 is BLOCKED — TIN banner" is useful. "Some items need attention" is not.
- **Omit noise.** Don't list Done/Resolved Jira tickets unless the user asked. Don't list 🔵 emails. Don't mention "No data found" for every tool if it's irrelevant to the scope.
- **Surface the critical path.** If 4 things are happening, what's the one that derails the sprint if it slips? Say that.
- **Use the team member's actual first name** in the Focus section, not just their email.
