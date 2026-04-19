---
service: "ckod-ui"
title: "Airflow Pipeline Deployment Creation"
generated: "2026-03-03"
type: flow
flow_name: "airflow-deployment-creation"
flow_type: synchronous
trigger: "User submits the Airflow deployment form on the /deployments page"
participants:
  - "ckodUi_webUi"
  - "ckodUi_apiRoutes"
  - "authz"
  - "deploymentOrchestration"
  - "integrationAdapters"
  - "ckodUi_dataAccess"
  - "continuumJiraService"
  - "googleChat"
  - "continuumCkodPrimaryMysql"
architecture_ref: "dynamic-deployment-workflow"
---

# Airflow Pipeline Deployment Creation

## Summary

This flow covers the creation of a tracked Airflow pipeline deployment from the DataOps UI. A PRE team engineer specifies the DAG IDs, environment, Deploybot URL, change description, and SOX compliance flag. The application validates the request, creates a JIRA deployment ticket (and optionally an approval/testing ticket for SOX-scoped changes), records the deployment in MySQL, and sends a Google Chat notification. SOX-scoped deployments require additional compliance tracking.

## Trigger

- **Type**: user-action
- **Source**: Engineer submits the Airflow deployment creation form at `/deployments`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web UI | Renders form, collects input, calls API route via RTK Query mutation | `ckodUi_webUi` |
| API Routes | Receives `GET /api/deployments/create/airflow` with query params | `ckodUi_apiRoutes` |
| Authentication and Authorization | Validates `x-grpn-email` header and user team membership | `authz` |
| Deployment Orchestration | Orchestrates JIRA ticket creation, DB write, and notification | `deploymentOrchestration` |
| External Integration Adapters | Executes calls to JIRA, Google Chat | `integrationAdapters` |
| Data Access Layer | Writes `pipeline_deployment` record | `ckodUi_dataAccess` |
| Jira Cloud | Receives deployment ticket creation request | `continuumJiraService` |
| Google Chat | Receives deployment notification webhook | `googleChat` |
| CKOD Primary MySQL | Stores `pipeline_deployment` record | `continuumCkodPrimaryMysql` |

## Steps

1. **Collect form input**: Engineer fills in DAG ID(s), environment (staging/production), Deploybot URL, change description, development ticket ID, testing ticket ID, developers list, financial reporting impact, and SOX flag on the `/deployments` page.
   - From: `ckodUi_webUi`
   - To: `ckodUi_webUi` (local state)
   - Protocol: Client-side React state

2. **Submit deployment request**: Web UI calls `GET /api/deployments/create/airflow` with all fields as query parameters via RTK Query mutation.
   - From: `ckodUi_webUi`
   - To: `ckodUi_apiRoutes`
   - Protocol: REST (internal Next.js route)

3. **Validate identity and permissions**: API route verifies the `x-grpn-email` user against MySQL team membership.
   - From: `ckodUi_apiRoutes`
   - To: `authz`
   - Protocol: Direct TypeScript module call

4. **Create JIRA deployment ticket**: Creates a JIRA issue capturing the DAG IDs, environment, change description, and developers. Returns a JIRA ticket key.
   - From: `deploymentOrchestration` via `integrationAdapters` (`jira-client.ts`)
   - To: `continuumJiraService`
   - Protocol: HTTPS REST

5. **Create SOX approval/testing tickets (conditional)**: If `is_sox=true`, creates additional JIRA tickets for SOX approval and testing workflows and links them to the primary deployment ticket.
   - From: `deploymentOrchestration` via `integrationAdapters` (`jira-client.ts`)
   - To: `continuumJiraService`
   - Protocol: HTTPS REST

6. **Record deployment in MySQL**: Writes a `pipeline_deployment` row with the JIRA ticket key as primary key, including `dag_id`, `environment`, `is_sox`, `deploybot_url`, `requested_by`, and linked ticket IDs.
   - From: `deploymentOrchestration` via `ckodUi_dataAccess`
   - To: `continuumCkodPrimaryMysql`
   - Protocol: Prisma / MySQL

7. **Send Google Chat notification**: Posts a deployment notification to the configured Google Chat space.
   - From: `deploymentOrchestration` via `integrationAdapters` (`google-chat-client.ts`)
   - To: `googleChat`
   - Protocol: HTTPS Webhook POST

8. **Return result to UI**: API route returns the JIRA ticket key and deployment status. UI shows a success toast.
   - From: `ckodUi_apiRoutes`
   - To: `ckodUi_webUi`
   - Protocol: REST (JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not in authorised team | Returns HTTP 403 | UI shows "Access Denied"; no ticket or record created |
| JIRA ticket creation fails | Error propagated from `jira-client.ts` | HTTP 500 returned; no DB record created |
| SOX ticket creation fails | Error propagated | HTTP 500 returned; primary deployment ticket may be orphaned |
| MySQL write fails | Prisma error propagated | HTTP 500 returned; JIRA ticket may be orphaned |
| Google Chat notification fails | Error logged, not propagated | Deployment succeeds; notification gap noted in logs |

## Sequence Diagram

```
Web UI -> API Routes: GET /api/deployments/create/airflow?requester=...&dag_id=...&environment=...&is_sox=...
API Routes -> authz: Validate x-grpn-email
authz --> API Routes: Authorised
API Routes -> deploymentOrchestration: Build Airflow deployment request
deploymentOrchestration -> continuumJiraService: POST /issue (create deployment ticket)
continuumJiraService --> deploymentOrchestration: Ticket key (PRE-XXXX)
deploymentOrchestration -> continuumJiraService: POST /issue (SOX approval ticket, if is_sox=true)
continuumJiraService --> deploymentOrchestration: SOX ticket key
deploymentOrchestration -> continuumCkodPrimaryMysql: INSERT pipeline_deployment
continuumCkodPrimaryMysql --> deploymentOrchestration: OK
deploymentOrchestration -> googleChat: POST webhook (notification card)
googleChat --> deploymentOrchestration: 200 OK
deploymentOrchestration --> API Routes: Ticket key + status
API Routes --> Web UI: { data: { ticketKey: "PRE-XXXX" } }
```

## Related

- Architecture dynamic view: `dynamic-deployment-workflow`
- Related flows: [Keboola Deployment Creation](keboola-deployment-creation.md)
- See [Data Stores](../data-stores.md) for `pipeline_deployment` schema
