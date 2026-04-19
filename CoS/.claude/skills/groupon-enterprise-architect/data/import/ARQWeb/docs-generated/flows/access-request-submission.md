---
service: "ARQWeb"
title: "Access Request Submission"
generated: "2026-03-03"
type: flow
flow_name: "access-request-submission"
flow_type: synchronous
trigger: "User submits a new access request via the ARQWeb UI or API"
participants:
  - "continuumArqWebApp"
  - "continuumArqPostgres"
  - "continuumJiraService"
  - "workday"
  - "servicePortal"
  - "smtpRelay"
architecture_ref: "components-continuum-arq-web-app"
---

# Access Request Submission

## Summary

An employee submits a new access request through the ARQWeb web interface or API. The web application validates the request against employee data from Workday and service ownership data from Service Portal, persists the request to PostgreSQL, creates a Jira ticket to track the workflow, enqueues an approval notification job, and sends an immediate email notification to the designated approver.

## Trigger

- **Type**: user-action / api-call
- **Source**: Groupon employee via browser (POST to `/requests`) or API client
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ARQWeb App | Receives, validates, and persists the request; orchestrates downstream calls | `continuumArqWebApp` |
| ARQ PostgreSQL | Stores the new access request record and queued jobs | `continuumArqPostgres` |
| Workday | Provides employee profile and manager hierarchy for validation | `workday` |
| Service Portal | Provides service ownership and metadata for the requested resource | `servicePortal` |
| Jira | Receives new ticket creation for the access workflow | `continuumJiraService` |
| SMTP Relay | Delivers approval notification email to the designated approver | `smtpRelay` |

## Steps

1. **Receives access request**: Employee submits the request form or API payload (requestor identity, target system/service, justification, access level).
   - From: `arqWebRouting`
   - To: `arqWebAccessRequestDomain`
   - Protocol: direct (in-process)

2. **Fetches employee profile**: Queries Workday to validate the requestor exists and retrieve their manager chain for approval routing.
   - From: `arqWebExternalAdapters`
   - To: `workday`
   - Protocol: HTTPS

3. **Fetches service ownership**: Queries Service Portal to retrieve the service owner and associated approver for the requested resource.
   - From: `arqWebExternalAdapters`
   - To: `servicePortal`
   - Protocol: HTTPS/JSON

4. **Validates and creates request record**: Validates request parameters against fetched data and writes a new access request record to PostgreSQL with status `pending`.
   - From: `arqWebAccessRequestDomain`
   - To: `arqWebPersistence` -> `continuumArqPostgres`
   - Protocol: SQL/TCP

5. **Creates Jira ticket**: Creates a Jira ticket representing the access request workflow, recording the ticket key against the request record.
   - From: `arqWebExternalAdapters`
   - To: `continuumJiraService`
   - Protocol: HTTPS API

6. **Enqueues approval notification job**: Writes a queued job record to PostgreSQL for the ARQ Worker to process the approval notification email.
   - From: `arqWebPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

7. **Sends immediate approval email**: Sends an email via the SMTP relay to the designated approver notifying them of the pending request.
   - From: `arqWebExternalAdapters`
   - To: `smtpRelay`
   - Protocol: SMTP

8. **Returns confirmation to requestor**: Returns HTTP 201 (or redirect for UI) with the new request ID and Jira ticket link.
   - From: `arqWebRouting`
   - To: Browser / API client
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Workday unavailable | Request validation fails; returns error to user | Requestor must retry; no partial record created |
| Service Portal unavailable | Service ownership lookup fails; request may be created with default approver routing | Request created with degraded approval routing |
| Jira ticket creation fails | Error logged; request still persisted; Jira job enqueued for worker retry | Request proceeds; Jira ticket created asynchronously |
| SMTP delivery fails | Email error logged; approval notification deferred to next worker digest run | Approver may not receive immediate email but will receive digest |
| Database write fails | HTTP 500 returned to requestor | No request created; requestor must retry |

## Sequence Diagram

```
Employee -> ARQWebApp: POST /requests (access request payload)
ARQWebApp -> Workday: GET employee profile and manager chain
Workday --> ARQWebApp: Employee data
ARQWebApp -> ServicePortal: GET service ownership for requested resource
ServicePortal --> ARQWebApp: Service owner and approver
ARQWebApp -> ARQPostgres: INSERT access request (status=pending)
ARQWebApp -> Jira: POST create access workflow ticket
Jira --> ARQWebApp: Ticket key
ARQWebApp -> ARQPostgres: INSERT queued notification job
ARQWebApp -> SMTPRelay: SEND approval notification email
ARQWebApp --> Employee: HTTP 201 (request ID, Jira ticket link)
```

## Related

- Architecture dynamic view: `components-continuum-arq-web-app`
- Related flows: [Access Request Approval](access-request-approval.md), [Access Provisioning (Worker)](access-provisioning-worker.md)
