---
service: "airflow_gcp"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The Airflow GCP SFDC ETL service does not use any asynchronous messaging system (Kafka, RabbitMQ, SQS, Pub/Sub, or internal Mbus). All data movement is driven by Apache Airflow's internal task scheduler. DAG task-to-task coordination uses Airflow XCom (in-process state passing) rather than external message queues. Failure notifications are delivered via email to `sfint-dev-alerts@groupon.com` using Airflow's built-in email alerting mechanism.

## Published Events

> This service does not publish any async events to external message topics or queues.

## Consumed Events

> This service does not consume any async events from external message topics or queues.

## Dead Letter Queues

> Not applicable — no messaging system is used.

## Failure Notification Pattern

All DAGs configure email-on-failure via `DEFAULT_ARGS`:

| Mechanism | Recipient | Trigger |
|-----------|-----------|---------|
| Airflow email alert | `sfint-dev-alerts@groupon.com` | Any DAG task failure |

This is not an async event system; it is Airflow's built-in SMTP notification mechanism.
