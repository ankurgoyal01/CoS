---
service: "ARQWeb"
title: "Access Provisioning (Worker)"
generated: "2026-03-03"
type: flow
flow_name: "access-provisioning-worker"
flow_type: asynchronous
trigger: "Approved access request job dequeued by the ARQ Worker cron loop"
participants:
  - "continuumArqWorker"
  - "continuumArqPostgres"
  - "activeDirectory"
  - "githubEnterprise"
  - "cyclops"
  - "continuumJiraService"
  - "smtpRelay"
  - "elasticApm"
architecture_ref: "components-continuum-arq-worker"
---

# Access Provisioning (Worker)

## Summary

After an access request is approved, the ARQ Worker asynchronously executes the actual access provisioning changes. The worker dequeues the provisioning job, determines which systems require changes (Active Directory group memberships, GitHub Enterprise team/repository access, Cyclops SOX role assignments), applies each change, updates the Jira ticket to reflect completion, sends a confirmation email to the requestor, delivers webhook notifications to any registered consumers, and records all outcomes in the PostgreSQL audit trail.

## Trigger

- **Type**: schedule (cron loop poll)
- **Source**: `arqWorkerCronLoop` polling the PostgreSQL job queue for runnable provisioning jobs
- **Frequency**: Continuous (cron loop runs on a short interval); each job processed as soon as it becomes runnable

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ARQ Worker | Dequeues job, orchestrates provisioning calls, records outcomes | `continuumArqWorker` |
| ARQ PostgreSQL | Provides job queue and receives audit log writes and job status updates | `continuumArqPostgres` |
| Active Directory | Receives AD group membership changes for the approved access | `activeDirectory` |
| GitHub Enterprise | Receives team/repository access changes for the approved access | `githubEnterprise` |
| Cyclops | Receives SOX role workflow execution for controlled resources | `cyclops` |
| Jira | Receives ticket transition to "provisioned" or "completed" state | `continuumJiraService` |
| SMTP Relay | Delivers provisioning confirmation email to requestor | `smtpRelay` |
| Elastic APM | Receives worker telemetry and any exception traces | `elasticApm` |

## Steps

1. **Polls job queue**: Cron loop scans PostgreSQL job queue for jobs with status `queued` and `scheduled_at <= now()`.
   - From: `arqWorkerCronLoop`
   - To: `arqWorkerPersistence` -> `continuumArqPostgres`
   - Protocol: SQL/TCP

2. **Claims job**: Updates job status to `running` and records the start time to prevent duplicate execution.
   - From: `arqWorkerJobHandlers`
   - To: `arqWorkerPersistence` -> `continuumArqPostgres`
   - Protocol: SQL/TCP

3. **Applies Active Directory changes**: Calls Active Directory via LDAP/LDAPS to add the user to the approved AD groups.
   - From: `arqWorkerExternalAdapters`
   - To: `activeDirectory`
   - Protocol: LDAP/LDAPS

4. **Applies GitHub Enterprise access**: Calls the GitHub Enterprise API to add the user to the approved team(s) or grant repository access.
   - From: `arqWorkerExternalAdapters`
   - To: `githubEnterprise`
   - Protocol: HTTPS API

5. **Runs Cyclops SOX workflow**: For SOX-controlled resources, calls Cyclops to execute the role assignment workflow and record SOX compliance evidence.
   - From: `arqWorkerExternalAdapters`
   - To: `cyclops`
   - Protocol: HTTPS API

6. **Updates Jira ticket**: Transitions the Jira ticket to "provisioned" or "completed" state with a summary of changes applied.
   - From: `arqWorkerExternalAdapters`
   - To: `continuumJiraService`
   - Protocol: HTTPS API

7. **Sends confirmation email**: Sends a provisioning completion email to the requestor via SMTP relay.
   - From: `arqWorkerExternalAdapters`
   - To: `smtpRelay`
   - Protocol: SMTP

8. **Delivers webhook notifications**: For any registered webhook consumers, delivers an HTTPS POST notification with the access state change payload.
   - From: `arqWorkerExternalAdapters`
   - To: `externalWebhookConsumers`
   - Protocol: HTTPS POST

9. **Records audit trail and marks job complete**: Writes an audit record for each provisioning action and updates job status to `completed`.
   - From: `arqWorkerPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

10. **Publishes telemetry**: Reports job execution timing and any errors to Elastic APM.
    - From: `continuumArqWorker`
    - To: `elasticApm`
    - Protocol: APM agent

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AD call fails | Job status reset to `queued`; attempt count incremented; retried on next cron cycle | Access change deferred until AD is available |
| GitHub API fails | Job status reset to `queued`; retried | GitHub access deferred |
| Cyclops call fails | Job status reset to `queued`; retried | SOX role assignment deferred |
| Maximum retries exceeded | Job status set to `failed`; error recorded in job record | Requires manual intervention; alert triggered |
| Jira update fails | Error logged; Jira job re-enqueued for retry | Provisioning still proceeds; Jira reflects stale state |
| SMTP delivery fails | Error logged; delivery deferred | Requestor does not receive immediate confirmation |
| Webhook delivery fails | Delivery retried; consumer marked as erroring after repeated failures | External consumer receives delayed or no notification |
| Job timeout exceeded | Job killed; status reset for retry | Protects worker from hanging on unresponsive external systems |

## Sequence Diagram

```
ARQWorker.CronLoop -> ARQPostgres: SELECT queued provisioning jobs
ARQPostgres --> ARQWorker.CronLoop: Runnable job list
ARQWorker.CronLoop -> ARQWorker.JobHandlers: Dispatch job
ARQWorker.JobHandlers -> ARQPostgres: UPDATE job status=running
ARQWorker.ExternalAdapters -> ActiveDirectory: LDAP modify group memberships
ActiveDirectory --> ARQWorker.ExternalAdapters: Success
ARQWorker.ExternalAdapters -> GitHubEnterprise: PUT team membership / repo access
GitHubEnterprise --> ARQWorker.ExternalAdapters: Success
ARQWorker.ExternalAdapters -> Cyclops: POST SOX role workflow
Cyclops --> ARQWorker.ExternalAdapters: Workflow complete
ARQWorker.ExternalAdapters -> Jira: PUT ticket transition=completed
ARQWorker.ExternalAdapters -> SMTPRelay: SEND confirmation email
ARQWorker.ExternalAdapters -> WebhookConsumers: POST state change notification
ARQWorker.Persistence -> ARQPostgres: INSERT audit records; UPDATE job status=completed
ARQWorker -> ElasticAPM: Report job telemetry
```

## Related

- Architecture dynamic view: `components-continuum-arq-worker`
- Related flows: [Access Request Approval](access-request-approval.md), [Access Request Submission](access-request-submission.md)
