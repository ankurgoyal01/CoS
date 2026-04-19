---
service: "ein_project"
title: "Change Request Creation and Approval"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "change-request-creation-approval"
flow_type: synchronous
trigger: "POST /api/changes/ from deployment tooling or engineer via web UI"
participants:
  - "continuumProdcatProxy"
  - "continuumProdcatWebApp"
  - "continuumProdcatRedis"
  - "continuumProdcatPostgres"
  - "jiraCloudSystem_unk_c3d4"
  - "jsmAlertsSystem_unk_d4e5"
  - "servicePortalSystem_unk_f6a7"
  - "googleChatSystem_unk_e5f6"
architecture_ref: "dynamic-change-request"
---

# Change Request Creation and Approval

## Summary

This is the primary compliance gate flow. A deployment tool or engineer submits a change request to ProdCat, which evaluates it against all active policies — JIRA ticket state, region lock status (from active incidents), change window schedules, and service registration in Service Portal — before returning an approved or rejected decision. On approval, a Google Chat notification is posted. The entire flow is synchronous and the submitting tool blocks on the response.

## Trigger

- **Type**: api-call
- **Source**: Deployment tooling (DeployBot, CI pipeline) via `POST /api/changes/`, or engineer via the web UI
- **Frequency**: On-demand, per deployment attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Nginx Proxy | Receives inbound HTTP and forwards to web app | `continuumProdcatProxy` |
| ProdCat Web App | Orchestrates all validation logic and persists the change record | `continuumProdcatWebApp` |
| REST API component | Receives the request, authenticates the caller, and dispatches to the validation engine | `apiController` |
| Auth Service | Authenticates and authorizes the submitting user or system | `einProject_authService` |
| Validation Engine | Runs all policy checks against external systems | `validationEngine` |
| Policy Service | Evaluates region and approval window policies | `policyService` |
| Cache Client | Returns cached validation results to skip redundant external API calls | `einProject_cacheClient` |
| Data Access | Reads policy data and writes the final change record to PostgreSQL | `einProject_dataAccess` |
| JIRA Client | Queries and updates the linked JIRA ticket | `einProject_jiraClient` |
| JSM Alerts Client | Checks for active incidents that would trigger a region lock | `jsmAlertsClient` |
| Service Portal Client | Validates the target service is registered and configured | `einProject_servicePortalClient` |
| Google Chat Client | Posts approval or rejection notification | `googleChatClient` |
| Redis | Stores cached validation results and sessions | `continuumProdcatRedis` |
| PostgreSQL | Stores the persisted change record and policy configuration | `continuumProdcatPostgres` |

## Steps

1. **Receive request**: Nginx proxy receives the inbound `POST /api/changes/` request.
   - From: `continuumProdcatProxy`
   - To: `continuumProdcatWebApp`
   - Protocol: HTTP

2. **Authenticate caller**: REST API delegates to Auth Service to validate the session or JWT token.
   - From: `apiController`
   - To: `einProject_authService`
   - Protocol: direct

3. **Check validation cache**: Cache Client queries Redis for a cached result for the same change request parameters.
   - From: `einProject_cacheClient`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

4. **Load policy and deployment data** (on cache miss): Data Access reads active change windows, region locks, holiday policies, and approver lists from PostgreSQL.
   - From: `einProject_dataAccess`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

5. **Evaluate approval and region policies**: Policy Service checks whether the current time is within an approved change window and whether the target region is locked.
   - From: `validationEngine`
   - To: `policyService`
   - Protocol: direct

6. **Check JIRA ticket status**: JIRA Client calls JIRA Cloud API v3 to confirm the linked ticket exists, is in the correct workflow state, and is approved.
   - From: `validationEngine`
   - To: JIRA Cloud (`jiraCloudSystem_unk_c3d4`)
   - Protocol: REST

7. **Check active incidents**: JSM Alerts Client queries JSM for active alerts scoped to the target region. If an incident is active, the region is considered locked.
   - From: `validationEngine`
   - To: JSM (`jsmAlertsSystem_unk_d4e5`)
   - Protocol: REST

8. **Validate service configuration**: Service Portal Client confirms the target service is registered and its configuration is valid.
   - From: `validationEngine`
   - To: Service Portal (`servicePortalSystem_unk_f6a7`)
   - Protocol: REST

9. **Write validation result to cache**: Cache Client stores the validated result in Redis to serve subsequent identical requests without re-calling external APIs.
   - From: `einProject_cacheClient`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

10. **Persist change record**: Data Access writes the final change request record (with approval decision and reason) to PostgreSQL.
    - From: `einProject_dataAccess`
    - To: `continuumProdcatPostgres`
    - Protocol: TCP/SQL

11. **Post notification**: Google Chat Client sends an approval or rejection notification to the configured Google Chat space.
    - From: `googleChatClient`
    - To: Google Chat (`googleChatSystem_unk_e5f6`)
    - Protocol: REST

12. **Return decision**: The REST API returns the approval or rejection response to the caller.
    - From: `apiController`
    - To: Calling deployment tool or engineer
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JIRA is unreachable | Validation fails closed | Change request rejected; error reason recorded |
| JSM is unreachable | Last known incident state preserved | Region lock state held; change may be blocked |
| Service Portal is unreachable | Validation fails closed | Change request rejected; error reason recorded |
| Authentication fails | 401 returned immediately | Request rejected before validation begins |
| Policy data unavailable (DB down) | Request fails with 500 | Change request rejected; no record persisted |
| Google Chat notification fails | Failure is swallowed | Change decision is unaffected; notification lost |

## Sequence Diagram

```
DeployBot -> continuumProdcatProxy: POST /api/changes/
continuumProdcatProxy -> continuumProdcatWebApp: Forward HTTP request
continuumProdcatWebApp -> continuumProdcatRedis: Check validation cache
continuumProdcatWebApp -> continuumProdcatPostgres: Load policy and deployment data
continuumProdcatWebApp -> JIRACloud: Check and update ticket (jiraCloudSystem_unk_c3d4)
continuumProdcatWebApp -> JSM: Check active incidents (jsmAlertsSystem_unk_d4e5)
continuumProdcatWebApp -> ServicePortal: Validate service config (servicePortalSystem_unk_f6a7)
continuumProdcatWebApp -> continuumProdcatRedis: Write validation result to cache
continuumProdcatWebApp -> continuumProdcatPostgres: Persist change record
continuumProdcatWebApp -> GoogleChat: Post approval/rejection notification (googleChatSystem_unk_e5f6)
continuumProdcatWebApp --> continuumProdcatProxy: Approval decision response
continuumProdcatProxy --> DeployBot: HTTP 200 approved / 403 rejected
```

## Related

- Architecture dynamic view: `dynamic-change-request`
- Related flows: [Change Validation Policy Check](change-validation-policy-check.md), [DeployBot Override Detection](deploybot-override-detection.md)
