---
service: "pull"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

Pull does not publish or consume asynchronous events. All interactions are synchronous request/response over REST/HTTPS. The service is stateless and does not participate in any message bus, Kafka topic, SQS queue, or similar async messaging infrastructure.

Telemetry data (metrics, traces) is emitted synchronously per-request via `pullTelemetryPublisher` using `itier-instrumentation` — this is observability emission, not event-driven messaging.

## Published Events

> Not applicable. This service does not publish async events.

## Consumed Events

> Not applicable. This service does not consume async events.

## Dead Letter Queues

> Not applicable. No async messaging is used.
