---
service: "ein_project"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message broker (no Kafka, RabbitMQ, SQS, or similar). All inter-process communication is HTTP (REST) for synchronous operations and Redis-backed RQ queues for background job dispatch between the web application and the worker process. RQ is an internal implementation detail rather than an event bus — jobs are enqueued by `asyncTaskDispatcher` and consumed by `rqWorker` within the same deployment unit.

## Published Events

> Not applicable

## Consumed Events

> Not applicable

## Dead Letter Queues

> Not applicable

---

> This service does not publish or consume async events via an external message broker. Background work is coordinated via Redis RQ queues internal to the ProdCat deployment. See [Flows](flows/index.md) for RQ job dispatch patterns and [Data Stores](data-stores.md) for the Redis queue configuration.
