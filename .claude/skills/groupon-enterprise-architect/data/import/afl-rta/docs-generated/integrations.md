---
service: "afl-rta"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 4
---

# Integrations

## Overview

AFL RTA integrates with four internal Continuum platform services and one external messaging infrastructure. Inbound data arrives exclusively via the Kafka `janus-tier2` topic (owned by data-engineering). Outbound calls enrich attributed orders with order and deal data, and publish results to MBus. The `failsafe` library provides retry and circuit-breaker policies for outbound HTTP calls. Kafka TLS client certificates are mounted from a Kubernetes secret (`client-certs` volume).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka (`janus-tier2`) | Kafka (TLS) | Source of all inbound click and order events processed by RTA | yes | `continuumJanusTier2Topic` |

### Kafka (`janus-tier2`) Detail

- **Protocol**: Kafka consumer (TLS); client certificates mounted at `/var/groupon/certs`
- **Base URL / SDK**: `kafka-clients` 2.7.0; topic `janus-tier2`; Janus Avro schema deserialized via `janus-thin-mapper` 1.7-Aff
- **Auth**: TLS mutual authentication using certificates injected as a Kubernetes secret volume
- **Purpose**: Sole inbound data source. Janus tier-2 provides near-real-time pre-processed click and order events from all Groupon platforms, already enriched with bcookie and channel metadata
- **Failure mode**: If Kafka is unavailable the consumer stalls; offsets are not advanced, so processing resumes from last committed position when connectivity is restored. A 1–2 hour outage is not critical as RTA can catch up faster than events are produced
- **Circuit breaker**: Not applicable (no HTTP; Kafka consumer polling handles reconnection natively)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumOrdersService` | HTTPS/JSON | Fetches order details and customer new/returning status for order attribution enrichment | `continuumOrdersService` |
| `continuumMarketingDealService` (MDS) | HTTPS/JSON | Fetches deal taxonomy and deal option details for attributed order enrichment | `continuumMarketingDealService` |
| `continuumAflRtaMySql` | JDBC (MySQL/DaaS) | Reads and writes clicks, attribution tiers, and attributed orders | `continuumAflRtaMySql` |
| `messageBus` | MBus/JMS | Publishes attributed order events for downstream partner channel processing (e.g., Commission Junction) | `messageBus` |

### `continuumOrdersService` Detail

- **Protocol**: HTTPS/JSON via `jtier-retrofit` HTTP client
- **Base URL / SDK**: JTier service discovery; `OrdersApiService` component handles v1 (legacy numeric IDs via `LegacyOrderIdResolver`) and v2 (UUID via `OrderUuidResolver`)
- **Auth**: Internal JTier service-to-service auth
- **Purpose**: Retrieves order details and determines customer status (new vs. returning) as part of attributed order enrichment
- **Failure mode**: Enrichment failure causes attribution to be logged via `LoggingOrderRegistration` fallback rather than published to MBus
- **Circuit breaker**: `failsafe` 2.4.4 retry/circuit-breaker policies applied

### `continuumMarketingDealService` (MDS) Detail

- **Protocol**: HTTPS/JSON via `MDSHttpAdapter` using `jtier-retrofit`
- **Base URL / SDK**: JTier service discovery; deal taxonomy and deal option details fetched by deal ID
- **Auth**: Internal JTier service-to-service auth
- **Purpose**: Enriches attributed orders with deal category taxonomy and deal option metadata required by Commission Junction and other partner channel payloads
- **Failure mode**: Enrichment failure causes attribution to fall back to `LoggingOrderRegistration`
- **Circuit breaker**: `failsafe` 2.4.4 retry/circuit-breaker policies applied; `cache2k` in-memory cache reduces load

## Consumed By

> Upstream consumers are tracked in the central architecture model. AFL RTA does not expose a REST API; it is not called by other services via HTTP. Downstream consumers of the MBus attributed order events include `afl-3pgw` (Commission Junction gateway), as declared in `.service.yml` dependencies.

## Dependency Health

- **Kafka**: Monitored via Wavefront for consumer lag and event throughput on `janus-tier2`. Zero-attribution alert fires if no attributed orders are produced for a configurable number of hours
- **Orders API / MDS**: `failsafe` provides retry with back-off on transient failures; no explicit circuit-breaker dashboard identified in this repository
- **MySQL**: Managed by JTier DaaS platform; connection pool health visible in JVM and service metrics on Wavefront (`afl-rta--sma` dashboard)
- **MBus**: Publish failures are caught and fall through to `LoggingOrderRegistration`; alerting via Wavefront RTA dashboard
