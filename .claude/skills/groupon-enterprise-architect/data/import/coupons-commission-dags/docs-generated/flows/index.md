---
service: "coupons-commission-dags"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Coupons Commission DAGs.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Monthly Commission Sourcing](monthly-commission-sourcing.md) | scheduled | Cron `0 2 1 * *` (1st of month, 02:00 UTC) | Sources raw commission data from all affiliate networks for the prior 12-month window |
| [Monthly Commission Transform](monthly-commission-transform.md) | scheduled | Cron `0 4 1 * *` (1st of month, 04:00 UTC) | Transforms sourced commission data into normalized records per network |
| [Monthly Commission Aggregation](monthly-commission-aggregation.md) | scheduled | Cron `0 6 1 * *` (1st of month, 06:00 UTC) | Aggregates normalized commission records into summary reports |
| [Daily Awin Sourcing](daily-awin-sourcing.md) | scheduled | Cron `0 2 * * *` (daily, 02:00 UTC) | Sources Awin affiliate commission data with a 20-day lookback window |
| [Daily Awin Transform](daily-awin-transform.md) | scheduled | Cron `0 4 * * *` (daily, 04:00 UTC) | Transforms daily Awin sourced data into normalized records |
| [Daily Awin Aggregation](daily-awin-aggregation.md) | scheduled | Cron `0 6 * * *` (daily, 06:00 UTC) | Aggregates daily Awin normalized data into summary reports |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

All six flows span the Airflow orchestration layer (`continuumCouponsCommissionDags`) and GCP infrastructure (`gcpDataprocCluster`, `gcpDataprocMetastore`, `grouponArtifactory`). The monthly flows share a common three-stage sequential pattern (sourcing → transform → aggregation), each running as an independent DAG with its own schedule offset to ensure the previous stage completes before the next starts. The daily Awin flows mirror this same three-stage pattern but run every day rather than monthly.

> Architecture dynamic views: No dynamic views are captured for this repository (`views/dynamics.dsl` is empty). The flows are documented here from DAG source code analysis.
