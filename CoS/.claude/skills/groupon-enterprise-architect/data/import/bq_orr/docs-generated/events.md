---
service: "bq_orr"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The BigQuery Orchestration Service (`bq_orr`) does not publish or consume asynchronous messages through any message broker. It is a DAG deployment package whose runtime behaviour is driven entirely by the Apache Airflow scheduler in the shared Google Cloud Composer environment. Scheduling, retries, and task notifications are all managed internally by Airflow, not by an external messaging system.

## Published Events

> No evidence found in codebase.

This service does not publish events to any topic or queue.

## Consumed Events

> No evidence found in codebase.

This service does not consume events from any topic or queue. DAG execution is triggered by Airflow's built-in scheduler based on the `schedule_interval` defined in each DAG file.

## Dead Letter Queues

> Not applicable

No dead letter queues are configured. Airflow's native retry mechanism (`retries: 1`, `retry_delay: 5 minutes`) handles transient task failures within each DAG.

> This service does not publish or consume async events. All scheduling is handled by the Apache Airflow scheduler in Cloud Composer.
