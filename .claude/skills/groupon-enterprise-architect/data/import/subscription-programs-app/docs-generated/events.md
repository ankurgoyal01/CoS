---
service: "subscription-programs-app"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus, killbill-webhook]
---

# Events

## Overview

Subscription Programs App participates in two async messaging patterns. It publishes membership lifecycle events to MBus (Groupon's internal message bus) after state-changing operations. It consumes KillBill billing lifecycle events via a dedicated HTTP webhook endpoint rather than a message bus subscription — KillBill pushes events directly to `POST /select/killbill-event`. The `jtier-messagebus-client` library handles outbound MBus publishing.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.select.MembershipUpdate` | `MembershipUpdate` | Any membership state change (create, cancel, reactivate, payment update) | consumerId, membershipStatus, planId, effectiveDate, changeType |

### MembershipUpdate Detail

- **Topic**: `jms.topic.select.MembershipUpdate`
- **Trigger**: Published after successful membership create, cancel, reactivate, or payment-driven status change
- **Payload**: Includes `consumerId`, `membershipStatus` (ACTIVE, CANCELLED, SUSPENDED), `planId`, `effectiveDate`, `changeType`
- **Consumers**: Downstream Continuum services (e.g., personalization, order services) that gate behavior on Select membership status
- **Guarantees**: at-least-once (JTier MBus default)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| KillBill HTTP webhook (not MBus) | Billing lifecycle events | `POST /select/killbill-event` resource | Updates membership status, triggers reactivation or suspension, may publish `MembershipUpdate` |

### KillBill Billing Event Detail

- **Topic**: Not a message-bus topic — KillBill delivers events via HTTP POST to `/select/killbill-event`
- **Handler**: `selectApi` receives the webhook, delegates to `membershipService` for state transition logic
- **Idempotency**: KillBill may retry webhook delivery; the handler should treat duplicate events idempotently (membership state machine guards re-entrancy)
- **Error handling**: HTTP 200 must be returned to prevent KillBill retry storm; internal failures should be logged and handled asynchronously
- **Processing order**: Unordered (KillBill does not guarantee ordered delivery for concurrent events)

## Dead Letter Queues

> No evidence found of DLQ configuration for MBus publishing. KillBill webhook delivery failures are retried by KillBill itself per its retry policy.
