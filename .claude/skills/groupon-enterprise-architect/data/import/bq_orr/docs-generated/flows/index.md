---
service: "bq_orr"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for the BigQuery Orchestration Service (`bq_orr`).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [DAG Deployment Flow](dag-deployment.md) | batch | Jenkins CI/CD pipeline push | Packages and promotes DAG artifact files from the repository through dev, staging, and production Cloud Composer environments via `deploybot_gcs` |
| [DAG Scheduled Execution Flow](dag-scheduled-execution.md) | scheduled | Airflow scheduler (daily) | Cloud Composer picks up deployed DAG files and executes scheduled tasks against Google BigQuery on a daily schedule |
| [Production Promotion and Approval Flow](production-promotion.md) | batch | Manual approval after successful staging deployment | Gated promotion of DAG artifacts from the staging Composer environment to production, requiring explicit human approval |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The DAG deployment flow spans `continuumBigQueryOrchestration` (this service) and the `preGcpComposerRuntime` shared Cloud Composer environment. The execution flow spans `preGcpComposerRuntime` and `bigQuery`. These cross-service interactions are captured in the architecture dynamic view `dynamic-bq-orr-bqOrr_shankarTestDag-deploy`.

See [Architecture Context](../architecture-context.md) for Structurizr diagram references.
