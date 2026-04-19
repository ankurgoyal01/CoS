---
service: "mbus-sigint-configuration-v2"
title: "Jira Ticket Automation"
generated: "2026-03-03"
type: flow
flow_name: "jira-ticket-automation"
flow_type: scheduled
trigger: "Quartz JiraJobScheduler jobs triggered by change-request state changes"
participants:
  - "continuumMbusSigintConfigurationService"
  - "continuumMbusSigintConfigurationDatabase"
  - "Jira API"
architecture_ref: "components-continuum-mbus-sigint-configuration-service"
---

# Jira Ticket Automation

## Summary

The service maintains a parallel Quartz scheduler (`JiraJobScheduler`, 3 threads) dedicated to Jira ticket operations. Four jobs handle the full Jira integration lifecycle: creating a Jira task per change request, linking MBC tasks to GPROD Jira tickets, transitioning MBC task status in sync with the change-request workflow, and transitioning GPROD task status when production deployment completes. This automation keeps Jira audit trails synchronized with the configuration change lifecycle without operator involvement.

## Trigger

- **Type**: schedule (Quartz) + state-driven (domain services enqueue jobs on state transitions)
- **Source**: `JiraJobScheduler` within `continuumMbusSigintConfigurationService`
- **Frequency**: Near-real-time following change-request state changes; Quartz thread pool of 3 workers

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduler Jobs (JiraJobScheduler) | Executes all four Jira jobs | `mbsc_schedulerJobs` |
| Domain Services | Enqueues Jira jobs on request state transitions | `mbsc_domainServices` |
| Integration Clients | HTTP client calls to Jira REST API | `mbsc_integrationClients` |
| Persistence Adapters | Reads request state; writes Jira ticket ID back | `mbsc_persistenceAdapters` |
| MBus Sigint Configuration Database | Source of change-request and gprod-config data | `continuumMbusSigintConfigurationDatabase` |
| Jira API | Creates, links, and transitions Jira issues | External |

## Steps

1. **Change request created (NEW)**: After `POST /change-request` persists the request, domain services enqueue a `JiraCreateJob` trigger.
   - From: `mbsc_domainServices`
   - To: `mbsc_schedulerJobs` (Quartz)
   - Protocol: Quartz in-process

2. **JiraCreateJob executes**: Reads request details from PostgreSQL, calls Jira API to create a new task (MBC issue type) for the change request, and writes the returned Jira ticket key back to the `request.jira_ticket` column.
   - From: `mbsc_schedulerJobs`
   - To: Jira API (HTTPS/REST)
   - Return: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`

3. **JiraLinkingJob executes**: Reads the gprod_config for the cluster to identify the associated GPROD Jira ticket. Links the newly created MBC task to the GPROD issue via the Jira issue-link API.
   - From: `mbsc_schedulerJobs`
   - To: Jira API (HTTPS/REST)
   - Protocol: HTTPS/REST

4. **State transitions trigger ChangeRequestJiraTransitionJob**: Each significant state change (`DEPLOY_TEST`, `DEPLOYED_TEST`, `DEPLOY_PROD`, `FAILED_*`, `REJECTED`, `CANCELLED`) enqueues a `ChangeRequestJiraTransitionJob` with the new target Jira status.
   - From: `mbsc_domainServices`
   - To: `mbsc_schedulerJobs` (Quartz)
   - Protocol: Quartz in-process

5. **ChangeRequestJiraTransitionJob executes**: Calls Jira Transition API to move the MBC task to the corresponding Jira workflow status (e.g., "In Progress", "Done", "Rejected").
   - From: `mbsc_schedulerJobs`
   - To: Jira API (HTTPS/REST)
   - Protocol: HTTPS/REST

6. **Production deployment completes — GprodJiraTransitionJob**: After `DEPLOYED_PROD` state is set, `GprodJiraTransitionJob` transitions the linked GPROD Jira ticket to its completion status to close the production change record.
   - From: `mbsc_schedulerJobs`
   - To: Jira API (HTTPS/REST)
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira API returns HTTP 4xx/5xx | Job execution fails; Quartz records failure | Job can be retried; `jiraTicket` field remains empty or stale |
| Jira API token expired | All Jira jobs fail with auth error | Operator must rotate `JIRA_API_PASSWORD` in k8s-secret and restart pods |
| Network timeout to Jira | Jersey client timeout | Job fails; Quartz retry if configured; audit trail lags behind |
| GPROD ticket not found for cluster | `JiraLinkingJob` has no target to link | Linking is skipped or fails silently; MBC task remains unlinked |

## Sequence Diagram

```
mbsc_domainServices -> QuartzJiraScheduler  : enqueue JiraCreateJob (on NEW request)
QuartzJiraScheduler -> mbsc_schedulerJobs   : JiraCreateJob fires
mbsc_schedulerJobs  -> mbsc_persistenceAdapters : read request details
mbsc_schedulerJobs  -> JiraAPI              : POST /rest/api/2/issue (create MBC task)
JiraAPI             --> mbsc_schedulerJobs   : Jira issue key
mbsc_schedulerJobs  -> mbsc_persistenceAdapters : write jira_ticket to request

mbsc_schedulerJobs  -> JiraAPI              : JiraLinkingJob: link MBC to GPROD
JiraAPI             --> mbsc_schedulerJobs   : link confirmed

mbsc_domainServices -> QuartzJiraScheduler  : enqueue ChangeRequestJiraTransitionJob (per state)
QuartzJiraScheduler -> mbsc_schedulerJobs   : ChangeRequestJiraTransitionJob fires
mbsc_schedulerJobs  -> JiraAPI              : POST /rest/api/2/issue/{key}/transitions
JiraAPI             --> mbsc_schedulerJobs   : transition confirmed

mbsc_domainServices -> QuartzJiraScheduler  : enqueue GprodJiraTransitionJob (on DEPLOYED_PROD)
QuartzJiraScheduler -> mbsc_schedulerJobs   : GprodJiraTransitionJob fires
mbsc_schedulerJobs  -> JiraAPI              : transition GPROD ticket to Done
JiraAPI             --> mbsc_schedulerJobs   : transition confirmed
```

## Related

- Architecture dynamic view: `components-continuum-mbus-sigint-configuration-service`
- Related flows: [Change Request Lifecycle](change-request-lifecycle.md)
