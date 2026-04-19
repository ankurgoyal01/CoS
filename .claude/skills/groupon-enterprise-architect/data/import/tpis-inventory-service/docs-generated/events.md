---
service: "tpis-inventory-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

No asynchronous messaging patterns (Kafka, ActiveMQ, SQS, or similar) are currently defined in the architecture DSL for the Third Party Inventory Service. The service's known integrations are all synchronous HTTP-based.

Given the service's role in managing partner inventory events and its database named for "tpis events inventory data," it is likely that the service does handle event-driven patterns (e.g., partner inventory change notifications, availability update events). Service owners should document any async messaging here.

## Published Events

No published events are currently defined in the architecture DSL.

> Service owners should document any events published by TPIS, including inventory status change events, partner synchronization events, or availability update notifications.

## Consumed Events

No consumed events are currently defined in the architecture DSL.

> Service owners should document any events consumed from partner systems or internal Continuum services.

## Dead Letter Queues

No DLQ configuration is discoverable from the architecture DSL.

> If no async messaging is used, note: "This service does not publish or consume async events." Otherwise, service owners should document the event topology here.
