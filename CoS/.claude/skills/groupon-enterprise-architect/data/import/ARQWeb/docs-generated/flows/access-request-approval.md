---
service: "ARQWeb"
title: "Access Request Approval"
generated: "2026-03-03"
type: flow
flow_name: "access-request-approval"
flow_type: synchronous
trigger: "Approver submits an approval or rejection decision via the ARQWeb UI or API"
participants:
  - "continuumArqWebApp"
  - "continuumArqPostgres"
  - "continuumJiraService"
  - "smtpRelay"
  - "continuumArqWorker"
architecture_ref: "components-continuum-arq-web-app"
---

# Access Request Approval

## Summary

A designated approver (manager or SOX admin) reviews a pending access request in ARQWeb and submits an approval or rejection decision. The web application records the decision, updates the request status in PostgreSQL, updates the Jira ticket to reflect the decision, and enqueues a provisioning job (on approval) or rejection notification job (on rejection) for the ARQ Worker to process asynchronously. An email notification is sent to the requestor confirming the outcome.

## Trigger

- **Type**: user-action / api-call
- **Source**: Approver via browser (POST to `/requests/<id>/approve` or `/requests/<id>/reject`) or API client
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ARQWeb App | Receives decision, validates approver authority, persists result, enqueues jobs | `continuumArqWebApp` |
| ARQ PostgreSQL | Stores updated request status, approval record, and new queued jobs | `continuumArqPostgres` |
| Jira | Receives status update on the access workflow ticket | `continuumJiraService` |
| SMTP Relay | Delivers decision notification email to the requestor | `smtpRelay` |
| ARQ Worker | Processes the provisioning or rejection notification job enqueued by the web app | `continuumArqWorker` |

## Steps

1. **Receives approval decision**: Approver submits approval or rejection with optional justification comment.
   - From: `arqWebRouting`
   - To: `arqWebAccessRequestDomain`
   - Protocol: direct (in-process)

2. **Validates approver authority**: Checks that the authenticated user is the designated approver for this request (using stored approval routing and Workday hierarchy data).
   - From: `arqWebAccessRequestDomain`
   - To: `arqWebPersistence` -> `continuumArqPostgres`
   - Protocol: SQL/TCP

3. **Records approval decision**: Writes an approval or rejection record to PostgreSQL; updates the request status to `approved` or `rejected`.
   - From: `arqWebAccessRequestDomain`
   - To: `arqWebPersistence` -> `continuumArqPostgres`
   - Protocol: SQL/TCP

4. **Updates Jira ticket**: Transitions the Jira ticket to the approved or rejected state, adding the approver's decision comment.
   - From: `arqWebExternalAdapters`
   - To: `continuumJiraService`
   - Protocol: HTTPS API

5. **Enqueues provisioning or rejection job**: For approvals, writes a provisioning job to the PostgreSQL job queue for the worker to execute access changes. For rejections, writes a notification-only job.
   - From: `arqWebPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

6. **Sends decision notification email**: Sends an email via SMTP relay to the requestor confirming whether their request was approved or rejected.
   - From: `arqWebExternalAdapters`
   - To: `smtpRelay`
   - Protocol: SMTP

7. **Returns confirmation to approver**: Returns HTTP 200 (or redirect for UI) confirming the decision was recorded.
   - From: `arqWebRouting`
   - To: Approver browser / API client
   - Protocol: HTTP

8. **Worker executes provisioning job** (asynchronous, subsequent): ARQ Worker dequeues and processes the provisioning job. See [Access Provisioning (Worker)](access-provisioning-worker.md).
   - From: `continuumArqWorker`
   - To: External systems (AD, GitHub, Cyclops)
   - Protocol: LDAP/LDAPS, HTTPS API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unauthorized approver | Request rejected with HTTP 403 | Decision not recorded; approver sees error |
| Request not found | HTTP 404 returned | Decision not recorded |
| Jira update fails | Error logged; Jira job enqueued for worker retry | Request state updated; Jira reflects stale status until worker retries |
| SMTP delivery fails | Email error logged; notification deferred to next digest | Requestor may not receive immediate email |
| Database write fails | HTTP 500 returned; no partial state committed | Approver must retry |

## Sequence Diagram

```
Approver -> ARQWebApp: POST /requests/<id>/approve (decision + comment)
ARQWebApp -> ARQPostgres: SELECT request and approver authority
ARQPostgres --> ARQWebApp: Request record and approval routing
ARQWebApp -> ARQPostgres: INSERT approval record; UPDATE request status=approved
ARQWebApp -> Jira: PUT transition ticket to approved
Jira --> ARQWebApp: Updated ticket
ARQWebApp -> ARQPostgres: INSERT provisioning job (queued)
ARQWebApp -> SMTPRelay: SEND decision notification to requestor
ARQWebApp --> Approver: HTTP 200 (decision confirmed)
-- async --
ARQWorker -> ARQPostgres: SELECT runnable provisioning job
ARQWorker -> ExternalSystems: Execute access changes (AD, GitHub, Cyclops)
```

## Related

- Architecture dynamic view: `components-continuum-arq-web-app`
- Related flows: [Access Request Submission](access-request-submission.md), [Access Provisioning (Worker)](access-provisioning-worker.md)
