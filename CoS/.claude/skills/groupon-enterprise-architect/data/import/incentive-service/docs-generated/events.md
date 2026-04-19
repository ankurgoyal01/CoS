---
service: "incentive-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

The Incentive Service participates in two async messaging systems: Apache Kafka (via Alpakka Kafka) for high-throughput event streams and MBus/STOMP for order and user population events. The `incentiveMessaging` component handles all consumers and producers, and is only active when `SERVICE_MODE=messaging`. The service both publishes outcomes of incentive operations and consumes upstream lifecycle events to drive state changes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Kafka | `incentive.redeemed` | Successful promo code redemption | order ID, incentive ID, user ID, discount amount |
| Kafka | `audience.qualified` | Audience qualification sweep completes | campaign ID, qualified user count, sweep timestamp |
| MBus | `campaign.status_changed` | Campaign transitions state (pending → active → expired) | campaign ID, previous state, new state, timestamp |

### `incentive.redeemed` Detail

- **Topic**: Kafka (topic name managed by `continuumKafkaBroker`)
- **Trigger**: Successful completion of the incentive redemption flow following an `order.confirmed` event
- **Payload**: order ID, incentive ID, user ID, discount amount applied, redemption timestamp
- **Consumers**: Downstream analytics and reporting systems; email automation coordination
- **Guarantees**: at-least-once

### `audience.qualified` Detail

- **Topic**: Kafka (topic name managed by `continuumKafkaBroker`)
- **Trigger**: Akka actor job completes an audience qualification sweep for a campaign
- **Payload**: campaign ID, list or count of qualified users, sweep completion timestamp
- **Consumers**: `continuumMessagingService` (to activate campaign delivery); analytics systems
- **Guarantees**: at-least-once

### `campaign.status_changed` Detail

- **Topic**: MBus (STOMP destination managed by `messageBus`)
- **Trigger**: Campaign state transitions — on approval workflow completion, quota exhaustion, or expiry
- **Payload**: campaign ID, previous state, new state, transition timestamp
- **Consumers**: `continuumMessagingService`; downstream campaign management systems
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus | `order.confirmed` | `incentiveMessaging` | Marks redemption in Cassandra, updates quota in PostgreSQL, publishes `incentive.redeemed` |
| MBus | `user.population_update` | `incentiveMessaging` | Updates user audience membership used in qualification sweeps |
| Kafka (via RAAS stub) | `campaign.state_change` | `incentiveMessaging` | Triggers incentive state sync with upstream campaign state |

### `order.confirmed` Detail

- **Topic**: MBus/STOMP
- **Handler**: `incentiveMessaging` consumer validates order contains an incentive, then drives the [Incentive Redemption Flow](flows/incentive-redemption.md)
- **Idempotency**: Redemption record in Cassandra is keyed by order ID + incentive ID; duplicate events do not create duplicate redemptions
- **Error handling**: Failed processing is retried; persistent failures are logged for manual review
- **Processing order**: unordered

### `user.population_update` Detail

- **Topic**: MBus/STOMP
- **Handler**: `incentiveMessaging` updates user audience membership data used by qualification sweeps in batch mode
- **Idempotency**: Membership state is overwritten on each update; replays are safe
- **Error handling**: Failed updates are retried; stale membership data degrades qualification accuracy but does not cause data loss
- **Processing order**: unordered

### `campaign.state_change` Detail

- **Topic**: Kafka (sourced from RAAS — stub only: `extRaas_276f` not in federated model)
- **Handler**: `incentiveMessaging` syncs internal incentive state with the upstream campaign state signal
- **Idempotency**: State transitions are idempotent for equal target states
- **Error handling**: Retry with backoff; alert on persistent failure
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration is not defined in the service inventory.
