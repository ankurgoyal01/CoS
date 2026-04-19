---
service: "fraud-arbiter"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Fraud Arbiter participates in async messaging via the Groupon message bus (`mbus`). It consumes order and shipment lifecycle events to trigger fraud evaluations, and publishes fraud decision events so downstream services can react to approve or reject outcomes without polling the API.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `mbus.fraud.decision` | `fraud_decision` | Fraud provider returns a decision (approve/reject/review) for an order | `order_id`, `decision`, `provider`, `reason_codes`, `score`, `timestamp` |

### fraud_decision Detail

- **Topic**: `mbus.fraud.decision`
- **Trigger**: Signifyd or Riskified delivers a webhook with a final or updated fraud decision; Fraud Arbiter validates and persists the decision then publishes this event
- **Payload**: `order_id`, `decision` (approve/reject/review), `provider` (signifyd/riskified), `reason_codes`, `score`, `timestamp`
- **Consumers**: Orders Service (to proceed with or cancel fulfillment), Kill Bill Payments (to authorize or void charges)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `mbus.order.created` | `order_created` | Fraud evaluation initiator | Submits order to fraud provider for review; creates initial fraud review record in MySQL |
| `mbus.shipment.updated` | `shipment_updated` | Fulfillment status notifier | Sends fulfillment status update to fraud provider; updates fraud record |

### order_created Detail

- **Topic**: `mbus.order.created`
- **Handler**: Receives new order event, gathers enrichment data from downstream services (deal catalog, goods inventory, user profile, etc.), and submits the order to the configured fraud provider for evaluation
- **Idempotency**: Fraud review record keyed on `order_id`; duplicate events result in a no-op if review already exists
- **Error handling**: Failed submissions retried via Sidekiq with exponential backoff; persistent failures logged to audit records in MySQL
- **Processing order**: unordered

### shipment_updated Detail

- **Topic**: `mbus.shipment.updated`
- **Handler**: Receives shipment status changes and notifies the fraud provider (Signifyd/Riskified) of fulfillment outcomes so provider risk models are updated
- **Idempotency**: Updates keyed on `order_id` and `shipment_status`
- **Error handling**: Retried via Sidekiq; failures recorded in audit log
- **Processing order**: unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| `mbus.fraud.decision.dlq` | `mbus.fraud.decision` | — | — |

> Retention and alert thresholds are not discoverable from the inventory. Operational procedures to be defined by service owner.
