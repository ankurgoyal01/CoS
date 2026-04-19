---
service: "janus-web-cloud"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message bus. All asynchronous work is performed internally through scheduled Quartz jobs (alert evaluation, replay processing) whose state is persisted in `continuumJanusMetadataMySql`. There are no Kafka, Pub/Sub, RabbitMQ, or SQS integrations.

## Published Events

> Not applicable. Janus Web Cloud does not publish events to any message bus or topic.

## Consumed Events

> Not applicable. Janus Web Cloud does not consume events from any message bus or topic.

## Dead Letter Queues

> Not applicable. No async messaging system is in use.

> This service does not publish or consume async events. Asynchronous workloads are driven by internal Quartz-scheduled jobs persisted to MySQL. See [Flows](flows/index.md) for replay and alert scheduling flows.
