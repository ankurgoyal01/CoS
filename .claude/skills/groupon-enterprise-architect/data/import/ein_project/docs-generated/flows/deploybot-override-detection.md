---
service: "ein_project"
title: "DeployBot Override Detection"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "deploybot-override-detection"
flow_type: event-driven
trigger: "Incoming change request to POST /api/changes/ with an override flag set by DeployBot"
participants:
  - "continuumProdcatProxy"
  - "continuumProdcatWebApp"
  - "continuumProdcatPostgres"
  - "googleChatSystem_unk_e5f6"
architecture_ref: "dynamic-change-request"
---

# DeployBot Override Detection

## Summary

The DeployBot override detection flow is a branch within the change request creation flow. When deployment tooling submits a change request with an override flag — indicating that a human has instructed DeployBot to bypass normal approval gates — ProdCat detects this condition, records the override in the change log with full attribution, and dispatches a stakeholder notification to Google Chat. The deployment may be permitted to proceed (depending on policy configuration), but the override is permanently audited. This flow enforces accountability for out-of-band deployments during freeze windows or active region locks.

## Trigger

- **Type**: event-driven (specialized case of an api-call)
- **Source**: DeployBot or CI pipeline submits `POST /api/changes/` with an override flag in the request payload
- **Frequency**: On-demand; expected to be infrequent; each occurrence is a notable compliance event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Nginx Proxy | Receives inbound HTTP and forwards to web app | `continuumProdcatProxy` |
| ProdCat Web App | Detects override flag, runs policy check, records audit entry | `continuumProdcatWebApp` |
| REST API component | Receives request and routes override detection logic | `apiController` |
| Auth Service | Authenticates the submitting system and user identity | `einProject_authService` |
| Validation Engine | Identifies override flag; records attributed override event | `validationEngine` |
| Policy Service | Determines whether the override is permissible under current policy | `policyService` |
| Data Access | Writes the override-flagged change record and audit entry to PostgreSQL | `einProject_dataAccess` |
| Google Chat Client | Posts override alert notification to configured stakeholder space | `googleChatClient` |
| PostgreSQL | Stores the override-attributed change record | `continuumProdcatPostgres` |

## Steps

1. **Receive change request with override flag**: Nginx proxy forwards the `POST /api/changes/` request (containing override metadata) to the web app.
   - From: `continuumProdcatProxy`
   - To: `continuumProdcatWebApp`
   - Protocol: HTTP

2. **Authenticate caller**: Auth Service validates the submitting system identity (DeployBot service account or user JWT).
   - From: `apiController`
   - To: `einProject_authService`
   - Protocol: direct

3. **Detect override flag**: Validation Engine inspects the change request payload and identifies the override flag along with the attributed actor (user or system that authorized the override).
   - From: `apiController`
   - To: `validationEngine`
   - Protocol: direct

4. **Evaluate override policy**: Policy Service checks whether the override is permissible (e.g., authorized override roles, emergency override policy). Even when permitted, all override details are recorded.
   - From: `validationEngine`
   - To: `policyService`
   - Protocol: direct

5. **Persist override-attributed change record**: Data Access writes the change request record to PostgreSQL with the override flag set, the authorizing actor identity, the original policy block reason, and a timestamp.
   - From: `einProject_dataAccess`
   - To: `continuumProdcatPostgres`
   - Protocol: TCP/SQL

6. **Post override alert notification**: Google Chat Client sends a notification to the configured stakeholder space identifying the override, the service being deployed, the target region, and the authorizing actor.
   - From: `googleChatClient`
   - To: Google Chat (`googleChatSystem_unk_e5f6`)
   - Protocol: REST

7. **Return decision**: REST API returns the change request outcome (approved with override note, or rejected if override policy denies it).
   - From: `apiController`
   - To: DeployBot / CI pipeline
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Override actor identity cannot be resolved | Change request rejected | Deployment blocked; unattributed overrides are not permitted |
| Override not permitted by policy | Change request rejected with specific reason | Deployment blocked; override attempt is still logged |
| PostgreSQL write fails | Request fails with 500 | Override not recorded; deployment blocked (fail closed) |
| Google Chat notification fails | Failure is swallowed | Override proceeds if approved; notification lost — monitor for alert delivery gaps |
| Authentication fails | 401 returned immediately | No override processing performed |

## Sequence Diagram

```
DeployBot -> continuumProdcatProxy: POST /api/changes/ (override_flag=true, actor=<user>)
continuumProdcatProxy -> continuumProdcatWebApp: Forward HTTP request
continuumProdcatWebApp -> einProject_authService: Authenticate caller identity
continuumProdcatWebApp -> validationEngine: Detect override flag and attributed actor
validationEngine -> policyService: Evaluate override permissibility
continuumProdcatWebApp -> continuumProdcatPostgres: Persist override-attributed change record
continuumProdcatWebApp -> GoogleChat: Post override alert notification (googleChatSystem_unk_e5f6)
continuumProdcatWebApp --> continuumProdcatProxy: Approved (with override note) / Rejected
continuumProdcatProxy --> DeployBot: HTTP response
```

## Related

- Architecture dynamic view: `dynamic-change-request`
- Related flows: [Change Request Creation and Approval](change-request-creation-approval.md), [Change Validation Policy Check](change-validation-policy-check.md)
