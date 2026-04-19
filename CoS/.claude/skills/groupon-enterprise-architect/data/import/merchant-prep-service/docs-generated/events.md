---
service: "merchant-prep-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The Merchant Preparation Service publishes asynchronous events to the internal JTier Message Bus (MBUS). The `MbusConfiguration` is loaded from the service YAML configuration file; the destination topic is referred to in the architecture model as `messageBus`. The service uses the `jtier-messagebus-client` library to produce events. No events are consumed from the bus by this service — it is a publisher only.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBUS topic (configured via `mbusConfiguration`) | Merchant setting update | Merchant updates payment info, tax info, billing address, or other account settings | Salesforce account ID, updated field values |

### Merchant Setting Update Detail

- **Topic**: Configured via `mbusConfiguration` in the JTier YAML config file (topic name is an environment-level configuration value, not hardcoded in source).
- **Trigger**: A merchant submits a change to payment info, tax info, billing address, company type, or other prep-workflow fields via the REST API and the service persists the change successfully.
- **Payload**: Contains merchant account identifiers (Salesforce account ID) and updated setting values. Exact schema is defined by the `jtier-messagebus-client` message contract.
- **Consumers**: Other Continuum services that need to react to merchant data changes (not discoverable from this repository — tracked in the central architecture model).
- **Guarantees**: at-least-once (standard JTier MBUS delivery semantics).

## Consumed Events

> No evidence found in codebase. This service does not subscribe to any message bus topics; it is a REST-driven, producer-only participant in the async messaging layer.

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration, if any, is managed at the MBUS infrastructure level.
