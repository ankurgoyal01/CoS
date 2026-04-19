---
service: "deal-catalog-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

The Deal Catalog Service integrates with two external systems (Salesforce and the shared Message Bus) and three internal Continuum Platform services as downstream dependencies. It is consumed by 13+ internal services as a critical source of deal merchandising metadata.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST / Integration | Receives deal metadata pushes (title, category, availability) | Yes | `salesForce` |
| Message Bus (MBus) | Async | Publishes deal lifecycle and snapshot events | Yes | `messageBus` |

### Salesforce Detail

- **Protocol**: REST / Integration
- **Base URL / SDK**: Salesforce pushes to Deal Catalog via configured REST integration endpoints
- **Auth**: Integration-level authentication (managed at the platform integration layer)
- **Purpose**: Salesforce is the primary source of deal offer data. When merchants create or update deals in Salesforce, the platform pushes deal metadata (title, category, availability) to the Catalog API.
- **Failure mode**: If Salesforce integration is down, new deal metadata cannot be ingested. Existing deal data remains available for reads.
- **Circuit breaker**: > No evidence found in codebase

### Message Bus (MBus) Detail

- **Protocol**: Async (MBus Producer)
- **Base URL / SDK**: MBus client library (MBus Producer)
- **Auth**: Internal service credentials
- **Purpose**: The Message Publisher component publishes deal lifecycle events (creation, update, snapshot) and node payload update events to MBus topics for downstream consumers.
- **Failure mode**: If MBus is unavailable, deal lifecycle events will not be delivered to downstream consumers (Marketing Deal Service, etc.), potentially causing stale data in downstream systems.
- **Circuit breaker**: > No evidence found in codebase

## Internal Dependencies (Outbound)

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Coupons Inventory Service | HTTP/JSON | Supports coupons for deals | `continuumCouponsInventoryService` |
| Marketing Deal Service | HTTP/JSON | Notifies MDS of new deals during deal creation flow | `continuumMarketingDealService` |
| Deal Catalog DB | JDBC | Primary data persistence | `continuumDealCatalogDb` |
| Deal Catalog Redis | Redis | PWA queueing and coordination state | `continuumDealCatalogRedis` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| API Lazlo (`continuumApiLazloService`) | HTTP/JSON over internal network | Fetch deal metadata for consumer browsing |
| API Lazlo SOX (`continuumApiLazloSoxService`) | HTTP/JSON over internal network | Fetch deal metadata (SOX-compliant path) |
| CLO Inventory (`continuumCloInventoryService`) | HTTP/JSON via DealCatalogClient | Resolve deal attributes for CLO inventory |
| Voucher Inventory API (`continuumVoucherInventoryApi`) | HTTPS/JSON | Resolve deal attributes for voucher inventory |
| Goods Inventory (`continuumGoodsInventoryService`) | HTTP/JSON via DealCatalogClient | Resolve deal attributes for goods inventory |
| Coupons Inventory (`continuumCouponsInventoryService`) | HTTP/JSON over OkHttp | Resolve deal attributes for coupons inventory |
| Online Booking API (`continuumOnlineBookingApi`) | HTTP/JSON | Fetch deal configuration for online booking |
| Deal Management API (`continuumDealManagementApi`) | HTTP/JSON | Register deal metadata during deal creation |
| Deal Alerts Workflows (`continuumDealAlertsWorkflows`) | API | Fetch deal data for alert workflows |
| Coffee-to-Go Workflows (`coffeeWorkflows`) | REST | Fetch deal data for coffee-to-go workflows |
| S2S Service (`continuumS2sService`) | HTTP/JSON | Retrieves deal catalog attributes for booster mappings |
| Travel Affiliates API (`continuumTravelAffiliatesApi`) | REST/JSON | Retrieves active deals and distribution regions |
| Travel Affiliates Cron (`continuumTravelAffiliatesCron`) | REST/JSON | Fetches active deal UUIDs and region data |

## Dependency Health

> No evidence found in codebase of specific health check, retry, or circuit breaker patterns for dependencies. JTier services at Groupon typically use OkHttp with configurable timeouts and retry policies. Dependency health is monitored through standard platform observability tooling.
