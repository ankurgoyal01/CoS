---
service: "mobile-logging-v2"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Mobile Logging V2.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Mobile Log Ingestion](mobile-log-ingestion.md) | synchronous | `POST /v2/mobile/logs` from iOS/Android client | Accepts, decodes, normalises, and publishes a batch of GRP telemetry events to Kafka |
| [MessagePack Decode and Event Normalisation](messagepack-decode-normalisation.md) | synchronous | Raw client payload submitted by Ingress API | Unpacks MessagePack binary, maps client header and event fields, filters invalid events |
| [Kafka Event Publish](kafka-event-publish.md) | asynchronous | Encoded event payload from Event Encoding Component | Selects producer, applies TLS, and sends encoded event to `mobile_tracking` Kafka topic |
| [GRP5 Checkout Event Processing](grp5-checkout-event-processing.md) | synchronous | GRP5 event row within a decoded log payload | Extracts purchase outcome and payment method from the checkout event and emits detailed metrics |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The `dynamic-mobile-log-ingestion` view in the Structurizr architecture model (`continuumSystem`) documents the cross-service ingestion flow from `continuumMobileLoggingService` to `messageBus`, `metricsStack`, and `loggingStack`. See [Architecture Context](../architecture-context.md) for the component-level breakdown.
