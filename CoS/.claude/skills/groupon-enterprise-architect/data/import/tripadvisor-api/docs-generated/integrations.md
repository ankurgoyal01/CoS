---
service: "tripadvisor-api"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

The Getaways Affiliate API integrates with three external CPC partner platforms (TripAdvisor, Trivago, and Google Hotel Ads) as consumers of its API. Internally, it depends on two Getaways platform services: `getawaysSearchApi` for real-time hotel availability and `getawaysContentApi` for product catalog data. All integrations are synchronous HTTP-based; no async or event-driven integrations are used.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Getaways Search API | REST/HTTP | Real-time hotel availability and pricing queries | yes | `getawaysSearchApi` (stub in federated model) |
| Getaways Content API | REST/HTTP | Hotel product sets and batch hotel detail retrieval | yes | `getawaysContentApi` (stub in federated model) |
| Tracking Redirect Service | REST/HTTP | Builds tracking redirect URLs for partner links | no | `trackingRedirectService` (stub in federated model) |

### Getaways Search API Detail

- **Protocol**: REST/HTTP
- **Base URL (production)**: `http://getaways-search-app-vip/getaways/v2/search` (from `live-US-settings.properties`)
- **Base URL (staging)**: `http://getaways-search-app-staging-vip/getaways/v2/search` (from `staging-US-settings.properties`)
- **Auth**: Client ID header (`getaways.api.client.id=969805bfe2f3cccb98ef500ea699b53f`)
- **Purpose**: Queries real-time hotel availability; primary upstream data source for all partner responses
- **Failure mode**: Returns `HotelAvailabilityException`; controller returns empty hotel list to partner
- **Connection timeout**: 5 seconds (`getaways.api.connection.timeout.seconds=5`)
- **Circuit breaker**: No evidence found in codebase

### Getaways Content API Detail

- **Protocol**: REST/HTTP
- **Base URL — product sets (production)**: `http://getaways-content-app-vip/v2/getaways/content/product_sets`
- **Base URL — batch hotel detail (production)**: `http://getaways-content-app-vip/v2/getaways/content/hotelDetailBatch`
- **Base URL (staging)**: `http://getaways-travel-content-staging-vip/v2/getaways/content/product_sets`
- **Auth**: `X-GRPN-Groups grp_getaways-extranet-admin.groupon.com_admin` header
- **Purpose**: Retrieves hotel product sets (up to 100 per batch; `live` status only) and batch hotel detail for enriching availability responses
- **Failure mode**: Returns degraded response; no circuit breaker evidence found
- **Circuit breaker**: No evidence found in codebase

### Tracking Redirect Service Detail

- **Protocol**: REST/HTTP
- **Base URL**: Not documented (stub only in federated model)
- **Auth**: Not documented
- **Purpose**: Constructs partner tracking redirect URLs embedded in availability responses
- **Failure mode**: Not documented

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| getaways-search | REST/HTTP | Hotel availability queries | `getawaysSearchApi` |
| getaways-availability-api | REST/HTTP | Listed as service portal dependency | listed in `.service.yml` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| TripAdvisor Partner | HTTPS | Queries hotel availability for CPC listing on TripAdvisor |
| Trivago Partner | HTTPS | Queries hotel availability for CPC listing on Trivago |
| Google Hotel Ads (`continuumGoogleHotelAds`) | HTTPS | Requests query control messages, transaction pricing, and hotel list feeds |

## Dependency Health

- **Connection timeout**: `getaways.api.connection.timeout.seconds=5` (configured in `settings.properties`)
- **Force-off switch**: `getaways.api.forceOff=false` — can be set to `true` to bypass downstream Getaways API calls
- **Availability shortcut**: `availability.shortcut.enabled=true` (dev/default) / `false` (production) — bypasses full availability pipeline when enabled
- No circuit breaker or retry library evidence found in the codebase; failure handling is done at the controller level by returning empty availability responses
