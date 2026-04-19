---
service: "ckod-ui"
title: "Keboola Deployment Creation"
generated: "2026-03-03"
type: flow
flow_name: "keboola-deployment-creation"
flow_type: synchronous
trigger: "User submits the Keboola deployment form on the /deployments page"
participants:
  - "ckodUi_webUi"
  - "ckodUi_apiRoutes"
  - "authz"
  - "deploymentOrchestration"
  - "integrationAdapters"
  - "ckodUi_dataAccess"
  - "continuumJiraService"
  - "keboola"
  - "googleChat"
  - "continuumCkodPrimaryMysql"
architecture_ref: "dynamic-deployment-workflow"
---

# Keboola Deployment Creation

## Summary

This flow covers the end-to-end process of creating a tracked Keboola branch deployment from the DataOps UI. A PRE team engineer selects a Keboola project and branch, enters change metadata, and submits the form. The application validates permissions, fetches branch component details from Keboola, creates a JIRA deployment ticket, records the deployment in MySQL, and sends a Google Chat notification. The resulting JIRA ticket ID is returned to the UI.

## Trigger

- **Type**: user-action
- **Source**: Engineer submits the Keboola deployment creation form at `/deployments`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Renders form, collects input, calls API route via RTK Query mutation | `ckodUi_webUi` |
| API Routes | Receives `GET /api/deployments/create/keboola` with query params | `ckodUi_apiRoutes` |
| Authentication and Authorization | Validates `x-grpn-email` header and user team membership | `authz` |
| Deployment Orchestration | Orchestrates Keboola API calls, JIRA ticket creation, DB write, and notification | `deploymentOrchestration` |
| External Integration Adapters | Executes calls to Keboola, JIRA, Google Chat | `integrationAdapters` |
| Data Access Layer | Writes `ckod_deployment_tracker` and `KEBOOLA_DEPLOYMENT_CONFIG` records | `ckodUi_dataAccess` |
| Jira Cloud | Receives ticket creation request | `continuumJiraService` |
| Keboola Storage API | Returns branch component configuration data | `keboola` |
| Google Chat | Receives deployment notification webhook | `googleChat` |
| CKOD Primary MySQL | Stores deployment tracker and config records | `continuumCkodPrimaryMysql` |

## Steps

1. **Collect form input**: Engineer fills in project ID, branch ID, change title, description, deployer email, configuration IDs, and email list on the `/deployments` page.
   - From: `ckodUi_webUi`
   - To: `ckodUi_webUi` (local state)
   - Protocol: Client-side React state

2. **Submit deployment request**: Web UI calls `POST /api/deployments/create/keboola` (implemented as `GET` with query params via RTK Query mutation) with all form fields encoded as query parameters.
   - From: `ckodUi_webUi`
   - To: `ckodUi_apiRoutes`
   - Protocol: REST (internal Next.js route)

3. **Validate identity and permissions**: API route extracts `x-grpn-email` header and verifies the user belongs to an authorised team via MySQL team membership lookup.
   - From: `ckodUi_apiRoutes`
   - To: `authz`
   - Protocol: Direct TypeScript module call

4. **Fetch branch deployment details**: Deployment orchestration calls the Keboola Storage API to retrieve component and configuration details for the specified project and branch.
   - From: `deploymentOrchestration` via `integrationAdapters` (`keboola-client.ts`)
   - To: `keboola`
   - Protocol: HTTPS REST

5. **Create JIRA deployment ticket**: Creates a JIRA ticket capturing the change title, description, deployer, and configuration details. Returns a JIRA ticket key (e.g., `PRE-XXXX`).
   - From: `deploymentOrchestration` via `integrationAdapters` (`jira-client.ts`)
   - To: `continuumJiraService`
   - Protocol: HTTPS REST

6. **Record deployment in MySQL**: Writes a `ckod_deployment_tracker` row with the JIRA ticket ID as primary key, and one or more `KEBOOLA_DEPLOYMENT_CONFIG` rows for each changed component.
   - From: `deploymentOrchestration` via `ckodUi_dataAccess`
   - To: `continuumCkodPrimaryMysql`
   - Protocol: Prisma / MySQL

7. **Send Google Chat notification**: Posts a deployment notification card to the configured Google Chat space with deployment summary details.
   - From: `deploymentOrchestration` via `integrationAdapters` (`google-chat-client.ts`)
   - To: `googleChat`
   - Protocol: HTTPS Webhook POST

8. **Return result to UI**: API route returns the JIRA ticket key and deployment status to the Web UI. RTK Query cache is refreshed and the UI shows a success toast.
   - From: `ckodUi_apiRoutes`
   - To: `ckodUi_webUi`
   - Protocol: REST (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not in authorised team | Returns HTTP 403 | UI shows "Access Denied" toast; no JIRA ticket created |
| Keboola API returns error | Deployment orchestration propagates error | API returns HTTP 500; UI shows error toast; no JIRA ticket or DB record created |
| JIRA ticket creation fails | Deployment orchestration propagates error | API returns HTTP 500; UI shows error toast; no DB record created |
| MySQL write fails | Prisma error propagated | API returns HTTP 500; JIRA ticket may have been created (orphaned) |
| Google Chat notification fails | Error logged but not propagated | Deployment succeeds; engineer notified via toast that notification failed |

## Sequence Diagram

```
Web UI -> API Routes: GET /api/deployments/create/keboola?requester=...&project_id=...&branch_id=...
API Routes -> authz: Validate x-grpn-email and team membership
authz --> API Routes: Authorised
API Routes -> deploymentOrchestration: Build deployment request
deploymentOrchestration -> keboola: GET /branch/{branchId}/components
keboola --> deploymentOrchestration: Branch component details
deploymentOrchestration -> continuumJiraService: POST /issue (create deployment ticket)
continuumJiraService --> deploymentOrchestration: Ticket key (PRE-XXXX)
deploymentOrchestration -> continuumCkodPrimaryMysql: INSERT ckod_deployment_tracker + KEBOOLA_DEPLOYMENT_CONFIG
continuumCkodPrimaryMysql --> deploymentOrchestration: OK
deploymentOrchestration -> googleChat: POST webhook (deployment notification card)
googleChat --> deploymentOrchestration: 200 OK
deploymentOrchestration --> API Routes: Ticket key + status
API Routes --> Web UI: { data: { ticketKey: "PRE-XXXX" } }
```

## Related

- Architecture dynamic view: `dynamic-deployment-workflow`
- Related flows: [Airflow Pipeline Deployment Creation](airflow-deployment-creation.md)
- See [Integrations](../integrations.md) for Keboola and JIRA client details
