---
service: "janus-engine"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 6
---

# Integrations

## Overview

Janus Engine integrates with three infrastructure-level systems (MBus, Kafka, Janus metadata service) and receives event feeds from six upstream Continuum domain services. All integration is asynchronous via message bus or event stream, except for the synchronous HTTP call to the Janus metadata service for mapper/rule metadata. The service has no inbound synchronous callers.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MBus (Message Bus) | MBus client (mbus-client 1.5.2) | Source of raw domain events (inbound) and DLQ payloads | yes | `messageBus` |
| Kafka cluster | Kafka producer/consumer (kafka-clients 2.7.0, kafka-streams 2.7.0) | Source topics (KAFKA mode) and all canonical sink topics (outbound) | yes | Kafka cluster stub |
| Janus metadata service | HTTP (curator-api 0.0.41) | Provides mapper definitions and curation rules used by `curationProcessor` | yes | Janus metadata service stub |

### MBus (Message Bus) Detail

- **Protocol**: MBus client 1.5.2 (proprietary Groupon message bus)
- **Base URL / SDK**: `mbus-client` library version 1.5.2
- **Auth**: Per MBus configuration (managed externally)
- **Purpose**: Delivers raw domain events from upstream Continuum services to `mbusIngestionAdapter` and DLQ payloads to `dlqProcessor`
- **Failure mode**: If MBus is unavailable, inbound event flow halts; health flag goes unhealthy; no events processed until reconnection
- **Circuit breaker**: No evidence found

### Kafka Cluster Detail

- **Protocol**: Kafka producer (kafka-clients 2.7.0) and Kafka Streams (kafka-streams 2.7.0)
- **Base URL / SDK**: Bootstrap server configured via environment/config (`kafka.grpn.kafka.bootstrap` / Kafka production service cluster)
- **Auth**: Per Kafka cluster configuration (managed externally)
- **Purpose**: Inbound source topics consumed in KAFKA mode; all canonical outbound sink topics (`janus-cloud-tier1/tier2/tier3/impression/email/raw`) published via `janusEngine_kafkaPublisher`
- **Failure mode**: If Kafka is unavailable, publication halts; Kafka Streams pauses; health metrics signal degradation
- **Circuit breaker**: No evidence found — Kafka client retries apply

### Janus Metadata Service Detail

- **Protocol**: HTTP (curator-api 0.0.41)
- **Base URL / SDK**: `janus.web.cloud.production.service` (Kubernetes internal service hostname, resolved from stubs)
- **Auth**: No evidence found (internal service-to-service call)
- **Purpose**: `janusMetadataClientComponent` fetches mapper definitions and routing rules keyed by source topic and event type; `curationProcessor` uses these to transform and route each event
- **Failure mode**: If metadata service is unavailable on startup, curation cannot proceed; cached metadata allows continued operation during transient outages
- **Circuit breaker**: No evidence found — caching provides partial resilience

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumOrdersService` | MBus | Publishes OrderSnapshots and OrderProcessingActivities consumed by Janus Engine | `continuumOrdersService` |
| `continuumUsersService` | MBus | Publishes user account and identity lifecycle events | `continuumUsersService` |
| `continuumDealCatalogService` | MBus | Publishes deal snapshot events | `continuumDealCatalogService` |
| `continuumInventoryService` | MBus | Publishes inventory product/unit snapshot events | `continuumInventoryService` |
| `continuumRegulatoryConsentLogApi` | MBus | Publishes regulatory consent log events | `continuumRegulatoryConsentLogApi` |
| `continuumPricingService` | MBus | Publishes dynamic pricing events | `continuumPricingService` |
| `loggingStack` | Log shipping | Receives operational logs from `continuumJanusEngine` | `loggingStack` |
| `metricsStack` | Metrics push | Receives streaming and health metrics from `continuumJanusEngine` | `metricsStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Downstream services consuming canonical Janus topics (`janus-cloud-tier1/tier2/tier3/impression/email/raw`) are not defined in this service's architecture module. They are tracked in the central `continuumSystem` model.

## Dependency Health

- **MBus**: Liveness is reflected in the filesystem health flag managed by `janusEngine_healthAndMetrics`. No automatic reconnect logic is documented; operational procedures should be defined by the service owner.
- **Kafka**: Kafka Streams provides internal retry and error handling. Metrics emitted to `metricsStack` include streaming health indicators.
- **Janus metadata service**: In-memory cache in `janusMetadataClientComponent` provides a buffer against transient HTTP failures. No circuit breaker is evidenced; stale metadata may be served if the service is unavailable.
