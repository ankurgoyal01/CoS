---
service: "mbus-sigint-configuration-v2"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase of async event publishing or consumption via a message broker (MBus, Kafka, SQS, etc.). The service is the configuration control plane for MBus brokers but does not itself produce or consume messages on those brokers.

## Published Events

> No evidence found in codebase. This service does not publish async events to any message bus topic or queue.

## Consumed Events

> No evidence found in codebase. This service does not subscribe to any message bus topic or queue.

## Dead Letter Queues

> No evidence found in codebase. This service configures DLQ settings for other services' destinations via its API (the `redelivery_settings` model includes `hasDedicatedDLQ`), but does not own or use a DLQ itself.

---

> This service does not publish or consume async events. All inter-system communication is synchronous (HTTP REST) or scheduled (Quartz jobs calling outbound REST/SSH).
