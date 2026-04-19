---
service: "orders_mbus_client"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

Orders Mbus Client has two core runtime dependencies: the Orders service (HTTP/JSON) and the Groupon Message Bus (MBus/STOMP). It also depends on its own MySQL message store. There are no external third-party SaaS integrations; all dependencies are internal Groupon services.

## External Dependencies

> No evidence found in codebase of direct external (third-party SaaS) integrations. PayPal events arrive via MBus, not via a direct PayPal API connection.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Orders service | HTTP/JSON (OkHttp3) | Receives translated MBus events as order, billing, redaction, and merchant-payment updates | `continuumOrdersService` |
| Groupon Message Bus (MBus) | MBus/STOMP (JTier messagebus) | Source of all inbound domain events; target for outbound gift-order messages | `messageBus` |
| MySQL (orders_mbus_client message store) | JDBI/MySQL | Durable outbound queue and retry state store | `continuumOrdersMbusClientMessageStore` |

### Orders Service Detail

- **Protocol**: HTTP/JSON
- **Base URL**: Production: `http://orders--rw.production.service`; Staging: `http://orders.staging.service`; Dev/UAT: `http://orders-uat-mongrel-vip.snc1`
- **Auth**: No explicit auth header — relies on network-level trust within the same datacenter/VPC.
- **Purpose**: Receives translated domain events (payment updates, billing updates, bucks mirror sync, account redaction, VFM promotional adjustments, PayPal billing record deletion, suspicious behaviour deactivation).
- **Endpoints called**:
  - `POST /v2/payment_events/store` — payment and billing update events
  - `POST /mirrors/bucks/sync` — bucks mirror synchronisation
  - `POST /v2/account_redaction` — GDPR account erasure
  - `PUT /v2/merchant_payments/inventory_product_attributes` — VFM promotional adjustments
  - `DELETE /tps/v1/paypal_billing_records` — PayPal billing record deletion
  - `PUT /tps/v1/users/{consumer_id}/billing_records/deactivate_user` — suspicious behaviour billing deactivation
  - `GET /v2/inventory_units/{unitId}` — unit lookup (used internally in tests/smoke tests)
- **Failure mode**: Returns `null` response; base processor logs the failure. No circuit breaker or retry at the HTTP client level — failures propagate as exceptions.
- **Circuit breaker**: No evidence found in codebase.
- **Timeouts**: `connectionTimeout: 0.5s`, `readTimeout: 5s`, `writeTimeout: 5s` (from config).

### Groupon Message Bus (MBus) Detail

- **Protocol**: MBus / STOMP over TCP port 61613
- **Auth**: Topic-specific credentials — usernames such as `rocketman`, `payments`, `rocketman_vis` with passwords injected via environment variables in production.
- **Purpose**: Source of all inbound domain events; target for outbound `jms.topic.Order.Gift` messages.
- **Failure mode (consumer)**: Consumer thread blocks waiting for messages; JTier MessageConsumerGroup handles reconnection internally.
- **Failure mode (publisher)**: Failed publishes are retried with exponential backoff via Quartz-scheduled `RetryPublishingJob`; after `maxRetryCount`, message is abandoned.
- **Circuit breaker**: No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Orders Mbus Client is a pure worker and exposes no HTTP API for external callers.

## Dependency Health

- **Orders service**: Health is assessed implicitly — non-2xx responses from the Orders service are logged as failures by the base topic processor. No explicit health-check probe is registered against the Orders service.
- **MBus**: The JTier consumer group polls with a 10-second idle interval; the `heartbeat.txt` file provides local health signal. No dedicated MBus health endpoint is configured.
- **MySQL**: JTier DaaS MySQL datasource includes a connection pool (`connectionTimeout: 1000ms` in staging/production). Health is indirectly surfaced via the monitoring job's message count queries.
