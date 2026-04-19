---
service: "tdo-team"
title: "Advisory Actions Reminders"
generated: "2026-03-03"
type: flow
flow_name: "advisory-actions-reminders"
flow_type: scheduled
trigger: "Kubernetes CronJob monthly on the 1st at 07:00 UTC"
participants:
  - "continuumTdoTeamAdvisoryActionsRemindersJob"
architecture_ref: "dynamic-tdo-team-advisory-actions-reminders"
---

# Advisory Actions Reminders

## Summary

The Advisory Actions Reminders flow runs monthly and posts Jira comment reminders on advisory action tickets that are approaching their due dates. The cronjob reads a Jira filter containing advisory action items, looks up service owner data from the Service Portal, and adds a color-formatted Jira comment tagging the service owner. It handles missing service names, inactive service owners, and unassigned tickets with different comment templates.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`advisory-actions-reminders` component)
- **Frequency**: Monthly on the 1st at 07:00 UTC (`0 7 1 * *` in production)
- **Entry point**: `./cronjobs/advisory_actions_reminders.sh`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Advisory Actions Reminders Job | CronJob host; executes the Bash script | `continuumTdoTeamAdvisoryActionsRemindersJob` |
| Jira REST API (external) | Source of advisory action filter results; receives reminder comments | external |
| Service Portal (internal) | Provides service owner name by service name | - |

## Steps

1. **Resolve Jira filter to search URL**: Calls `GET /rest/api/2/filter/48661` to obtain the filter's `searchUrl`
   - From: `continuumTdoTeamAdvisoryActionsRemindersJob`
   - To: Jira REST API
   - Protocol: REST (curl, Basic Auth)

2. **Fetch advisory action tickets**: Executes the filter's search URL with `maxResults=-1` to retrieve all matching tickets; each result provides ticket key, service name (custom field `customfield_18801`), assignee account ID, and reporter account ID
   - From: `continuumTdoTeamAdvisoryActionsRemindersJob`
   - To: Jira REST API
   - Protocol: REST (curl, Basic Auth)

3. **Resolve service name (if missing)**: For tickets where `customfield_18801` is empty, traverses linked and parent tickets looking for a linked GPROD Incident ticket from which to inherit the service name
   - From: `continuumTdoTeamAdvisoryActionsRemindersJob`
   - To: Jira REST API (`GET /rest/api/2/issue/{key}`)
   - Protocol: REST (curl, Basic Auth)

4. **Resolve service owner from Service Portal**: Calls `GET /api/v2/services/{serviceName}` with `GRPN-Client-ID: tdo-coea-automation` header to obtain the service owner's name
   - From: `continuumTdoTeamAdvisoryActionsRemindersJob`
   - To: Service Portal (`$SP_URL`)
   - Protocol: REST (curl)

5. **Resolve service owner Jira account ID**: Calls Jira user search `GET /rest/api/2/user/search?query={ownerEmail}` to find the Jira account ID for the service owner
   - From: `continuumTdoTeamAdvisoryActionsRemindersJob`
   - To: Jira REST API
   - Protocol: REST (curl, Basic Auth)

6. **Post Jira comment**: Posts the appropriate reminder comment (`POST /rest/api/2/issue/{key}/comment`) based on the combination of available data (service name present/missing, assignee present/missing, owner active/inactive). Comment text is a 30-day reminder formatted in Jira wiki markup with blue/red color highlights
   - From: `continuumTdoTeamAdvisoryActionsRemindersJob`
   - To: Jira REST API
   - Protocol: REST (curl, Basic Auth)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Filter returns no tickets | Logs "no 30 days REMINDER results"; script exits cleanly | No action needed |
| Service name missing from ticket | Attempts to inherit from linked GPROD incident; falls back to generic "service name unknown" comment | Comment added noting inability to identify service |
| Service owner inactive in Jira | Posts reminder without active owner mention; tags IMOC team account (`6102c01bc51f3a0069ab29b3`) | Comment added; IMOC team notified |
| Ticket unassigned | Posts additional "unassigned ticket" comment alongside the reminder | Two comments added to ticket |
| Jira comment POST returns non-201 | Logs "ERROR ADDING COMMENT ..." | Comment not added; no retry |

## Sequence Diagram

```
CronJob -> Jira REST API: GET /rest/api/2/filter/48661
Jira REST API --> CronJob: searchUrl
CronJob -> Jira REST API: GET {searchUrl}&maxResults=-1
Jira REST API --> CronJob: List of advisory action tickets
CronJob -> Jira REST API: GET /rest/api/2/issue/{key} (if service name missing)
CronJob -> Service Portal: GET /api/v2/services/{serviceName}
Service Portal --> CronJob: owner name
CronJob -> Jira REST API: GET /rest/api/2/user/search?query={ownerEmail}
Jira REST API --> CronJob: accountId
CronJob -> Jira REST API: POST /rest/api/2/issue/{key}/comment
Jira REST API --> CronJob: 201 Created
```

## Related

- Related flows: [Subtask and IA Reminders](subtask-and-ia-reminders.md), [SEV4 Reminders](sev4-reminders.md)
- Jira filter: `48661` (advisory actions with 30-day reminder SLA)
- Flows index: [Flows](index.md)
