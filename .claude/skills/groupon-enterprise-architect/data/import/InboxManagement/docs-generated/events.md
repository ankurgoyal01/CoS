---
service: "inbox_management_platform"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

InboxManagement is a heavily event-driven service. It consumes multiple Kafka and mbus topics to receive campaign triggers, user profile updates, send errors, and subscription changes. It publishes SendEvents to RocketMan via Kafka to trigger channel delivery, and emits queue depth metrics as operational signals. The `inbox_rocketmanPublisher` component handles all outbound event production; the `inbox_userSyncProcessor` and `inbox_errorListener` handle inbound consumption.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| RocketMan dispatch topic (Kafka) | `SendEvent` | Dispatch scheduler promotes user/event to send-ready state | user_id, campaign_id, channel, send_time, payload |
| Metrics sink | `QueueDepthMetric` | Queue monitor daemon on schedule | queue_name, depth, region, timestamp |

### SendEvent Detail

- **Topic**: RocketMan dispatch Kafka topic
- **Trigger**: `inbox_dispatchScheduler` promotes an eligible dispatch candidate; `inbox_rocketmanPublisher` serializes and produces the event
- **Payload**: user_id, campaign_id, channel type (email/push/SMS), scheduled send time, serialized message payload
- **Consumers**: RocketMan (channel delivery)
- **Guarantees**: at-least-once

### QueueDepthMetric Detail

- **Topic**: Metrics sink (arpnetworking-metrics-client)
- **Trigger**: `inbox_queueMonitor` daemon executes on a polling schedule and emits depth readings for calc and dispatch queues
- **Payload**: queue_name, region, current depth, timestamp
- **Consumers**: Monitoring/alerting infrastructure
- **Guarantees**: at-most-once (metrics loss is acceptable)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Campaign Management topic (Kafka/mbus) | `CampaignSendEvent` | `inbox_coordinationWorker` | Enqueues user-campaign pairs onto calc queue in Redis |
| User profile topic (Kafka) | `UserProfileEvent` | `inbox_userSyncProcessor` | Updates user attribute state in Redis and Postgres |
| Send error topic (Kafka/mbus) | `SendErrorEvent` | `inbox_errorListener` | Records error state in Postgres; triggers retry or suppression logic |
| Subscription topic (Kafka/mbus) | `SubscriptionEvent` | `inbox_subscriptionListener` | Updates subscription/preference state affecting future dispatch eligibility |

### CampaignSendEvent Detail

- **Topic**: Campaign Management Kafka/mbus topic
- **Handler**: `inbox_coordinationWorker` — dequeues, loads campaign metadata via `inbox_campaignManagementClient`, applies CAS arbitration via `inbox_arbitrationClient`, and schedules dispatch
- **Idempotency**: Redis locks per user prevent duplicate processing
- **Error handling**: Failed events are retried; persistent failures written to error state in Postgres
- **Processing order**: unordered (sharded daemon instances process in parallel)

### UserProfileEvent Detail

- **Topic**: User profile Kafka topic
- **Handler**: `inbox_userSyncProcessor` — reads and writes sync state via `inbox_configAndStateAccess`
- **Idempotency**: Last-write-wins on user attribute keys
- **Error handling**: Errors logged; state remains at last known good
- **Processing order**: unordered per user; ordering within a user partition where available

### SendErrorEvent Detail

- **Topic**: Send error Kafka/mbus topic
- **Handler**: `inbox_errorListener` — persists error record to `continuumInboxManagementPostgres` and applies recovery logic
- **Idempotency**: Error records keyed by send_id
- **Error handling**: Dead-letter after configurable retry count
- **Processing order**: unordered

### SubscriptionEvent Detail

- **Topic**: Subscription Kafka/mbus topic
- **Handler**: `inbox_subscriptionListener` — updates subscription preference state affecting whether future dispatch events are eligible
- **Idempotency**: State overwrite per user/channel combination
- **Error handling**: Errors logged; preference state remains at last known good
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found of explicit DLQ configuration in the architecture model. Dead-letter strategy to be confirmed by service owner.
