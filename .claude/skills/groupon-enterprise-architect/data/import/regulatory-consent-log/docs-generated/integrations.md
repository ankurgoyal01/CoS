---
service: "regulatory-consent-log"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 3
---

# Integrations

## Overview

The Regulatory Consent Log integrates with five external systems and three internal Groupon platform systems. External integrations handle privacy-platform webhooks (Transcend), b-cookie resolution (Janus Aggregator), and access-data upload (Lazlo). Internal integrations use the PostgreSQL DaaS, Redis RaaS, and the Groupon Message Bus. All outbound HTTP calls use Retrofit over OkHttp; all data store access uses JDBI 3 or the Redis Dropwizard bundle.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Transcend Privacy Platform | REST / Webhook | Validates webhook JWT signatures; uploads erasure and access-request confirmations for Groupon brand | Yes | `transcendPrivacyPlatform` |
| LivingSocial Transcend API | REST | Brand-specific Transcend endpoints for LivingSocial erasure and access confirmations | Yes | `livingSocialTranscendApi` |
| Lazlo API | REST | Uploads user access-request data for Groupon brand | Yes | `lazloApi` |
| LivingSocial Lazlo API | REST | Uploads user access-request data for LivingSocial brand | Yes | `livingSocialLazloApi` |
| Janus Aggregator Service | REST | Resolves erased-user UUID to b-cookie list during erasure pipeline | Yes | `janusAggregatorService` |

### Transcend Privacy Platform Detail

- **Protocol**: HTTP/JSON (inbound webhook + outbound REST)
- **Auth**: Inbound webhook JWT verified via `java-jwt` (auth0 library, version 3.8.2); outbound calls use API credentials (stored in secrets).
- **Purpose**: Receives Transcend-initiated access and erasure events via the `Register User Event Endpoint`; the `Transcend Users Event Service` routes these to the appropriate workflow. After processing, confirmation uploads are sent back to Transcend APIs.
- **Failure mode**: If Transcend is unreachable during async processing, the event remains in the pending user events table and the `Async User Event Executor` Quartz job retries on its next run.
- **Circuit breaker**: No evidence found in codebase.

### Janus Aggregator Service Detail

- **Protocol**: HTTP/JSON
- **Base URL**: `http://janus-aggregations-app-vip.{datacenter}/v1/bcookie_mapping/consumers/{user_uuid}` (datacenter-specific VIP)
- **Auth**: Internal service-to-service (no external auth documented).
- **Purpose**: During the user erasure pipeline, the `Janus Aggregator Client` queries Janus to retrieve all b-cookies associated with a given erased user UUID; these cookies are then stored in Postgres.
- **Failure mode**: Failures are recorded in the Redis error queue and retried. No b-cookie data is lost on Janus unavailability; the erasure pipeline stalls until successful resolution.
- **Circuit breaker**: No evidence found in codebase. Graceful error handling: Janus failures are recorded in RaaS for retry.

### Lazlo API Detail

- **Protocol**: HTTP/JSON
- **Auth**: Internal service credentials (stored in secrets).
- **Purpose**: Uploads user access-request data during async event processing by the `Async User Event Handler Service`.
- **Failure mode**: Upload retried on next Quartz job execution.
- **Circuit breaker**: No evidence found in codebase.

### LivingSocial Transcend API and LivingSocial Lazlo API Detail

- **Protocol**: HTTP/JSON
- **Purpose**: Brand-specific endpoints for LivingSocial users following the same patterns as the Groupon equivalents above.
- **Failure mode**: Same retry semantics as Groupon-brand equivalents.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| PostgreSQL DaaS | JDBC / JDBI 3 | Primary data store for all consent, cookie, erasure, outbox, and event records | `continuumRegulatoryConsentLogDb` |
| Redis RaaS | Redis Pub/Sub / Queue | Work queue and pub/sub for the async user erasure pipeline | `continuumRegulatoryConsentRedis` |
| Message Bus (ActiveMQ Artemis) | MBus (AMQP) | Consumes user erasure, erasure-complete, consent log, and reactivation events; publishes consent log and erasure-complete events | `continuumRegulatoryConsentMessageBus` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Registration service | REST | Records user consent at account creation |
| Checkout service | REST | Records user consent during order flow |
| Subscription Modal service | REST | Records user consent for email subscription |
| API-Lazlo | REST | Validates b-cookie against erased-user records via `GET /v1/cookie` |
| API-Torii | REST | Validates b-cookie against erased-user records via `GET /v1/cookie` |
| Transcend Privacy Platform | Webhook (outbound to RCL) | Delivers GDPR access and erasure webhook events |

> Upstream consumers are also tracked in the central architecture model.

## Dependency Health

- PostgreSQL: `postgres-session-pool-0.pool.ConnectivityCheck` and `postgres-transaction-pool-0.pool.ConnectivityCheck` exposed on the Dropwizard admin healthcheck endpoint (`GET :8081/healthcheck`).
- Redis: `redis` health check exposed on `GET :8081/healthcheck`.
- Message Bus: Monitored via the MBus dashboard; subscription ID `rfs_gapi` (durable in production, non-durable in staging).
- Janus Aggregator: No built-in health check; failures are surfaced in Splunk logs and the Redis error queue.
