---
service: "ckod-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for ckod-ui (DataOps).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Keboola Deployment Creation](keboola-deployment-creation.md) | synchronous | User action — engineer submits deployment form | Creates a Keboola branch deployment: validates input, creates JIRA tickets, records deployment in MySQL, notifies via Google Chat |
| [Airflow Pipeline Deployment Creation](airflow-deployment-creation.md) | synchronous | User action — engineer submits Airflow deployment form | Creates an Airflow pipeline deployment: validates input, creates JIRA tickets, records deployment in MySQL, notifies via Google Chat |
| [SLO Dashboard Data Fetch](slo-dashboard-fetch.md) | synchronous | User action — navigates to or refreshes SLO dashboard | Fetches SLO job detail records from MySQL for one or more platforms and renders compliance status in the dashboard |
| [SLO Definition Management](slo-definition-management.md) | synchronous | User action — creates, edits, or deletes an SLO threshold | Reads and writes SLO definition records in MySQL via the SLO management page; writes an audit log entry |
| [Hand It Over Note Generation](hand-it-over-note-generation.md) | synchronous | User action — PRE team member clicks "Generate Notes" | Collects on-call data, JSM alerts, and JIRA issues; generates AI handover notes via LiteLLM; optionally shares to Google Chat |
| [Vertex AI Agent Chat](vertex-ai-agent-chat.md) | synchronous | User action — sends a message in the AI agent chat UI | Creates or reuses a Vertex AI reasoning engine session, sends user message, streams response back to the browser |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The **Keboola Deployment Creation** and **Airflow Pipeline Deployment Creation** flows span `continuumCkodUi`, `continuumJiraService`, `keboola`, `googleChat`, and `continuumCkodPrimaryMysql`. The architecture dynamic view `dynamic-deployment-workflow` documents the internal component interactions.
- The **Hand It Over Note Generation** flow spans `continuumCkodUi`, `jsmOps`, `continuumJiraService`, `extLiteLlm`, and `googleChat`.
