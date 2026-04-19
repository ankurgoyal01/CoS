---
service: "tdo-team"
title: "Close Old GPROD Logbooks"
generated: "2026-03-03"
type: flow
flow_name: "close-old-logbooks"
flow_type: scheduled
trigger: "Kubernetes CronJob — daily at 08:00 UTC"
participants:
  - "continuumTdoTeamCloseLogbooksJob"
architecture_ref: "tdo-team-containers"
---

# Close Old GPROD Logbooks

## Summary

This flow runs daily at 08:00 UTC and automatically closes GPROD logbook tickets that have been open for more than 10 days past their planned start date. For each qualifying ticket, the script retrieves the service owner from Service Portal, posts an explanatory comment, and transitions the ticket to Done using Jira's transition API. The flow assumes that if a logbook is still open after 10 days, the deployment completed successfully and the ticket was forgotten.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`continuumTdoTeamCloseLogbooksJob`)
- **Frequency**: Daily at 08:00 UTC (`0 8 * * *`)
- **Invocation**: `./cronjobs/close_old_logbooks_LOCAL.sh` (Bash shell script)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Close Logbooks CronJob | Schedule trigger; executes the Bash script | `continuumTdoTeamCloseLogbooksJob` |
| Jira REST API v2 | Source of open logbook tickets; receives comments and status transitions | - |
| Service Portal | Resolves service owner name from service name | - |

## Steps

1. **Fetch Jira filter search URL**: The script calls `GET /rest/api/2/filter/47402` to retrieve the `searchUrl` for open logbook tickets older than 7 days (threshold applied externally in the filter; script applies 10-day rule for closure).
   - From: Close Logbooks CronJob
   - To: Jira REST API (`https://groupondev.atlassian.net/rest/api/2/filter/47402`)
   - Protocol: REST (HTTPS, Basic Auth) using a dedicated Jira service account

2. **Execute search against filter**: The script calls the `searchUrl` with `maxResults=-1` to retrieve all matching logbook ticket keys and service names (`customfield_18801`).
   - From: Close Logbooks CronJob
   - To: Jira REST API (search URL)
   - Protocol: REST (HTTPS, Basic Auth)

3. **Resolve service owner from Service Portal**: For each ticket, the script calls `GET /api/v2/services/{serviceName}` to retrieve the owner's name.
   - From: Close Logbooks CronJob
   - To: Service Portal (`$SP_URL/api/v2/services/{name}`)
   - Protocol: REST (HTTP, `GRPN-Client-ID: tdo-coea-automation` header)

4. **Resolve service owner's Jira account ID**: The script queries `GET /rest/api/2/user/search?query={ownerName}` to get the owner's Jira account ID for use in the comment mention.
   - From: Close Logbooks CronJob
   - To: Jira REST API
   - Protocol: REST (HTTPS, Basic Auth)

5. **Attempt ticket closure (TO DO → DONE)**: The script posts `POST /rest/api/2/issue/{key}/transitions` with transition ID `21` (TO DO → DONE) to close the ticket.
   - From: Close Logbooks CronJob
   - To: Jira REST API (`POST /rest/api/2/issue/{key}/transitions`)
   - Protocol: REST (HTTPS, Basic Auth)

6. **Fallback closure attempt (IN PROGRESS → DONE)**: If the first transition returns a non-204 response (ticket is IN PROGRESS, not TO DO), the script retries with transition ID `41` (IN PROGRESS → DONE).
   - From: Close Logbooks CronJob
   - To: Jira REST API (`POST /rest/api/2/issue/{key}/transitions`)
   - Protocol: REST (HTTPS, Basic Auth)

7. **Post closure comment**: On successful closure (204 response), the script posts a comment explaining that the logbook was automatically closed because it has been open for more than 10 days past the planned start date, and tags the service owner.
   - From: Close Logbooks CronJob
   - To: Jira REST API (`POST /rest/api/2/issue/{key}/comment`)
   - Protocol: REST (HTTPS, Basic Auth)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira filter returns no open logbooks | Script logs "no logbooks tickets open older than 10 days" | Script exits cleanly |
| Ticket cannot be transitioned (non-204 from both transition IDs) | Logs "ERROR CLOSING TICKET ... RESPONSE_CODE=..." | Ticket remains open; requires manual closure or investigation of valid transition IDs |
| Service Portal returns null owner | `srv_owner_id` is empty; comment posted without valid mention | Comment may appear without proper mention; owner not notified |
| Jira comment POST fails (non-201) | Logs "ERROR ADDING COMMENT" | Ticket closed but no comment posted |

## Sequence Diagram

```
CronJob -> Jira REST API: GET /rest/api/2/filter/47402
Jira REST API --> CronJob: searchUrl
CronJob -> Jira REST API: GET searchUrl&maxResults=-1&fields=key,customfield_18801
Jira REST API --> CronJob: list of logbook tickets with service names
CronJob -> Service Portal: GET /api/v2/services/{serviceName}
Service Portal --> CronJob: owner name
CronJob -> Jira REST API: GET /rest/api/2/user/search?query={ownerName}
Jira REST API --> CronJob: accountId
CronJob -> Jira REST API: POST /rest/api/2/issue/{key}/transitions {"transition":{"id":"21"}}
Jira REST API --> CronJob: 204 No Content (or error)
CronJob -> Jira REST API: POST /rest/api/2/issue/{key}/transitions {"transition":{"id":"41"}} (fallback)
CronJob -> Jira REST API: POST /rest/api/2/issue/{key}/comment (closure notice)
Jira REST API --> CronJob: 201 Created
```

## Related

- Architecture container view: `tdo-team-containers`
- Related flows: [Subtask and IA Reminders](subtask-and-ia-reminders.md), [Advisory Actions Reminders](advisory-actions-reminders.md)
- Integration details: [Integrations](../integrations.md)
