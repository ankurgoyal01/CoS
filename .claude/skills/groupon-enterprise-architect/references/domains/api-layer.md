# API Layer (GAPI Monorepo)

## Overview

The GAPI monorepo is the core API infrastructure serving all consumer traffic for Groupon. It lives within the Continuum platform (ID:297) and encompasses the edge gateway, SOX-compliant aggregation layer, user/identity services, and supporting infrastructure. All consumer-facing requests flow through this stack before reaching downstream commerce, inventory, and merchant services.

The GAPI codebase is organized as a monorepo containing multiple Java/Vert.x and Ruby/Sinatra services deployed across 7 regions: snc1 (legacy DC), us-central1 (GCP primary), us-west-1/2 (GCP), europe-west1 (GCP EMEA), dub1 (legacy EMEA), eu-west-1 (AWS EMEA), and sac1 (South America).

## Service Configuration Hierarchy

GAPI services use a 4-level configuration hierarchy that allows progressively more specific overrides:

| Level | Scope | Mechanism |
|-------|-------|-----------|
| **Base Configs** | Default values for all environments | JSON config files in repo |
| **Environment Overrides** | Staging / UAT / Production | Environment-specific JSON files |
| **Region Overrides** | Per-datacenter / cloud-region | Region-specific JSON files |
| **Runtime Overrides** | Live changes without deploy | DB-backed flags, feature toggles |

This hierarchy means a production setting in us-central1 can differ from europe-west1, and runtime overrides (stored in the database) take precedence over all file-based configuration. Feature flag systems layer on top: Birdcage (external HTTP service for Java services), Setting model (MySQL-backed JSON for Ruby services), config-based JSON per environment/region, and `countryFeatures.json` for per-country toggles.

## API Proxy

**Technology:** Java/Vert.x | **ID:** 298 | **Role:** Edge gateway

The API Proxy is the entry point for all consumer traffic. It handles request routing, rate limiting, A/B testing support, and a 14-filter chain that processes every inbound request in sequence:

```
TracingFilter → ExtensionFilter → ErrorFilter → BCookieFilter →
BCookieTranslateFilter → SubscriberIDCookieFilter → SignifydCookieFilter →
XForwardedProtoFilter → LoadShedFilter → BrandFilter → ClientIdFilter →
RateLimitFilter → CORSFilter → RecaptchaFilter
```

**Filter responsibilities:**
- **TracingFilter** — Distributed tracing context propagation
- **BCookieFilter / BCookieTranslateFilter** — Browser cookie handling and translation
- **SubscriberIDCookieFilter** — Subscriber identification
- **SignifydCookieFilter** — Fraud detection integration (Signifyd)
- **LoadShedFilter** — Circuit breaker / load shedding under pressure
- **BrandFilter** — Multi-brand routing (Groupon operates across brands)
- **ClientIdFilter** — API client identification (ties to Client-ID service)
- **RateLimitFilter** — Per-client rate limiting (Redis-backed, port 6379)
- **CORSFilter** — Cross-origin request handling
- **RecaptchaFilter** — reCAPTCHA Enterprise V3 bot protection

**Timeout configuration:**

| Timeout Type | Value |
|-------------|-------|
| Default connect | 200ms |
| Default request | 2,000ms |
| Write operations (orders, bucks) | Up to 60,000ms |
| Localization / CMS | 6,000ms |

## API Lazlo SOX

**Technology:** Java/Vert.x | **Role:** SOX-compliant API aggregator

API Lazlo SOX is the primary aggregation layer sitting behind the API Proxy. It orchestrates calls to 50+ downstream service clients, assembling composite responses for consumer-facing endpoints. The "SOX" designation indicates it handles financially sensitive operations (orders, payments, bucks) subject to SOX compliance controls.

**Complete downstream client inventory:**

| Category | Clients |
|----------|---------|
| **Core commerce** | AdsClient, CartServiceClient, DealCatalogClient, UsersClient, WriteOnlyOrdersClient, ReadOnlyOrdersClient, TaxonomyClient, LocalizeClient |
| **Inventory** | VIS (Voucher Inventory Service), CLO (Card-Linked Offers), Stores, Goods, TPIS (Third-Party Inventory Service), GLive (Groupon Live), MR Getaways, Getaways |
| **Supplementary** | AutoRebuy, Bucks, CloConsent, CustomerService, Epods, Geoplaces, Incentives, Merchant, MerchantPlace, Messaging, Offers, Subscriptions, UGC, Wishlist |

The three-layer authentication architecture flows through Lazlo: API Gateway controllers and BLS services in Java/Vert.x call down to the Users Service for OTP generation/validation, with Redis backing state and Rocketman handling email delivery.

## Supporting Services

### Users Service
**Technology:** Ruby/Sinatra | **Role:** User authentication and OTP

Handles user authentication, one-time password (OTP) generation and validation, and database-backed feature flags (Setting model pattern — MySQL-backed JSON). Uses Redis (port 6379) for OTP codes and session storage.

### Identity Service
**Technology:** Ruby/Sinatra + PostgreSQL | **Role:** Identity management

Newer identity management service that coexists with the Users Service. Handles identity resolution and management with Redis (port 6379) for session storage. Uses PostgreSQL rather than MySQL, distinguishing it from most Continuum services.

### Deckard
**Technology:** Java/Vert.x | **Role:** Inventory unit indexing and caching

Maintains a fast-access index of inventory units with Redis cluster caching (port 7000) for the cache layer and Redis (port 6379) for async update queues. Supports real-time inventory availability lookups for the consumer experience.

### Client-ID Service
**Technology:** Java/Dropwizard + MySQL | **Role:** API client identification

Manages API client identification and access control. Every API consumer is assigned a client ID that flows through the ClientIdFilter in the proxy chain, enabling per-client rate limiting, access policies, and usage tracking.

## Redis Usage Across Services

| Service | Port | Purpose |
|---------|------|---------|
| API Proxy | 6379 | Rate limiting counters |
| Deckard (cache) | 7000 (cluster) | Inventory unit cache |
| Deckard (async) | 6379 | Async update queue |
| Users Service | 6379 | OTP codes, sessions |
| Identity Service | 6379 | Session storage |

## Source Links

| Document | Space | Link |
|----------|-------|------|
| KT: Service Configurations (GAPI) | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82559139956/KT+Service+Configurations) |
| KT: OTP Authentication System | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82561368067/KT+OTP+Authentication+System) |
| KT: reCAPTCHA Enterprise V3 | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82558058896/KT+reCAPTCHA+Enterprise+V3+Integration) |
| KT: Signifyd Fraud Detection | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82558223114/KT+Signifyd+Fraud+Detection+Integration) |
| Continuum Containers | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) |
| Continuum Components | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82250137601/Continuum+Components) |
| Groupon API Space | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/) |
