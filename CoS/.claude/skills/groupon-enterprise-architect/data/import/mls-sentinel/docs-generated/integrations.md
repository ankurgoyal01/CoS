---
service: "mls-sentinel"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 6
---

# Integrations

## Overview

MLS Sentinel has six internal Groupon service dependencies, all within the Continuum platform. Four are accessed via synchronous HTTP using Retrofit2 + RxJava3 clients (VIS, Reading Rainbow, M3 Merchant, Deal Catalog); one is accessed via FIS (Federated Inventory Service) client (Inventory Service); and one is the shared messaging infrastructure (MessageBus / Kafka). There are no external third-party dependencies. All HTTP clients are configured under the `clients` section of the JTier YAML config and injected via HK2 DI.

## External Dependencies

> No evidence found in codebase of third-party external service integrations.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Voucher Inventory Service (VIS) | HTTP (Retrofit2 / RxJava3) | Validates that voucher and inventory entities are current in the RO datasource before emitting commands | `continuumVoucherInventoryService` |
| Inventory Service | HTTP (Retrofit2 / FIS client) | Fetches inventory product payloads during update and backfill flows | `continuumInventoryService` |
| M3 Merchant Service | HTTP (Retrofit2 / RxJava3) | Fetches merchant account details for validation during MerchantFact and MerchantAccount flows | `continuumM3MerchantService` |
| Reading Rainbow | HTTP (Retrofit2 / RxJava3) | Fetches account and history-related data used in merchant lifecycle flows | `continuumRainbowService` |
| Deal Catalog Service | HTTP (Retrofit2 / RxJava3) | Fetches deal catalog data; also publishes deal snapshot/update messages to MBus consumed by Sentinel | `continuumDealCatalogService` |
| MessageBus / Kafka | MBus (JMS) + Kafka | Consumes domain events (MBus queues/topics); publishes validated MLS Command messages (Kafka topics) | `messageBus` |

### Voucher Inventory Service (VIS) Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Configured under `clients.vis` in JTier YAML; uses `VisClient` Retrofit interface from `mx-jtier-commons`
- **Auth**: Internal Groupon service auth (JTier client credentials)
- **Purpose**: Entity freshness validation — Sentinel checks that the RO view of VIS has the updated voucher/unit before producing a Kafka Command. Concurrent VIS calls are bounded by `maxConcurrentVisMessages` config.
- **Failure mode**: If VIS count check times out (threshold: `visCountTimeoutLimit`), Sentinel can optionally use a merchant blacklist (`useMerchantBlacklistOnVisTimeout`, blacklist TTL: `merchantBlacklistTimeoutMillis`). MBus message is not acknowledged; retried in 15 minutes.
- **Circuit breaker**: No explicit circuit breaker evidenced; RxJava3 timeout and retry strategy applied

### M3 Merchant Service Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Configured under `clients.m3Merchant`; uses `M3MerchantClient` Retrofit interface
- **Auth**: Internal Groupon service auth
- **Purpose**: Retrieves merchant account information to populate MerchantAccountChanged and MerchantFactChanged commands
- **Failure mode**: Flow processing fails; MBus message is nacked and retried
- **Circuit breaker**: No explicit circuit breaker evidenced

### Reading Rainbow Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Configured under `clients.readingRainbow`; uses `ReadingRainbowClient` Retrofit interface
- **Auth**: Internal Groupon service auth
- **Purpose**: Provides account and history-related data needed for merchant lifecycle event processing
- **Failure mode**: Flow processing fails; MBus message is nacked and retried
- **Circuit breaker**: No explicit circuit breaker evidenced

### Deal Catalog Service Detail

- **Protocol**: HTTP REST + MBus (bidirectional)
- **Base URL / SDK**: Configured under `clients.dealCatalog` (optional); uses `DealCatalogClient` Retrofit interface; also publishes deal snapshot/update messages to MBus that Sentinel consumes
- **Auth**: Internal Groupon service auth
- **Purpose**: Fetches deal catalog data during inventory update flows; also the source of deal snapshot events that Sentinel processes
- **Failure mode**: If optional config absent, HTTP calls are skipped; MBus events from Deal Catalog continue to be consumed
- **Circuit breaker**: No explicit circuit breaker evidenced

### MessageBus / Kafka Detail

- **Protocol**: MBus (JMS-style broker) for inbound; Kafka 0.9.0.1 for outbound
- **Base URL / SDK**: MBus destinations configured per processor in `mbusConfiguration`; Kafka producer/router properties in `commandRouter.kafka`
- **Auth**: Broker-level auth (TLS for Kafka — configured via `kafka-tls.sh` in Docker image)
- **Purpose**: Primary event transport: inbound MBus events drive all flow processing; outbound Kafka commands feed MLS Yang and other consumers
- **Failure mode**: Kafka producer failure surfaces via `MlsSentinel-US_KAFKA_PRODUCED` Nagios alert; MBus consumer failure via `MlsSentinel-US_MBUS_CONSUMED` alert
- **Circuit breaker**: No explicit circuit breaker; Kafka producer uses synchronous/async send with error logging

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| MLS Yang | Kafka | Primary consumer of all `mls.*` Kafka Command topics produced by Sentinel |
| Any MLS subscriber | Kafka | Open subscription to `mls.*` topics (topic-level fanout) |

> Upstream consumer details beyond MLS Yang are tracked in the central architecture model.

## Dependency Health

- **VIS**: Bounded concurrency via `maxConcurrentVisMessages` and `maxWaitBeforeVisMessageProcessingInMillis` config values. Timeout triggers optional merchant blacklist. Latency tracked via Splunk `http.out` logs and Wavefront outgoing call rate alert.
- **All HTTP clients**: Latency monitored via Splunk `http.out` structured log events. Wavefront alert fires if outgoing call failure rate exceeds 100 per 4 minutes.
- **MBus consumers**: Health tracked via `mbus_message_consume` Splunk log events and `MlsSentinel-US_MBUS_CONSUMED` Nagios alert.
- **Kafka producer**: Health tracked via `kafka_message_produce` Splunk log events and `MlsSentinel-US_KAFKA_PRODUCED` Nagios alert.
