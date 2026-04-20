# DRI Bet Update — Plugin Setup Guide

Generates bi-weekly (or sprint-cadence) iteration reports for any Groupon PM bet.
Produces a GROW² plan for the next sprint and a Retrospective for the completed one,
then posts both to Asana and saves an HTML report locally.

The `giq-report` skill is a pre-configured instance of this plugin for the GIQ bet.
To create a new instance for a different bet, copy that skill and replace the BET CONFIG block.

---

## Required MCP Connections

All three must be active in your Claude Code session before invoking the skill.
Check Settings → MCP Servers or run `/mcp` to verify.

| MCP | Tool prefix | What it does |
|---|---|---|
| **Asana** | `mcp__claude_ai_Asana__*` | Reads meeting notes, 5/15s, and roadmap; writes GROW²/Retro tasks |
| **Atlassian (Jira)** | `mcp__claude_ai_Atlassian_Rovo__*` | Searches resolved/in-progress tickets; reads metric baseline ticket |
| **Echelon** | Direct curl to `octopus-app-zcwpc.ondigitalocean.app` | Pulls Tempo worklogs for all team members |

> **Echelon is not an MCP** — it is called via `curl` in a Bash tool call. No MCP setup needed, but the endpoint must be reachable from the machine running Claude Code.

---

## Asana Data Sources

For each entry, you need the **GID** (numeric ID in the Asana URL: `app.asana.com/0/{GID}/...`).

### 1. Iteration Reports Project (required)

The Asana project where GROW² and Retrospective tasks will be posted.

- Config key: `asana_iteration_project`
- Must have at least two sections named **"Doing"** and **"Planned"** (the roadmap subagent reads these)
- The skill will create a new parent task and two subtasks per iteration run

How to find it: open the project in Asana → copy the number from the URL.

### 2. Meeting Notes Parent Tasks (required for Key Learnings)

One or more recurring parent tasks whose subtasks are dated meeting notes.

- Config key: `asana_meeting_tasks` (list of `{gid, label}`)
- Each subtask should be named `"[Meeting Title] — YYYY-MM-DD"` (the skill parses the date from the name)
- All subtasks in these parent tasks are treated as bet-related — no title filtering

How to find it: open the parent meeting-notes task → copy the GID from the URL.

### 3. 5/15 Parent Tasks (required for Key Learnings)

One entry per person on the bet team. Each person has a recurring parent task whose subtasks are weekly 5/15 submissions.

- Config key: `asana_515_tasks` (list of `{name, gid}`)
- Subtask naming convention expected: `"5/15 - Name - YYYY-MM-DD"`
- The skill picks the subtask dated closest to and no earlier than `end_date` (within 7 days)

How to find it: navigate to a person's 5/15 parent task → copy GID from the URL.

### 4. Additional Sources (optional)

Extra Asana project sections whose tasks should be pulled as completed/in-progress items alongside Jira tickets. Useful when a stream tracks work in Asana rather than Jira.

- Config key: `asana_additional_sources` (list of `{project, section, stream, label}`)
- Completed tasks (within date range) appear in Iteration Results
- Incomplete tasks appear in In-Progress

### 5. Additional 5/15s (optional)

5/15 tasks from people outside the core bet team (e.g. a Sales Rollout PM).

- Config key: `asana_additional_515s` (list of `{name, gid, filter_for}`)
- `filter_for`: comma-separated keywords; only content mentioning these keywords is extracted

---

## Jira Data Sources

### 1. Jira Cloud ID (required)

The cloud instance ID for your Groupon Jira.

- Config key: `jira_cloud_id`
- Current value (same for all Groupon bets): `d22269b5-12fa-4277-9276-734d96c6467d`
- How to find it: Settings → Atlassian MCP → cloud ID, or ask an Atlassian admin

### 2. Jira Projects (required)

The Jira project keys that track delivery work for this bet.

- Config key: `jira_projects` (list of `{key}` or `{key, parent_epic}`)
- Without `parent_epic`: all resolved/in-progress tickets in the project are pulled
- With `parent_epic`: scope is restricted to children of that epic only (use when the project is shared across bets)

How to find it: the two- to four-letter prefix on every ticket (e.g. `MCE`, `ENC`).

### 3. Metric Baseline Ticket (required for Results section)

A single Jira ticket whose description holds the bet's GRO/metric targets, kill-gate thresholds, and milestone dates.

- Config key: `jira_metric_baseline_ticket`
- Format: `"QR-XXXX"` or any valid ticket key
- The skill reads the description field and extracts targets and thresholds

### 4. Team Member Jira Account IDs (required for Tempo)

Every person whose time should be counted needs a Jira account ID.

- Config keys: `team.product[].jira_account_id` and `team.engineering[].jira_account_id`
- Format: `"712020:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"`
- How to find it: in Jira, open a user profile → the account ID is in the URL (`/jira/people/{accountId}`)
  or call the Atlassian REST API: `GET /rest/api/3/user?query={email}`

---

## Echelon / Tempo

Tempo worklogs are fetched via the Echelon internal API. No configuration needed beyond having the correct Jira account IDs in the team config (see above).

The skill filters worklogs to bet-scoped issues only:
- Time logged on issues in the configured Jira projects counts
- Time on issues listed in `tempo_giq_issue_overrides` always counts (use for cross-project tickets)
- Time on all other issues is excluded

To add a cross-project issue override:
```yaml
tempo_giq_issue_overrides:
  - id: 5010744         # numeric Jira issue ID (not the key)
    note: "Description of why this is included"
```

How to find a numeric issue ID: open the ticket in Jira → view page source → search for `"id"`.
Or call: `GET /rest/api/3/issue/{issueKey}?fields=id`

---

## Setup

1. Copy `.claude/skills/DRI_Bet_Update/` into your CoS workspace
2. Run `/DRI_Bet_Update` in Claude Code
3. The wizard will ask for each value and write your configured skill

Before running the wizard, make sure your MCP connections are active (see Required MCP Connections above) — you'll need them to look up GIDs and account IDs as the wizard asks for them.

---

## Creating a New Bet Instance

1. Copy `.claude/skills/DRI_Bet_Update/` into your CoS workspace
2. Run `/DRI_Bet_Update` — the wizard starts automatically
3. Answer each question; the wizard suggests values where it can
4. Confirm the summary → your new skill is written to `.claude/skills/{your-slug}/`
5. Invoke with `/{your-slug} [start_date] [end_date] [iteration_name]`
