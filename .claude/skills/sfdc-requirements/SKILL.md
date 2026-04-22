---
name: sfdc-requirements
description: >
  Use this skill whenever a user supplies an Asana or Jira URL and wants to analyse business
  requirements and generate Salesforce technical design documents or Jira tickets.
  Triggers include: any mention of "Asana URL", "Jira URL", "technical design", "TDD", "Salesforce
  design", "SFDC ticket", "create Jira ticket from Asana", "requirements from Asana/Jira", or any
  request to process a task/ticket URL into documentation or Jira work items. Always use this skill
  when the user pastes a URL from Jira or Asana — even if they don't explicitly mention Salesforce
  or a design doc.
---

# SFDC Requirements → Technical Design & Jira Automation Skill

This skill processes business requirements from **Asana** or **Jira** URLs and:
1. Reads and understands the requirement
2. Generates a **Technical Design Document (.docx)** with Salesforce impact analysis
3. If the source is **Asana**, creates exactly **one Jira Task** under the `SFDC` project
4. Moves the ticket to the **"Ready for Grooming/Estimation"** sprint

---

## Configuration (Pre-set for Groupon)

| Setting | Value |
|---|---|
| Jira Instance | `https://groupondev.atlassian.net` |
| Jira Project Key | `SFDC` |
| Jira User Email | `agoyal@groupon.com` |
| Sprint Name | `Ready for Grooming/Estimation` |
| Ticket Type | `Task` |
| Doc Format | `.docx` (Word) |

> **API Key**: The user will supply their Jira API key at the start of each session.
> Store it in memory as `JIRA_API_KEY` for the duration of the conversation.

---

## Step 0 — Collect API Key (if not already provided)

If the user hasn't provided a Jira API key, ask:
> "Please share your Jira API key so I can create and move tickets. It will only be used for this session."

---

## Step 1 — Detect Source & Read Requirement

### Detect source type from URL:
- URL contains `app.asana.com` → **Asana**
- URL contains `atlassian.net` or `jira` → **Jira**

### Reading Asana task:
Use the connected **Asana MCP** tool to fetch the task. Extract:
- Task name / title
- Description / notes
- Subtasks (if any)
- Attachments or linked documents
- Assignee, due date, tags

### Reading Jira ticket:
Use the **Jira REST API** (see `references/jira-integration.md`) to fetch the issue. Extract:
- Summary
- Description
- Issue type, priority
- Linked issues
- Acceptance criteria (if in description or custom fields)

---

## Step 1.5 — Fetch Org Context Documents

**Before writing the TDD**, read `references/org-context.md` for full details, then fetch both org context resources described there. These documents tell you what already exists in the Groupon Salesforce org — existing automations, naming conventions, and the overall architecture — so the design you produce fits in cleanly rather than duplicating or conflicting with live automation.

Fetch both in parallel using **Claude in Chrome**:

1. **Salesforce Sales Cloud Automations doc** — navigate to the Google Doc URL in `org-context.md` and extract the text with `get_page_text`
2. **Architecture diagram** — navigate to the diagrams.net URL in `org-context.md`, wait for it to fully render, then capture labels and structure with `read_page` or `get_page_text`

If either resource is inaccessible (sign-in wall, Chrome unavailable, etc.), follow the **Fallback Behaviour** section in `org-context.md` — add a warning block to the TDD and an Open Question, then continue with all other sections.

Keep the extracted content in memory; you'll reference it throughout Step 2.

---

## Step 2 — Generate Technical Design Document

Read `references/tdd-template.md` for the full document structure.

Use the **docx skill** to produce a `.docx` file. Key sections:
- Business Requirements Summary
- Salesforce Impact Analysis (Objects/Fields, Flows, Apex, Permissions, **Alignment with Org Automation Standards**)
- Implementation Approach
- Risks & Assumptions
- Acceptance Criteria

For Salesforce impact analysis, read `references/salesforce-impact.md` for detailed checklists.

Throughout the analysis, actively use the org context fetched in Step 1.5:
- Call out any **existing automations** (from the Sales Cloud Automations doc) that overlap with the proposed work
- Reference specific elements of the **architecture diagram** — objects, integrations, or system boundaries — when they are relevant to the design
- Follow **naming conventions** observed in the automation doc when naming new components

Save the file as: `TDD_<sanitized-title>_<YYYY-MM-DD>.docx`
Present it to the user via `present_files`.

---

## Step 3 — Create Jira Ticket (Asana source only)

**Only run this step if the source was Asana.**

Always create exactly **one (1) Jira Task** per Asana task — no more, no less. Consolidate all technical work (Apex, Flow, Permissions, etc.) into a single ticket, using the description sections to call out each component clearly.

Use the Jira REST API (see `references/jira-integration.md`) to create a Task with:
- **Summary**: Clear, action-oriented title
- **Description**: Structured with sections — Background, Implementation Details, Technical Notes
- **Acceptance Criteria**: As a checklist in the description
- **Project**: `SFDC`
- **Issue Type**: `Task`
- **Labels**: `sfdc-auto-generated`
- **Assignee**: `agoyal@groupon.com` (Ankur Goyal) — always set this, no exceptions
- **Epic Link**: `SFDC-9644` — always link the ticket to this parent Epic

After creation, collect the issue key (e.g., `SFDC-123`).

---

## Step 4 — Attach TDD to Jira Ticket

After creating the Jira ticket, attach the generated `.docx` TDD file to it.

See `references/jira-integration.md` → "Attaching a File to an Issue" section for the exact API call.

- The attachment should appear in the Jira ticket's "Attachments" panel so the team can open it directly during grooming

---

## Step 5 — Move Ticket to Sprint

After attaching the TDD, move the ticket to the **"Ready for Grooming/Estimation"** sprint.

See `references/jira-integration.md` → "Moving Issues to a Sprint" section for the exact API calls needed.

---

## Step 6 — Summary to User

Present a clean summary:
```
✅ Technical Design Document: [filename]

📋 Jira Ticket Created:
  - SFDC-123: <title> → https://groupondev.atlassian.net/browse/SFDC-123
    Assigned to: Ankur Goyal | Epic: SFDC-9644

📎 TDD attached to ticket

🏃 Sprint: Ticket moved to "Ready for Grooming/Estimation"
```

If the source was Jira (not Asana), skip the ticket creation and attachment summary.

---

## Error Handling

- **Asana task not found**: Ask user to check the URL or Asana permissions
- **Jira API 401**: Ask user to re-confirm their API key and email
- **Jira API 404 on project**: Confirm `SFDC` project key is correct
- **Sprint not found**: List available sprints using the sprint search API and ask user to confirm
- **docx generation fails**: Fall back to generating the TDD as Markdown in-chat and offer to retry the file

---

## Reference Files

| File | When to Read |
|---|---|
| `references/org-context.md` | At the start of Step 1.5 — before fetching the external org documents |
| `references/tdd-template.md` | Before generating the design document (Step 2) |
| `references/salesforce-impact.md` | For Salesforce impact analysis sections |
| `references/jira-integration.md` | Before any Jira API call (Steps 3 & 4) |
