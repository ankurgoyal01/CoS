---
service: "pre_task_tracker"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["mbus", "jsm"]
---

# Events

## Overview

`pre_task_tracker` does not publish or consume messages from a traditional message broker (Kafka, RabbitMQ, SQS). However, it monitors MBUS (Groupon's internal message bus) queue backlogs via the Grafana/Prometheus API and triggers downstream Airflow DAGs when backlog thresholds are exceeded. It also fires JSM alert events (create/resolve) to Atlassian Jira Service Management as its primary operational output mechanism.

## Published Events

The service publishes JSM operational alerts rather than traditional async message topics. These are fire-and-forget HTTP calls to the Atlassian JSM API.

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| JSM Alerts API | `FAILED` | Airflow task found in `failed` state | `dag_id`, `task_id`, `run_id`, `execution_date`, `operator`, `try_number` |
| JSM Alerts API | `Long Running` | Airflow task runtime exceeds SLA threshold | `dag_id`, `task_id`, `run_id`, `execution_date`, `operator`, `try_number` |
| JSM Alerts API | `Skip Sequence` | DAG has >= 5 consecutive runs where all-but-two tasks are skipped | `dag_id`, `run_id`, `execution_date` |
| JSM Alerts API | `Queued` | DAG or task has been in QUEUED state longer than `queue_threshold` minutes | `dag_id`, `task_id`, `run_id`, `execution_date`, `operator` |
| JSM Alerts API | `Megatron EOD` | Megatron table has not completed load by configured `eod_time` | `service_name`, `table_name`, `load_type`, `schema_name`, `content_group`, `delay_threshold` |
| JSM Alerts API | `Megatron Lag` | Megatron table data lag exceeds configured `delay_threshold` (hours) | `service_name`, `table_name`, `load_type`, `schema_name`, `content_group`, `delay_threshold` |
| JSM Alerts API | `DATAPROC-LONG-RUNNING` | Dataproc cluster running longer than 8 hours | `ClusterName`, `Project`, `StartTime`, `DAG_ID`, `Composer` |
| JSM Alerts API | `DATAPROC-IDLE` | Dataproc cluster idle (no jobs) for longer than 1 hour | `ClusterName`, `Project`, `StartTime`, `DAG_ID`, `Composer` |
| JSM Alerts API | `MAGNETO - Teradata Table Delay` | Teradata table `consistent_before_hard` timestamp has exceeded delay limit | `Table Name`, `Schema Name`, `Consistent Before Hard`, `Delay Duration`, `EOD Jobs` |

### Alert Resolution Events

The service also publishes resolution events to JSM when conditions clear:

| Resolution Trigger | Condition |
|-------------------|-----------|
| Task moved to `success` or `skipped` state | Closes `FAILED` or `Long Running` JSM alert |
| DAG run reached `success` state | Closes associated open JSM alert |
| DAG no longer in skip sequence | Closes `Skip Sequence` Jira logbook ticket |
| Queued DAG/task started running | Closes `Queued` Jira logbook ticket |
| Megatron table caught up | Closes `Megatron EOD` or `Megatron Lag` JSM alert |
| Dataproc cluster no longer long-running or idle | Closes `DATAPROC-LONG-RUNNING` or `DATAPROC-IDLE` JSM alert |

## Consumed Events

### MBUS Backlog Monitoring (Indirect Consumption)

The `mbus_backlog_monitor` DAG does not subscribe to MBUS topics directly. It polls backlog message counts from Prometheus (via Grafana proxy) for the following monitored MBUS addresses:

| Topic / Queue | Threshold | Downstream DAG Triggered |
|---------------|-----------|--------------------------|
| `jms.topic.salesforce.address.delete` | 10,000 | `HLY_MBUS_SF_ADDRESS_DEL_varPARTITION_ID1` |
| `jms.topic.salesforce.opportunity.delete` | 10,000 | `HLY_WF_MBUS_SF_OPPORTUNITY_DEL_varPARTITION_ID1_02` |
| `jms.topic.salesforce.case.delete` | 10,000 | `HLY_WF_MBUS_SF_CASE_DEL_varPARTITION_ID1_02` |
| `jms.topic.InventoryProducts.Created.Goods_Emea` | 10,000 | `HLY_EXTRACT_GIS_INV_PRODUCTS_varPARTITION_ID_104` |
| `jms.topic.InventoryProducts.Created.Goods` | 10,000 | `HLY_EXTRACT_GIS_INV_PRODUCTS_varPARTITION_ID_104` |
| `jms.topic.InventoryProducts.Updated.Goods` | 10,000 | `HLY_EXTRACT_GIS_INV_PRODUCTS_varPARTITION_ID_104` |
| `jms.topic.InventoryProducts.Updated.Goods_Emea` | 10,000 | `HLY_EXTRACT_GIS_INV_PRODUCTS_varPARTITION_ID_104` |
| `jms.topic.placeservice_iud_notification_production` | 10,000 | `HLY_UNITY_TD_DIM_PLACES_021018` |
| `jms.topic.glive.purchases` | 10,000 | `HLY_GLIVE_PURCHASE_GDOOP_SOX_varPARTITION_ID1_150202` |
| `jms.topic.salesforce.task.delete` | 10,000 | `HLY_WF_MBUS_SF_TASK_DEL_varPARTITION_ID1_02` |
| `jms.topic.gdpr.account.v1.erased` | 10,000 | `hly_gdpr_rtf_requests_varpartition_id1` |
| `jms.topic.gdpr.account.v1.erased.emea` | 10,000 | `hly_gdpr_rtf_requests_varpartition_id1` |
| `jms.topic.division_updates` | 10,000 | `HLY_EXT_MBUS_DEALS_varPARTITION_ID1_40` |
| `jms.topic.dealCatalog.deals.v1.update` | 10,000 | `HLY_EXT_MBUS_DEALS_varPARTITION_ID1_40` |
| `jms.topic.inventory.v1.constraintsChanged` | 10,000 | `HLY_EXT_MBUS_DEALS_varPARTITION_ID1_40` |
| `jms.topic.inventory.v1.productChanged` | 10,000 | `HLY_EXT_MBUS_DEALS_varPARTITION_ID1_40` |
| `jms.topic.dealCatalog.deals.v1.paused` | 10,000 | `HLY_EXT_MBUS_DEALS_PAUSED_UNPAUSED_varPARTITION_ID1_406` |
| `jms.topic.dealCatalog.deals.v1.unpaused` | 10,000 | `HLY_EXT_MBUS_DEALS_PAUSED_UNPAUSED_varPARTITION_ID1_406` |
| `jms.topic.identity_service.identity.v1.c2.event` | 10,000 | `WF_HLY_USERS_EXT_MBUS_varPARTITION_ID_001246810121416182023` |

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is used by this service.
