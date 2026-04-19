---
service: "audienceDerivationSpark"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found

Audience Derivation Spark does not publish or consume asynchronous events via a message broker (Kafka, RabbitMQ, SQS, etc.). The service is a scheduled batch pipeline. Job submission is driven by cron-scheduled `spark-submit` invocations. Communication with downstream systems occurs via direct Hive/HDFS writes, Cassandra connector writes (via the `audiencepayloadspark` library), and Bigtable payload uploads — all of which are synchronous I/O operations within the Spark job execution.

## Published Events

> This service does not publish async events.

## Consumed Events

> This service does not consume async events.

## Dead Letter Queues

> Not applicable — no message queues are used by this service.
