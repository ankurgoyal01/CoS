---
service: "voucher-inventory-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 4
---

# Integrations

## Overview

Voucher Inventory JTier has four internal Groupon service dependencies (Pricing Service, Calendar Service, Legacy VIS, MessageBus) and two external infrastructure dependencies (DaaS MySQL, Groupon Transfer SFTP). The API container calls Pricing Service and Calendar Service synchronously during request processing. The Worker container communicates with Legacy VIS (HTTP) for replenishment jobs and with Groupon Transfer (SFTP) for unit redeem file processing. All HTTP clients use OkHttp/Retrofit with configured connect and read timeouts.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Groupon Transfer SFTP | SFTP | Downloads unit redeem files for EMEA processing | no | `transferSftp` |

### Groupon Transfer SFTP Detail

- **Protocol**: SFTP (JSch, port 22)
- **Host**: `transfer.groupondev.com`
- **Auth**: SSH private key (`~/.ssh-key/id_rsa`) with known hosts file
- **User**: `voucher-inventory-dev`
- **Remote path (production EMEA)**: `/groupon-transfer-prod-voucher-inventory/EMEA`
- **Remote path (staging EMEA)**: `/groupon-transfer-prod-voucher-inventory/staging/EMEA`
- **Local path**: `/app/jobs/unit-redeem`
- **Purpose**: The Unit Redeem Job (Quartz, Worker container) downloads unit redeem CSV files from this SFTP server and posts redeem updates to Legacy VIS
- **Failure mode**: Unit redeem job fails for that cycle; no fallback defined

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Pricing Service | HTTP (OkHttp/Retrofit) | Fetches dynamic pricing and updates feature controls for inventory products | `continuumPricingService` |
| Calendar Service | HTTP (OkHttp/Retrofit) | Fetches availability segments and product segments for inventory enrichment | `continuumCalendarService` |
| Legacy VIS (Voucher Inventory Service 1.0/2.0) | HTTP (OkHttp/Retrofit) | Replenishment job fetches inventory schedule details; Unit Redeem job posts redeem updates | `legacyVoucherInventoryService` |
| MessageBus | JMS/STOMP (port 61613) | Publishes inventory product updates; consumes inventory and order events | `messageBus` |

### Pricing Service Detail

- **Protocol**: HTTP (OkHttp/Retrofit)
- **Base URL (production cloud)**: `http://pricing-service.production.service/`
- **Base URL (production on-prem SNC1)**: `http://pricing-app-vip.snc1/`
- **Auth**: Client ID `418587d4-c892-49fe-9a27-63928a4b7eb2` propagated in request
- **Purpose**: Two use cases — `GetPrice` type fetches dynamic pricing to enrich inventory response; `UpdateFeatures` type writes feature control updates to Pricing Service
- **Timeouts (production cloud)**: connectTimeout: 150ms, readTimeout: 600ms; maxConcurrentRequests: 200
- **Failure mode**: VIS falls back to contracted price if Pricing Service does not respond within SLA (TP99: 7ms)
- **Circuit breaker**: No evidence found in codebase

### Calendar Service Detail

- **Protocol**: HTTP (OkHttp/Retrofit)
- **Base URL (production cloud)**: `http://calendar-service.production.service/`
- **Base URL (production on-prem SNC1)**: `http://booking-engine-calendar-service-vip.snc1/`
- **Auth**: Client ID `vis`
- **Purpose**: Fetches product availability segments (`/v1/products/segments`) and product availability (`/v1/products/availability`) to enrich inventory responses
- **Timeouts (production cloud)**: connectTimeout: 150ms, readTimeout: 600ms; maxConcurrentRequests: 200
- **Feature flag**: Enabled when `enableCalendarService: true` (on in production cloud and EU regions; off in SNC1 on-prem production)
- **Failure mode**: Not explicitly defined; controlled via `enableCalendarService` flag
- **Circuit breaker**: No evidence found in codebase
- **HBW acquisition method IDs**: A configured list of UUIDs determines which products use the booking/HBW flow

### Legacy VIS Detail

- **Protocol**: HTTP (OkHttp/Retrofit)
- **Base URL (production cloud)**: `http://voucher-inventory.production.service/`
- **Base URL (production on-prem SNC1)**: `http://voucher-inventory-staging.snc1/`
- **Auth (replenishment)**: Client ID `ouroboros-jtier`; **Auth (unit redeem)**: Client ID `1088c9f67300fc53-mvrt`
- **Purpose**: Replenishment Job reads inventory schedule details from Legacy VIS; Unit Redeem Job posts redeem updates (type `GliveUnitRedeem`) to Legacy VIS
- **Timeouts (production cloud)**: connectTimeout: 1,000ms, readTimeout: 5,000ms
- **Failure mode**: Replenishment or unit redeem job fails for that cycle
- **Circuit breaker**: No evidence found in codebase

### MessageBus Detail

- **Protocol**: JMS/STOMP (port 61613)
- **Production on-prem host**: `mbus-vip.snc1`
- **Production cloud host**: `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com`
- **Auth**: Username/password configured per destination (`voucher-inventory` / secret)
- **Purpose**: Bidirectional — Worker consumes 5 inventory/order topics; API publishes inventory product updates
- **Failure mode**: Worker processes stop receiving updates; events queue in MessageBus durable subscriptions

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include Deal Estate, Deal Wizard, and all registered client IDs in the Hybrid Boundary configuration. The complete list is maintained in the client ID spreadsheet referenced in `doc/owners_manual.md`.

## Dependency Health

- **Pricing Service SLA**: TP99 7ms, 99.9% uptime; VIS falls back to contracted price on timeout
- **Calendar Service SLA**: TP99 13ms, 99.9% uptime; controlled via `enableCalendarService` feature flag
- **MessageBus polling**: 10,000ms poll interval (`mbusConsumerPollTime`) with durable subscriptions
- **Redis timeouts**: connectTimeout 1,000ms, queryTimeout 1,000ms; pool of up to 2,000 connections
- **MySQL timeouts**: connectTimeout 60,000ms, socketTimeout 60,000ms per database connection
