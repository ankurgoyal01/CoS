---
service: "ckod-backend-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for CKOD Backend JTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Keboola Job Polling](keboola-job-polling.md) | scheduled | Worker background loop | Polls Keboola job queue and persists new and updated job run records to MySQL |
| [Deployment Tracking — Keboola](deployment-tracking-keboola.md) | synchronous | API call to `GET /deployments/create/keboola` | Creates a Jira GPROD ticket, generates a GitHub diff link, and persists a deployment tracker record |
| [Deployment Tracking — Airflow](deployment-tracking-airflow.md) | synchronous | API call to `GET /deployments/create/airflow` | Creates a Jira GPROD ticket for an Airflow deployment and persists a tracking record |
| [SOX Compliance Check](sox-compliance-check.md) | synchronous | API call to `GET /deployments/sox` | Determines whether a deployment pipeline is SOX-scoped by querying the GitHub SOX registry |
| [Cost Alert Query](cost-alert-query.md) | synchronous | API call to `/costAlert/*` endpoints | Reads or writes cost alert configurations and returns KBC telemetry and BQ cost data |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The deployment tracking flows are modelled in the central architecture dynamic view `dynamic-ckod-deployment-tracking-flow`, which spans `continuumCkodBackendJtier`, `githubEnterprise`, `continuumJiraService`, `googleChat`, and `continuumCkodMySql`. See [Architecture Context](../architecture-context.md) for full relationship details.
