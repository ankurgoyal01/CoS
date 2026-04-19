---
service: "coupons-itier-global"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 4
internal_count: 2
---

# Integrations

## Overview

`coupons-itier-global` integrates with two primary external data APIs (Vouchercloud and GAPI), one CDN (Akamai), and one internal platform dependency (Layout Service). All integrations are synchronous REST or GraphQL over HTTPS. There is no message-bus or event-driven integration. The service also interacts with Groupon V2 Services as an internal dependency.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Vouchercloud API | REST/HTTPS | Provides coupon, merchant, and category data | yes | `vouchercloudApi_5b7d2e` (stub) |
| GAPI (GraphQL) | GraphQL/HTTPS | Provides deal and redemption data | yes | `gapi_1f2a9c` (stub) |
| Akamai CDN | HTTP proxy | Edge caching and traffic routing for consumer page requests | yes | Not modelled |
| Groupon V2 Services | REST/HTTPS | Supplementary Groupon platform data | no | Not modelled |

### Vouchercloud API Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: `@grpn/voucher-cloud-client` v1.50.4
- **Auth**: Not documented in architecture model
- **Purpose**: Primary data source for all coupon, merchant, and category content; also provides redirect rule mappings used in affiliate flows
- **Failure mode**: Cache miss falls through to live API; if API is unavailable, page render may degrade or fail for uncached content
- **Circuit breaker**: No evidence found

### GAPI (GraphQL) Detail

- **Protocol**: GraphQL over HTTPS
- **Base URL / SDK**: `@grpn/graphql-gapi` v5.2.9
- **Auth**: Not documented in architecture model
- **Purpose**: Fetches deal listings and redemption data to augment coupon pages with Groupon deal content
- **Failure mode**: Coupon pages may render with partial data if GAPI is unavailable and no cached data exists
- **Circuit breaker**: No evidence found

### Akamai CDN Detail

- **Protocol**: HTTP proxy (edge CDN)
- **Base URL / SDK**: Infrastructure-level, not SDK-mediated
- **Auth**: Not applicable
- **Purpose**: Edge caching and geographic routing for consumer-facing page requests across 11 countries; absorbs the majority of read traffic before it reaches the I-Tier service
- **Failure mode**: Traffic bypasses CDN and hits origin directly
- **Circuit breaker**: Not applicable

### Groupon V2 Services Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: Not documented in architecture model
- **Auth**: Not documented in architecture model
- **Purpose**: Supplementary data from Groupon platform APIs
- **Failure mode**: No evidence found
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Redis Cache | Redis | Read and write cached offer, redirect, and render payload data | `continuumCouponsRedisCache` |
| Layout Service | REST/HTTPS | Provides page layout shell for server-side rendered pages | Not modelled in this service's DSL |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Direct end-user browser traffic arrives via Akamai CDN. The Layout Service may also call this service for content fragments.

## Dependency Health

- Redis connection is managed by `ioredis` v5.7.0 (`couponsItierGlobal_cacheClient`). ioredis provides automatic reconnection on connection loss.
- HTTP dependencies (Vouchercloud, GAPI) use `axios` v1.5.1. No explicit circuit breaker configuration is documented; retry and timeout policies are not specified in the architecture model.
