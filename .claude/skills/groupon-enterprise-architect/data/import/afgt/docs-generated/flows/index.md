---
service: "afgt"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for AFGT (Analytics Financial Global Transactions).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Daily AFGT TD Pipeline](daily-afgt-td-pipeline.md) | scheduled | Daily cron `30 6 * * *` UTC via Airflow | Full daily pipeline from upstream precheck through Teradata staging, Hive load, and downstream DAG trigger |
| [Teradata to Hive Data Transfer](teradata-to-hive-transfer.md) | batch | Triggered within `afgt_sb_td` DAG after staging stages complete | Extracts staged Teradata data via Sqoop into the IMA Hive data lake |
| [Upstream Precheck and Cluster Bootstrap](precheck-and-cluster-bootstrap.md) | scheduled | Start of `afgt_sb_td` DAG run | Validates upstream DAG completion, provisions Dataproc cluster, copies secrets, and initializes environment |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The `afgt_sb_td` DAG participates in a broader cross-service daily data flow:

- **Upstream**: `DLY_OGP_FINANCIAL_varRUNDATE_0003` and `go_segmentation` DAGs must complete before AFGT starts (enforced by PythonSensor prechecks)
- **Downstream**: After `hive_load` completes, `rma-gmp-wbr-load` DAG is triggered via `TriggerDagRunOperator`
- **Validation**: Optimus Prime validation job `6497` is triggered in parallel with the Sqoop import step

The architecture dynamic view for this cross-service flow is defined in `architecture/views/dynamics/afgtTdToHiveLoad.dsl` but is currently disabled in federation (references stub-only elements). See [Architecture Context](../architecture-context.md) for the full relationship map.
