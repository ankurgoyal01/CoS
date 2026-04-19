---
service: "ckod-backend-jtier"
title: "Deployment Tracking — Keboola"
generated: "2026-03-03"
type: flow
flow_name: "deployment-tracking-keboola"
flow_type: synchronous
trigger: "HTTP GET /deployments/create/keboola"
participants:
  - "continuumCkodBackendJtier"
  - "githubEnterprise"
  - "continuumJiraService"
  - "googleChat"
  - "continuumCkodMySql"
architecture_ref: "dynamic-ckod-deployment-tracking-flow"
---

# Deployment Tracking — Keboola

## Summary

When a Keboola deployment is initiated, a caller invokes `GET /deployments/create/keboola` with project, branch, and change metadata. CKOD resolves the Keboola branch components, generates a GitHub diff link between staging and production versions, creates a Jira GPROD deployment ticket, sends a Google Chat notification, and persists the full deployment tracking record to MySQL. This flow is the primary mechanism by which data platform deployments are logged and made auditable.

## Trigger

- **Type**: api-call
- **Source**: Caller (Airflow pipeline, data engineer, or deployment automation) sends `GET /deployments/create/keboola`
- **Frequency**: On-demand (per deployment event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CKOD API Resource (`DeploymentResource`) | Receives request and delegates to service layer | `continuumCkodBackendJtier` |
| CKOD Domain Service (`JiraTicketService`, `KeboolaTrackerService`) | Orchestrates ticket creation, diff resolution, notification, and persistence | `continuumCkodBackendJtier` |
| CKOD Integration Client (`HttpClient`) | Executes all outbound HTTPS calls | `continuumCkodBackendJtier` |
| GitHub Enterprise | Provides diff and commit context between base and head SHAs | `githubEnterprise` |
| Jira Cloud | Creates the GPROD deployment issue and issue links | `continuumJiraService` |
| Google Chat | Receives deployment notification | `googleChat` |
| CKOD MySQL | Stores deployment tracker record and configuration snapshot | `continuumCkodMySql` |

## Steps

1. **Receive deployment request**: API Resource receives `GET /deployments/create/keboola` with query parameters: `project_id`, `branch_id`, `change_title`, `description`, `email_list`, `labels`, `configuration_ids`, `asana_id`. The caller's email is extracted from `X-GRPN-Email` header.
   - From: Caller
   - To: `continuumCkodApiResources`
   - Protocol: REST

2. **Resolve Keboola branch components**: Calls `GET https://connection.groupon.keboola.cloud/v2/storage/branch/{branchId}/components` using the project's API token to retrieve the list of components in the deployment branch.
   - From: `continuumCkodIntegrationClients`
   - To: `keboola`
   - Protocol: HTTPS/REST

3. **Fetch deployment metadata from Deploybot**: Calls Deploybot edge proxy (`https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com/v1/last_successful_deployments/{org}/{repo}`) to obtain staging and production version SHAs.
   - From: `continuumCkodIntegrationClients`
   - To: Deploybot
   - Protocol: HTTPS/REST

4. **Generate GitHub diff context**: Using the staging and production SHAs from Deploybot, calls `GET https://api.github.groupondev.com/repos/{org}/{repo}/compare/{base}...{head}` to retrieve commit authors between the two versions.
   - From: `continuumCkodIntegrationClients`
   - To: `githubEnterprise`
   - Protocol: HTTPS/REST

5. **Resolve on-call and account metadata**: Queries Jira JSM schedule API (`https://api.atlassian.com/jsm/ops/api/.../on-calls`) to retrieve the current on-call user; resolves user account IDs via `GET {jiraServer}/rest/api/3/user/search`.
   - From: `continuumCkodIntegrationClients`
   - To: `continuumJiraService`
   - Protocol: HTTPS/REST

6. **Create Jira deployment ticket**: Posts to `{jiraServer}/rest/api/2/issue` with the GPROD project ticket payload including change title, description, requester, on-call, diff authors, and labels.
   - From: `continuumCkodIntegrationClients`
   - To: `continuumJiraService`
   - Protocol: HTTPS/REST

7. **Link Jira tickets**: Creates issue links between the new deployment ticket and any context ticket or action items via `POST {jiraServer}/rest/api/2/issueLink`.
   - From: `continuumCkodIntegrationClients`
   - To: `continuumJiraService`
   - Protocol: HTTPS/REST

8. **Send Google Chat notification**: Posts a structured JSON message to the configured Google Chat webhook URL notifying stakeholders of the deployment.
   - From: `continuumCkodIntegrationClients`
   - To: `googleChat`
   - Protocol: HTTPS/REST (webhook POST)

9. **Persist deployment tracker record**: Writes a new `ckod_deployment_tracker` row and associated `keboola_deployment_config` rows to MySQL via `DataWriteDao` and `KeboolaDeploymentConfigWriteDao`.
   - From: `continuumCkodDomainServices`
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

10. **Return response**: Returns the created Jira ticket key and tracking metadata to the caller.
    - From: `continuumCkodApiResources`
    - To: Caller
    - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Keboola branch resolution fails | `IOException` propagated | Request fails; error returned to caller |
| GitHub diff resolution fails | `IOException` propagated | Request fails; diff authors unavailable |
| Jira ticket creation fails (non-2xx) | `JiraTicketResp.created = false` | Ticket not created; response signals failure to caller |
| Google Chat notification fails | `IOException` thrown but may not block ticket creation depending on service wiring | Notification lost; ticket creation may succeed |
| MySQL persistence fails | Exception propagated | Tracker record not created; caller must retry |

## Sequence Diagram

```
Caller -> DeploymentResource: GET /deployments/create/keboola
DeploymentResource -> KeboolaTrackerService: describeBranch(projectId, branchId)
KeboolaTrackerService -> keboola: GET /v2/storage/branch/{branchId}/components
keboola --> KeboolaTrackerService: component list
DeploymentResource -> JiraTicketService: createKeboolaDeploymentTicket(...)
JiraTicketService -> Deploybot: GET /v1/last_successful_deployments/{org}/{repo}
Deploybot --> JiraTicketService: DeploybotResponseModel (staging/prod SHAs)
JiraTicketService -> githubEnterprise: GET /repos/{org}/{repo}/compare/{base}...{head}
githubEnterprise --> JiraTicketService: commit authors
JiraTicketService -> continuumJiraService: GET on-call schedule
continuumJiraService --> JiraTicketService: on-call user
JiraTicketService -> continuumJiraService: POST /rest/api/2/issue
continuumJiraService --> JiraTicketService: ticket key
JiraTicketService -> continuumJiraService: POST /rest/api/2/issueLink
JiraTicketService -> googleChat: POST webhook (notification)
JiraTicketService -> continuumCkodMySql: INSERT ckod_deployment_tracker
JiraTicketService -> continuumCkodMySql: INSERT keboola_deployment_config
DeploymentResource --> Caller: ticket key + tracking data
```

## Related

- Architecture dynamic view: `dynamic-ckod-deployment-tracking-flow`
- Related flows: [Deployment Tracking — Airflow](deployment-tracking-airflow.md), [SOX Compliance Check](sox-compliance-check.md), [Keboola Job Polling](keboola-job-polling.md)
