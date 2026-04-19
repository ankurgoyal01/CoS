---
service: "deals-cluster"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

Deals Cluster does not publish or consume asynchronous events via a message bus (Kafka, RabbitMQ, SQS, or similar). It is a **scheduled batch job** whose sole integration pattern is:

- **Batch input**: Reading files from HDFS and querying Hive/EDW at job execution time.
- **Batch output**: Writing results to PostgreSQL and HDFS at job completion.
- **Metrics emission**: Writing job execution metrics (counters, timers) to InfluxDB synchronously during and after each job run.

There are no event topics, queues, dead-letter queues, or event-driven triggers.

## Published Events

> Not applicable. This service does not publish async events.

## Consumed Events

> Not applicable. This service does not consume async events.

## Dead Letter Queues

> Not applicable. This service does not use message queuing infrastructure.
