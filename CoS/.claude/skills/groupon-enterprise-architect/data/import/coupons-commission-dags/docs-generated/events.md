---
service: "coupons-commission-dags"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

coupons-commission-dags does not publish or consume asynchronous events via any message broker (Kafka, Pub/Sub, SQS, or similar). All pipeline orchestration is schedule-driven via Airflow's internal scheduler. The DAGs interact with GCP Dataproc synchronously through the Airflow Dataproc operators, which block until each task completes.

## Published Events

> Not applicable. This service does not publish async events.

## Consumed Events

> Not applicable. This service does not consume async events.

## Dead Letter Queues

> Not applicable. No message queuing infrastructure is used.
