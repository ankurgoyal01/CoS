---
service: "ein_project"
title: "Change Validation Policy Check"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "change-validation-policy-check"
flow_type: synchronous
trigger: "POST /api/check/ from deployment tooling performing a pre-flight validation"
participants:
  - "continuumProdcatProxy"
  - "continuumProdcatWebApp"
  - "continuumProdcatRedis"
  - "continuumProdcatPostgres"
  - "jiraCloudSystem_unk_c3d4"
  - "jsmAlertsSystem_unk_d4e5"
  - "servicePortalSystem_unk_f6a7"
architecture_ref: "dynamic-change-request"
---

# Change Validation Policy Check

## Summary

The policy check flow runs the full ProdCat validation pipeline on a prospective change but does not persist a change request record to the database. It is designed for deployment tooling that wants to determine whether a deployment would be approved before committing to submitting a formal change request. The response is identical in structure to the approval response — approved or rejected with reasons — but no side effects (no JIRA update, no Google Chat notification, no database write) are produced.

## Trigger

- **Type**: api-call
- **Source**: Deployment tooling (CI pipeline, DeployBot) performing a pre-flight check
- **Frequency**: On-demand; typically called immediately before a deployment is initiated

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Nginx Proxy | Receives inbound HTTP and forwards to web app | `continuumProdcatProxy` |
| ProdCat Web App | Orchestrates validation without persisting state | `continuumProdcatWebApp` |
| REST API component | Receives and routes the check request | `apiController` |
| Auth Service | Authenticates and authorizes the caller | `einProject_authService` |
| Validation Engine | Runs all policy checks against external systems | `validationEngine` |
| Policy Service | Evaluates region and approval window policies | `policyService` |
| Cache Client | Checks for and returns cached validation results | `einProject_cacheClient` |
| Data Access | Reads policy configuration from PostgreSQL (read-only for this flow) | `einProject_dataAccess` |
| JIRA Client | Queries JIRA ticket status | `einProject_jiraClient` |
| JSM Alerts Client | Checks for active incidents for the target region | `jsmAlertsClient` |
| Service Portal Client | Validates service registration | `einProject_servicePortalClient` |
| Redis | Stores and returns cached validation results | `continuumProdcatRedis` |
| PostgreSQL | Provides policy, region, and change window configuration (read-only) | `continuumProdcatPostgres` |

## Steps

1. **Receive check request**: Nginx proxy receives `POST /api/check/` and forwards to the web app.
   - From: `continuumProdcatProxy`
   - To: `continuumProdcatWebApp`
   - Protocol: HTTP

2. **Authenticate caller**: Auth Service validates the session or JWT token.
   - From: `apiController`
   - To: `einProject_authService`
   - Protocol: direct

3. **Check validation cache**: Cache Client queries Redis for a cached result matching the request parameters.
   - From: `einProject_cacheClient`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

4. **Load policy data** (on cache miss): Data Access reads active change windows, region locks, and policies from PostgreSQL.
   - From: `einProject_dataAccess`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

5. **Evaluate policies**: Policy Service evaluates whether the current time and target region are within approved deployment parameters.
   - From: `validationEngine`
   - To: `policyService`
   - Protocol: direct

6. **Check JIRA ticket**: JIRA Client queries the linked ticket for workflow state and approval status.
   - From: `validationEngine`
   - To: JIRA Cloud (`jiraCloudSystem_unk_c3d4`)
   - Protocol: REST

7. **Check active incidents**: JSM Alerts Client queries JSM for active alerts on the target region.
   - From: `validationEngine`
   - To: JSM (`jsmAlertsSystem_unk_d4e5`)
   - Protocol: REST

8. **Validate service configuration**: Service Portal Client confirms service registration is valid.
   - From: `validationEngine`
   - To: Service Portal (`servicePortalSystem_unk_f6a7`)
   - Protocol: REST

9. **Cache the result**: Cache Client writes the validation result to Redis for reuse.
   - From: `einProject_cacheClient`
   - To: `continuumProdcatRedis`
   - Protocol: TCP/Redis

10. **Return result**: REST API returns the validation outcome (approved / rejected with reasons) without writing any records to the database and without posting notifications.
    - From: `apiController`
    - To: Calling deployment tool
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JIRA is unreachable | Validation fails closed | Returns rejected; no record persisted |
| JSM is unreachable | Last known state preserved | May return stale region lock assessment |
| Service Portal unreachable | Validation fails closed | Returns rejected |
| Authentication fails | 401 returned immediately | No validation performed |
| Database unreachable | Request fails with 500 | No policy data available; request fails |

## Sequence Diagram

```
CI Pipeline -> continuumProdcatProxy: POST /api/check/
continuumProdcatProxy -> continuumProdcatWebApp: Forward HTTP request
continuumProdcatWebApp -> continuumProdcatRedis: Check validation cache
continuumProdcatWebApp -> continuumProdcatPostgres: Load policy data (read-only)
continuumProdcatWebApp -> JIRACloud: Check ticket status (jiraCloudSystem_unk_c3d4)
continuumProdcatWebApp -> JSM: Check active incidents (jsmAlertsSystem_unk_d4e5)
continuumProdcatWebApp -> ServicePortal: Validate service (servicePortalSystem_unk_f6a7)
continuumProdcatWebApp -> continuumProdcatRedis: Cache validation result
continuumProdcatWebApp --> continuumProdcatProxy: Validation result (no DB write, no notification)
continuumProdcatProxy --> CI Pipeline: HTTP 200 approved / 403 rejected
```

## Related

- Architecture dynamic view: `dynamic-change-request`
- Related flows: [Change Request Creation and Approval](change-request-creation-approval.md)
