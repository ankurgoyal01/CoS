---
service: "orders-ext"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Orders Ext uses the internal MessageBus (STOMP/JMS protocol) to publish one event type: a PayPal billing agreement cancellation notification. The service publishes to a JMS topic when it receives a verified `BILLING_AGREEMENTS.AGREEMENT.CANCELLED` webhook from PayPal. No events are consumed from the message bus; Orders Ext is a pure publisher in the async messaging layer.

Additionally, Orders Ext enqueues background jobs to a Redis-backed Resque queue (`accertify_order_resolution`) for async order resolution processing by an external worker service. This is documented under [Data Stores](data-stores.md) and the [Accertify Order Resolution Flow](flows/accertify-order-resolution.md).

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.BillingRecords.PaypalBillingAgreementEvents` | `PaypalBillingAgreementCancelled` | Verified PayPal `BILLING_AGREEMENTS.AGREEMENT.CANCELLED` webhook received | `billingAgreementID`, `messageType`, `messageVersion`, `identifier`, `creationTime` |

### PaypalBillingAgreementCancelled Detail

- **Topic**: `jms.topic.BillingRecords.PaypalBillingAgreementEvents`
- **Trigger**: A PayPal webhook POST to `/paypal_webhooks` containing event type `BILLING_AGREEMENTS.AGREEMENT.CANCELLED` that passes signature verification
- **Payload**:
  ```json
  {
    "identifier": "<uuid>",
    "messageType": "PaypalBillingAgreementCancelled",
    "messageVersion": 1.0,
    "payloadType": "JSON",
    "creationTime": <unix_ms>,
    "containerVersion": 1,
    "payload": {
      "billingAgreementID": "<billing_agreement_id>"
    }
  }
  ```
- **Consumers**: Billing Records downstream consumers (tracked externally in central architecture model)
- **Guarantees**: at-least-once — the publisher retries up to 5 times with a 200 ms interval on timeout; duplicate delivery is possible

## Consumed Events

> This service does not consume async events from the message bus. It is a pure publisher.

## Dead Letter Queues

> No dead letter queue configuration found in codebase. Failed publish attempts are logged via STENO_LOGGER and a failure response is returned to the PayPal webhook caller.
