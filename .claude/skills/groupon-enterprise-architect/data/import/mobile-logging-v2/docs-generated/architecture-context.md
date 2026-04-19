---
service: "mobile-logging-v2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMobileLoggingService]
---

# Architecture Context

## System Context

Mobile Logging V2 sits within the `continuumSystem` (Groupon's core commerce platform). It acts as the ingestion boundary between mobile clients and the event streaming platform. iOS and Android applications (both legacy and MBNXT variants) send batched GRP telemetry via `api-proxy` to this service, which normalises and forwards events to the Kafka `messageBus`. The service writes operational logs to the shared `loggingStack` (ELK) and emits processing metrics to the shared `metricsStack` (Grafana).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Mobile Logging V2 Service | `continuumMobileLoggingService` | Backend Service | Java, Dropwizard | 1.0.x | Receives mobile app log payloads, decodes and transforms events, and publishes encoded events for downstream processing |
| Message Bus (stub) | `messageBus` | Pipe | Kafka | — | External Kafka cluster receiving `mobile_tracking` events |
| Logging Stack (stub) | `loggingStack` | External | ELK | — | Centralised operational log aggregation |
| Metrics Stack (stub) | `metricsStack` | External | Grafana/tsdaggr | — | Service and event processing metrics collection |

## Components by Container

### Mobile Logging V2 Service (`continuumMobileLoggingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Mobile Logging Ingress API (`mobileLogV2_ingressApi`) | Accepts `/v2/mobile/logs` uploads and orchestrates request processing lifecycle | JAX-RS Resource |
| Message Decode Pipeline (`mobileLogV2_decodePipeline`) | Reads request content, decodes MessagePack payloads, and normalises event records | DecodeService + MessagePackDecoder |
| Event Encoding Component (`mobileLogV2_encodingComponent`) | Encodes normalised events into outbound serialised payloads | Encoder (kafka-message-serde/Loggernaut) |
| Kafka Publish Component (`mobileLogV2_kafkaPublishComponent`) | Selects destination producer and publishes encoded events to Kafka | KafkaEventsProducerFactory |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `mobileLogV2_ingressApi` | `mobileLogV2_decodePipeline` | Submits raw client payload for decode and normalisation | Direct (in-process RxJava) |
| `mobileLogV2_decodePipeline` | `mobileLogV2_encodingComponent` | Passes decoded events for encoding | Direct (in-process) |
| `mobileLogV2_encodingComponent` | `mobileLogV2_kafkaPublishComponent` | Provides encoded event payload for publish | Direct (in-process) |
| `continuumMobileLoggingService` | `messageBus` | Publishes encoded mobile events to `mobile_tracking` | Kafka/TLS |
| `continuumMobileLoggingService` | `loggingStack` | Writes structured operational logs | Log shipping (Filebeat) |
| `continuumMobileLoggingService` | `metricsStack` | Emits service and event processing metrics | tsdaggr |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumMobileLoggingService`
- Dynamic (ingestion flow): `dynamic-mobile-log-ingestion`
