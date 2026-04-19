---
service: "regla"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

regla participates in both the Kafka event streaming fabric and the Continuum MessageBus. The stream job (`reglaStreamJob`) consumes high-volume deal-purchase and browse event streams from Kafka and publishes rule evaluation results to two Kafka topics. The service (`reglaService`) consumes MessageBus topics for additional event-driven triggers. All stream processing uses kafka-streams 2.8.2 for the main pipeline and kafka-0.8-thin-client 2.0.16 for publishing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `im_push_regla_delayed_instances_spark` | DelayedRuleInstance | Stream job evaluates a rule with a time-delayed action | rule_id, user_id, instance_id, scheduled_at, action metadata |
| `janus-tier2` | RuleEvaluationResult | Stream job determines a rule has fired for a user | rule_id, user_id, action_type, deal_id, category_id |

### DelayedRuleInstance Detail

- **Topic**: `im_push_regla_delayed_instances_spark`
- **Trigger**: Stream job evaluates a rule whose action requires delayed delivery (e.g., scheduled push notification)
- **Payload**: rule_id, user_id, instance_id, scheduled_at, action metadata
- **Consumers**: Inbox management push scheduling service
- **Guarantees**: at-least-once

### RuleEvaluationResult (janus-tier2) Detail

- **Topic**: `janus-tier2`
- **Trigger**: Stream job fires a rule for a given user based on purchase or browse event
- **Payload**: rule_id, user_id, action_type, deal_id, category_id
- **Consumers**: Janus inbox delivery service (tier-2 routing)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Kafka deal-purchase topic | DealPurchased | `reglaStreamJob` stream consumer | Evaluates active rules against purchase; updates purchase history in Redis and PostgreSQL; may publish to output topics |
| Kafka browse events topic | BrowseEvent | `reglaStreamJob` stream consumer | Evaluates browse-triggered rules; updates rule state in Redis |
| MessageBus topics | Various | `reglaService` mbus-client consumer | Triggers rule evaluations or state updates; exact topic names not specified in inventory |

### DealPurchased Detail

- **Topic**: Kafka deal-purchase topic (exact topic name not specified in inventory)
- **Handler**: `reglaStreamJob` Kafka Streams topology — reads purchase event, checks active rules, updates Redis purchase history, publishes results to `janus-tier2` or `im_push_regla_delayed_instances_spark` as appropriate
- **Idempotency**: Redis deduplication on purchase event key
- **Error handling**: Kafka consumer group offset management; failed records may be retried by seeking offset
- **Processing order**: unordered (partitioned by user_id)

### BrowseEvent Detail

- **Topic**: Kafka browse events topic (exact topic name not specified in inventory)
- **Handler**: `reglaStreamJob` Kafka Streams topology — evaluates browse-triggered rule conditions against Redis state
- **Idempotency**: Rule state in Redis provides deduplication context
- **Error handling**: Kafka offset management; no DLQ evidence found
- **Processing order**: unordered (partitioned by user_id)

## Dead Letter Queues

> No evidence found in codebase for explicit DLQ topic configuration.
