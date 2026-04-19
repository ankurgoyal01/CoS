---
service: "tdo-team"
title: "GPROD Subtask and Immediate Action Reminders"
generated: "2026-03-03"
type: flow
flow_name: "subtask-and-ia-reminders"
flow_type: scheduled
trigger: "Kubernetes CronJob — daily at 08:00 UTC"
participants:
  - "continuumTdoTeamSubtaskRemindersJob"
architecture_ref: "tdo-team-containers"
---

# GPROD Subtask and Immediate Action Reminders

## Summary

This flow runs daily at 08:00 UTC and sends Jira comment reminders to owners of GPROD subtasks and Immediate Action tickets that are approaching their due dates. Three separate Jira filters capture tickets at 30-, 10-, and 3-day thresholds before the due date. For each ticket found, the script resolves the service name and owner via the Service Portal, then posts a due-date reminder comment in the Jira ticket tagging the service owner.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`continuumTdoTeamSubtaskRemindersJob`)
- **Frequency**: Daily at 08:00 UTC (`0 8 * * *`)
- **Invocation**: `./cronjobs/gprod-subtask-and-IA-reminders.sh` (Bash shell script)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subtask Reminders CronJob | Schedule trigger; executes the Bash script | `continuumTdoTeamSubtaskRemindersJob` |
| Jira REST API v2 | Source of subtask/IA ticket data; target for reminder comments | - |
| Service Portal | Resolves service owner name from service name | - |

## Steps

1. **Iterate over three SLA thresholds (30, 10, 3 days)**: The script processes Jira filters for 30-day (`44615`), 10-day (`44645`), and 3-day (`44644`) thresholds in sequence.
   - From: Subtask Reminders CronJob (Bash shell)
   - To: (internal loop over `SLAS` array)
   - Protocol: local

2. **Fetch Jira filter search URL**: For each filter ID, the script calls `GET /rest/api/2/filter/{id}` to retrieve the filter's `searchUrl`.
   - From: Subtask Reminders CronJob
   - To: Jira REST API (`https://groupondev.atlassian.net/rest/api/2/filter/{id}`)
   - Protocol: REST (HTTPS, Basic Auth)

3. **Execute Jira filter search**: The script calls the `searchUrl` with `maxResults=-1` to retrieve all matching ticket keys and their service name (`customfield_18801`).
   - From: Subtask Reminders CronJob
   - To: Jira REST API (search URL)
   - Protocol: REST (HTTPS, Basic Auth)

4. **Resolve service name (if missing)**: If a ticket has no service name (`MISSING`), the script walks linked tickets and parent tickets to find a linked GPROD Incident, then reads its service name field.
   - From: Subtask Reminders CronJob
   - To: Jira REST API (`GET /rest/api/2/issue/{key}`)
   - Protocol: REST (HTTPS, Basic Auth)

5. **Resolve service owner from Service Portal**: The script calls `GET /api/v2/services/{serviceName}` using `GRPN-Client-ID: tdo-coea-automation` to get the owner's name.
   - From: Subtask Reminders CronJob
   - To: Service Portal (`$SP_URL/api/v2/services/{name}`)
   - Protocol: REST (HTTP)

6. **Resolve owner's Jira account ID**: The script queries `GET /rest/api/2/user/search?query={ownerEmail}` to get the owner's Jira account ID for use in the `@mention` comment.
   - From: Subtask Reminders CronJob
   - To: Jira REST API
   - Protocol: REST (HTTPS, Basic Auth)

7. **Post due-date reminder comment**: The script calls `POST /rest/api/2/issue/{key}/comment` with a message stating the number of days remaining (3, 10, or 30) before the service moves to ORR red, and tags the service owner's account ID.
   - From: Subtask Reminders CronJob
   - To: Jira REST API
   - Protocol: REST (HTTPS, Basic Auth)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira filter returns no tickets | Loop body skipped | Script logs "no N days results" and moves to next threshold |
| Ticket has no service name and no linked GPROD incident | Posts generic "SERVICE NAME EMPTY" comment | Ticket is commented; team member must manually update service name |
| Service Portal returns null owner | Comment is not posted; script skips to next ticket | Ticket receives no reminder; requires manual follow-up |
| Jira comment POST returns non-201 | Script logs "ERROR ADDING COMMENT" | Comment not added; no retry |

## Sequence Diagram

```
CronJob -> Jira REST API: GET /rest/api/2/filter/44615 (30 days)
Jira REST API --> CronJob: searchUrl
CronJob -> Jira REST API: GET searchUrl&maxResults=-1
Jira REST API --> CronJob: list of tickets with service names
CronJob -> Jira REST API: GET /rest/api/2/issue/{key} (if service name missing)
CronJob -> Service Portal: GET /api/v2/services/{serviceName}
Service Portal --> CronJob: owner name
CronJob -> Jira REST API: GET /rest/api/2/user/search?query={ownerEmail}
Jira REST API --> CronJob: accountId
CronJob -> Jira REST API: POST /rest/api/2/issue/{key}/comment (30-day reminder)
CronJob -> Jira REST API: GET /rest/api/2/filter/44645 (10 days)
... (repeat for 10-day and 3-day thresholds)
```

## Related

- Architecture container view: `tdo-team-containers`
- Related flows: [Advisory Actions Reminders](advisory-actions-reminders.md), [Close Old Logbooks](close-old-logbooks.md)
- Integration details: [Integrations](../integrations.md)
