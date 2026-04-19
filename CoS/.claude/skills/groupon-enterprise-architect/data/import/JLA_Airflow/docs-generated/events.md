---
service: "JLA_Airflow"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

JLA Airflow does not use a message broker (Kafka, RabbitMQ, SQS, or Pub/Sub) for async event-driven communication. Inter-DAG coordination is achieved through Airflow's `TriggerDagRunOperator` (which chains the ETL steps 1–8.1 sequentially) and XCom for within-DAG state passing. Operational notifications are pushed to Google Chat webhooks by the Alerting Adapter component.

## Published Events

> This service does not publish async events to a message broker. Inter-DAG triggers use `TriggerDagRunOperator` and are internal to Airflow.

### Google Chat Operational Notifications

Although not async events in the messaging sense, the following notification types are sent via Google Chat webhooks:

| Destination | Notification Type | Trigger | Key Payload Fields |
|-------------|------------------|---------|-------------------|
| `gchat_spaces` (ENGINEERING_ALERTS) | DAG failure alert | `on_failure_callback` in any DAG | DAG ID, task ID, log URL |
| `gchat_spaces` (ENGINEERING_ALERTS) | EBA missing rulesets alert | `jla-eba-rules-exec` status check | rule count, process ID |
| `gchat_spaces` (JLA_ALERTS) | EBA summary | Successful EBA rules execution | process ID, journal entry total, rule count |
| `gchat_spaces` (STAKEHOLDER_ALERTS) | Customer sync summary | Successful `jla-pipeline-customers` run | count inserted, count updated, process date |
| `gchat_spaces` (ENGINEERING_ALERTS) | Customer sync detail/variance | Customer variance or error detected | counts, error list, log URL |
| `gchat_spaces` (ENGINEERING_ALERTS) | DB Watchman alert | DB Watchman configurable check fires | alert name, description, message |

## Consumed Events

> This service does not consume events from a message broker. DAG triggers are schedule-based (cron) or manual.

### Airflow Dataset Trigger

The Adyen PSP DAG publishes to an internal Airflow `Dataset('Adyen')` upon completion, which can trigger downstream dataset-aware DAGs within the same Airflow environment.

| Dataset | Producer DAG | Consumer Impact |
|---------|-------------|-----------------|
| `airflow.datasets.Dataset('Adyen')` | Adyen PSP DAG | Signals Adyen settlement data readiness to downstream dataset-aware DAGs |

## Dead Letter Queues

> No evidence found in codebase. This service does not use message broker DLQs.
