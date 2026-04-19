---
service: "tronicon-ui"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. No message broker, event bus, Kafka topic, RabbitMQ queue, or similar async messaging integration was identified in the service inventory. Tronicon UI uses Celery (version 3.1.13) for internal async task processing, but there is no evidence of external event publishing or consumption via a shared messaging system.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events via a shared messaging system.
