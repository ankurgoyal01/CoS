---
service: "giftcard_service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message bus (no Kafka, RabbitMQ, SQS, or Pub/Sub integration was found in the codebase). All inter-service communication is synchronous HTTP. The only background processing is the `ServiceDiscovery` job (SuckerPunch in-process queue) which runs hourly to refresh First Data endpoint URLs — this is an internal scheduled task, not an event-driven integration.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

> This service does not publish or consume async events. All integrations use synchronous HTTP calls. See [Integrations](integrations.md) for the full dependency list.
