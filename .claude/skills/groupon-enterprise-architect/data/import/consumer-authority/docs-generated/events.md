---
service: "consumer-authority"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Consumer Authority publishes outbound consumer-attribute events to the Groupon Message Bus (`messageBus`) via the Kafka-backed Holmes publisher. The service does not consume any inbound events; all execution is triggered externally by Airflow and Cerebro Job Submitter rather than by event subscription.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` (consumer-attribute topic) | consumer-attribute event | Completion of daily attribute computation run | Derived consumer attribute signals per user |

### consumer-attribute event Detail

- **Topic**: `messageBus` — consumer-attribute channel (exact topic name managed by Holmes publisher configuration)
- **Trigger**: `cdeExternalPublisher` emits events after `cdeSparkExecutionEngine` provides computed attribute datasets
- **Payload**: Derived consumer attribute signals; specific field schema is managed by the Holmes publisher contract
- **Consumers**: Audience Management Service (`continuumAudienceManagementService`) and downstream marketing and personalization systems
- **Guarantees**: at-least-once (Kafka-backed Holmes publisher delivery semantics)

## Consumed Events

> No evidence found. Consumer Authority does not subscribe to any message bus topics. Job execution is triggered by Airflow schedules and Cerebro job submission, not by inbound events.

## Dead Letter Queues

> No evidence found. Dead-letter queue configuration is not visible in the architecture model.
