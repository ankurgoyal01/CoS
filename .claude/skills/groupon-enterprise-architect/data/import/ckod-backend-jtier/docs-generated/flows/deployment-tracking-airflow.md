---
service: "ckod-backend-jtier"
title: "Deployment Tracking — Airflow"
generated: "2026-03-03"
type: flow
flow_name: "deployment-tracking-airflow"
flow_type: synchronous
trigger: "HTTP GET /deployments/create/airflow"
participants:
  - "continuumCkodBackendJtier"
  - "continuumJiraService"
  - "googleChat"
  - "continuumCkodMySql"
architecture_ref: "dynamic-ckod-deployment-tracking-flow"
---

# Deployment Tracking — Airflow

## Summary

When an Airflow DAG deployment is initiated, a caller invokes `GET /deployments/create/airflow` with deployment context, developer list, and environment information. CKOD creates a Jira GPROD deployment ticket (using the Airflow-specific ticket configuration), sends a Google Chat notification, and persists the deployment tracking record to MySQL. This flow mirrors the Keboola deployment tracking flow but is tailored for Airflow pipeline deployments, which do not have an associated Keboola branch or Deploybot diff.

## Trigger

- **Type**: api-call
- **Source**: Airflow DAG or deployment automation sends `GET /deployments/create/airflow`
- **Frequency**: On-demand (per Airflow deployment event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CKOD API Resource (`DeploymentResource`) | Receives request and delegates to service layer | `continuumCkodBackendJtier` |
| CKOD Domain Service (`JiraTicketService`) | Orchestrates ticket creation, notification, and persistence | `continuumCkodBackendJtier` |
| CKOD Integration Client (`HttpClient`) | Executes outbound HTTPS calls | `continuumCkodBackendJtier` |
| Jira Cloud | Creates the GPROD deployment issue using `JiraAirflowDeploymentTicketConfig` | `continuumJiraService` |
| Google Chat | Receives deployment notification | `googleChat` |
| CKOD MySQL | Stores deployment tracker record | `continuumCkodMySql` |

## Steps

1. **Receive deployment request**: API Resource receives `GET /deployments/create/airflow` with query parameters: `testing_ticket_id`, `asana_id`, `change_description`, `financial_reporting_impact`, `developers`, `environment`, `development_ticket_id`, `deploybot_url`, `email_list`, `labels`. The caller's email is extracted from `X-GRPN-Email` header.
   - From: Caller
   - To: `continuumCkodApiResources`
   - Protocol: REST

2. **Build Airflow ticket payload**: Constructs the Jira issue payload using `JiraAirflowDeploymentTicketConfig`, including change description, financial reporting impact, environment, developers, and testing ticket reference.
   - From: `continuumCkodDomainServices`
   - To: (internal)
   - Protocol: Direct (in-process)

3. **Create Jira deployment ticket**: Posts to `{jiraServer}/rest/api/2/issue` with the Airflow-specific GPROD ticket payload.
   - From: `continuumCkodIntegrationClients`
   - To: `continuumJiraService`
   - Protocol: HTTPS/REST

4. **Link Jira tickets**: If a context ticket or development ticket is provided, creates issue links via `POST {jiraServer}/rest/api/2/issueLink`.
   - From: `continuumCkodIntegrationClients`
   - To: `continuumJiraService`
   - Protocol: HTTPS/REST

5. **Send Google Chat notification**: Posts a structured JSON message to the configured webhook URL to notify stakeholders.
   - From: `continuumCkodIntegrationClients`
   - To: `googleChat`
   - Protocol: HTTPS/REST (webhook POST)

6. **Persist deployment tracker record**: Writes a new `ckod_deployment_tracker` row to MySQL.
   - From: `continuumCkodDomainServices`
   - To: `continuumCkodMySql`
   - Protocol: JDBC/MySQL

7. **Return response**: Returns the created Jira ticket key to the caller.
   - From: `continuumCkodApiResources`
   - To: Caller
   - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira ticket creation fails (non-2xx) | `JiraTicketResp.created = false` | Ticket not created; response signals failure to caller |
| Google Chat notification fails | `IOException` thrown | Notification lost; ticket creation may still succeed depending on execution order |
| MySQL persistence fails | Exception propagated | Tracker record not persisted; caller must retry |

## Sequence Diagram

```
Caller -> DeploymentResource: GET /deployments/create/airflow
DeploymentResource -> JiraTicketService: createAirflowDeploymentTicket(...)
JiraTicketService -> continuumJiraService: POST /rest/api/2/issue (Airflow config)
continuumJiraService --> JiraTicketService: ticket key
JiraTicketService -> continuumJiraService: POST /rest/api/2/issueLink (if context ticket set)
JiraTicketService -> googleChat: POST webhook (notification)
JiraTicketService -> continuumCkodMySql: INSERT ckod_deployment_tracker
DeploymentResource --> Caller: ticket key
```

## Related

- Architecture dynamic view: `dynamic-ckod-deployment-tracking-flow`
- Related flows: [Deployment Tracking — Keboola](deployment-tracking-keboola.md), [SOX Compliance Check](sox-compliance-check.md)
