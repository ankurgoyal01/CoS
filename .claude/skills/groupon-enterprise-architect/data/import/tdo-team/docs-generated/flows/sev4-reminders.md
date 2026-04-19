---
service: "tdo-team"
title: "SEV4 Reminders"
generated: "2026-03-03"
type: flow
flow_name: "sev4-reminders"
flow_type: scheduled
trigger: "Kubernetes CronJob — Mondays at 09:00 UTC"
participants:
  - "continuumTdoTeamSev4RemindersJob"
architecture_ref: "tdo-team-containers"
---

# SEV4 Reminders

## Summary

The SEV4 Reminders flow runs every Monday at 09:00 UTC and posts Jira comment reminders on open SEV4 incidents that require SLA-compliant bi-daily status updates. The flow queries a Jira filter for qualifying SEV4 tickets, resolves the service owner via the Service Portal, and posts reminder comments tagging the responsible parties to ensure the on-call team provides timely updates on low-severity incidents.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`continuumTdoTeamSev4RemindersJob`)
- **Frequency**: Mondays at 09:00 UTC (`0 9 * * 1`)
- **Invocation**: `./cronjobs/sev4-reminders.sh` (Bash shell script)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SEV4 Reminders CronJob | Schedule trigger; executes the Bash script | `continuumTdoTeamSev4RemindersJob` |
| Jira REST API v2 | Source of open SEV4 incident tickets; target for reminder comments | - |
| Service Portal | Resolves service owner name from service name | - |

## Steps

1. **Fetch Jira filter search URL**: The script calls `GET /rest/api/2/filter/48483` to retrieve the `searchUrl` for open SEV4 incident tickets requiring reminder comments.
   - From: SEV4 Reminders CronJob
   - To: Jira REST API (`https://groupondev.atlassian.net/rest/api/2/filter/48483`)
   - Protocol: REST (HTTPS, Basic Auth)

2. **Execute filter search**: The script calls the `searchUrl` with `maxResults=-1` to retrieve all matching SEV4 incident tickets, extracting ticket key, service name, assignee, and reporter fields.
   - From: SEV4 Reminders CronJob
   - To: Jira REST API (search URL)
   - Protocol: REST (HTTPS, Basic Auth)

3. **Resolve service owner from Service Portal**: For each ticket, the script calls `GET /api/v2/services/{serviceName}` to retrieve the owner's name.
   - From: SEV4 Reminders CronJob
   - To: Service Portal (`$SP_URL/api/v2/services/{name}`)
   - Protocol: REST (HTTP, `GRPN-Client-ID: tdo-coea-automation` header)

4. **Resolve service owner's Jira account ID**: The script queries `GET /rest/api/2/user/search?query={ownerEmail}` to get the Jira account ID for the mention in the reminder comment.
   - From: SEV4 Reminders CronJob
   - To: Jira REST API
   - Protocol: REST (HTTPS, Basic Auth)

5. **Post SEV4 reminder comment**: The script posts a Jira comment on the SEV4 incident ticket reminding the assigned team to update the ticket status per the SLA, tagging the service owner and/or IMOC team as appropriate.
   - From: SEV4 Reminders CronJob
   - To: Jira REST API (`POST /rest/api/2/issue/{key}/comment`)
   - Protocol: REST (HTTPS, Basic Auth)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira filter returns no tickets | Script logs "no results" and exits cleanly | No action; normal completion |
| Service Portal returns null owner | Falls back to IMOC team account ID for comment mention | Comment posted; IMOC team tagged instead of service owner |
| Jira comment POST returns non-201 | Logs "ERROR ADDING COMMENT" | Comment not added; no retry |

## Sequence Diagram

```
CronJob -> Jira REST API: GET /rest/api/2/filter/48483
Jira REST API --> CronJob: searchUrl
CronJob -> Jira REST API: GET searchUrl&maxResults=-1
Jira REST API --> CronJob: list of open SEV4 tickets
CronJob -> Service Portal: GET /api/v2/services/{serviceName}
Service Portal --> CronJob: owner name
CronJob -> Jira REST API: GET /rest/api/2/user/search?query={ownerEmail}
Jira REST API --> CronJob: accountId
CronJob -> Jira REST API: POST /rest/api/2/issue/{key}/comment (SEV4 SLA reminder)
Jira REST API --> CronJob: 201 Created
```

## Related

- Architecture container view: `tdo-team-containers`
- Related flows: [Advisory Actions Reminders](advisory-actions-reminders.md), [Subtask and IA Reminders](subtask-and-ia-reminders.md)
- Integration details: [Integrations](../integrations.md)
