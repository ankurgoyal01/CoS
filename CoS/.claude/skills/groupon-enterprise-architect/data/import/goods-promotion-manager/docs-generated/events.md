---
service: "goods-promotion-manager"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Goods Promotion Manager does not use an asynchronous messaging system (e.g., Kafka, RabbitMQ, or SQS). All inter-service communication is synchronous via REST. Background work is handled internally by Quartz scheduled jobs (polling/import model) rather than event-driven consumption.

## Published Events

> No evidence found in codebase. This service does not publish events to any message bus or topic.

## Consumed Events

> No evidence found in codebase. This service does not consume events from any message bus or topic.

## Dead Letter Queues

> Not applicable. No messaging system is in use.
