---
service: "mailman"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 0
internal_count: 13
---

# Integrations

## Overview

Mailman has thirteen internal Continuum dependencies: twelve HTTP/JSON services providing domain context data, and one messaging infrastructure dependency (MBus). All outbound HTTP calls are made via Retrofit-based clients encapsulated in `continuumMailmanOutboundClients`. There are no external (third-party) integrations owned by Mailman — Rocketman handles the external email provider relationship downstream of MBus.

## External Dependencies

> Not applicable — Mailman has no direct external (third-party) integrations. External email delivery is handled by Rocketman after receiving MBus events.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `messageBus` | MBus/JMS | Consumes inbound request queue (`MailmanQueue`), DLQ, and publishes `TransactionalEmailRequest` payloads | `messageBus` |
| `continuumOrdersService` | HTTP/JSON | Fetches order and transaction details for order-related notifications | `continuumOrdersService` |
| `continuumUsersService` | HTTP/JSON | Fetches user/account profiles for personalization and targeting | `continuumUsersService` |
| `continuumDealCatalogService` | HTTP/JSON | Fetches deal catalog and product metadata | `continuumDealCatalogService` |
| `continuumMarketingDealService` | HTTP/JSON | Fetches deal-management metadata and lifecycle details | `continuumMarketingDealService` |
| `continuumVoucherInventoryService` | HTTP/JSON | Fetches voucher and inventory-unit data | `continuumVoucherInventoryService` |
| `continuumRelevanceApi` | HTTP/JSON | Fetches relevance and recommendation context (loaded when required) | `continuumRelevanceApi` |
| `continuumUniversalMerchantApi` | HTTP/JSON | Fetches merchant and location data | `continuumUniversalMerchantApi` |
| `continuumApiLazloService` | HTTP/JSON | Fetches legacy API data paths for market-specific flows | `continuumApiLazloService` |
| `continuumGoodsInventoryService` | HTTP/JSON | Fetches goods inventory data for goods notifications | `continuumGoodsInventoryService` |
| `continuumTravelInventoryService` | HTTP/JSON | Fetches travel itinerary and inventory data | `continuumTravelInventoryService` |
| `continuumThirdPartyInventoryService` | HTTP/JSON | Fetches partner inventory data for third-party notifications | `continuumThirdPartyInventoryService` |
| `mailmanPostgres` | JDBC | Reads/writes request, retry, and deduplication state | `mailmanPostgres` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. MBus producers writing to `MailmanQueue` are the primary upstream producers. Rocketman consumes Mailman's published MBus events.

## Dependency Health

- All outbound HTTP calls to domain services are made via Retrofit clients in `continuumMailmanOutboundClients`. No evidence of circuit breaker configuration was found in the architecture model.
- MBus integration via `continuumMailmanMessageBusIntegration` handles DLQ consumption for failed messages.
- PostgreSQL connectivity is managed via standard Spring Boot JDBC data source configuration.
- EhCache provides in-process fallback for reference data if downstream services are temporarily slow.
