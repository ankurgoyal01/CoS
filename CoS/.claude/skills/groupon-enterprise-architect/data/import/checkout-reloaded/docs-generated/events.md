---
service: "checkout-reloaded"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

checkout-reloaded does not participate in asynchronous messaging directly. It is a stateless BFF that delegates all event-emitting responsibility to downstream services. Order lifecycle events (order placed, payment confirmed, etc.) are published by the Order Service upon successful order finalization — not by this BFF.

## Published Events

> No evidence found in codebase. This service does not publish any Kafka, MBus, or other async events. Event emission on order completion is owned by the Order Service.

## Consumed Events

> No evidence found in codebase. This service does not consume any Kafka, MBus, or other async event streams. All data is fetched synchronously from downstream services on a per-request basis.

## Dead Letter Queues

> Not applicable — this service does not publish or consume async events.
