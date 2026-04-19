---
service: "AudiencePayloadSpark"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark"]
---

# Events

## Overview

AudiencePayloadSpark is a batch Spark application suite. It does not publish or consume async messages via a message broker (Kafka, RabbitMQ, SQS, Pub/Sub, or similar). All data movement is driven by explicit `spark-submit` invocations triggered by Fabric operational scripts or cron jobs. Data flows are synchronous within each Spark job: Hive reads followed by direct writes to Cassandra, Keyspaces, Bigtable, or Redis.

> This service does not publish or consume async events via a messaging system. No evidence found in codebase.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
