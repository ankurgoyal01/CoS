---
service: "bhuvan"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

Bhuvan does not publish or consume asynchronous events. It is a synchronous request/response service. All interactions occur via REST HTTP calls. Log events are forwarded to the central logging stack via a Logstash sidecar container writing to a Kafka topic, but this is observability infrastructure — not domain event messaging.

## Published Events

> No evidence found in codebase.

This service does not publish domain events to any message bus or queue.

## Consumed Events

> No evidence found in codebase.

This service does not consume events from any topic or queue.

## Dead Letter Queues

> No evidence found in codebase.

No dead letter queues are configured for this service.
