---
service: "partner-service"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Partner Service uses the Groupon shared MBus (JMS/STOMP) for asynchronous messaging via `jtier-messagebus-client`. The `partnerSvc_mbusAndScheduler` component manages both production and consumption of partner workflow events. No inbound event consumers were identified in the inventory; the service publishes workflow events to notify downstream systems of partner state changes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` (partner workflow topics) | Partner Workflow Event | Completion of a partner onboarding or state-transition workflow step | partner ID, workflow stage, status, timestamp |

### Partner Workflow Event Detail

- **Topic**: Partner workflow topics on `messageBus`
- **Trigger**: Completion of a partner onboarding step, mapping reconciliation result, or uptime state change
- **Payload**: Contains partner identifier, workflow stage identifier, status code, and event timestamp; exact schema is defined in the service source
- **Consumers**: Downstream Continuum services monitoring partner state — specific consumers are tracked in the central architecture model
- **Guarantees**: at-least-once (JMS/STOMP with MBus)

## Consumed Events

> No evidence found of explicit MBus topic subscriptions in the federated model. The `partnerSvc_mbusAndScheduler` component is described as both consumer and producer; specific consumed topics were not enumerated in the inventory.

## Dead Letter Queues

> No evidence found. Dead-letter queue configuration is managed by the MBus infrastructure team outside this service's model.
