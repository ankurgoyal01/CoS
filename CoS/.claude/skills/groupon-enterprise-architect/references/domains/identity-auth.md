# Identity & Access Domain

> Tier 3 reference — factual, concise, architect-focused

## Overview

**Domain View:** `containers-continuum-platform-identity` (26 elements)

The Identity & Access domain covers authentication, identity resolution, RBAC, consent, and API authorization. It spans two platform generations: Continuum's legacy auth stack (Users Service, Identity Service, Client-ID, API Proxy auth filters) and Encore's new-generation auth services (Authentication, Authorization, Users, API Tokens). Continuum handles all consumer-facing auth; Encore handles B2B/admin auth.

The domain sits at the critical path for every API request. Auth-related filters in the API Proxy chain — BCookieFilter, BCookieTranslateFilter, SubscriberIDCookieFilter, SignifydCookieFilter, ClientIdFilter, RecaptchaFilter — execute before any downstream service call.

## OTP Authentication System (3-Layer)

Three-layer architecture documented in GAPI KT materials:

**Layer 1: API Gateway (Java/Vert.x)** — API Lazlo SOX controllers + BLS services. Orchestrates auth flow between consumer API and backend Users Service. SOX-compliant audit logging on all authentication events.

**Layer 2: Users Service (Ruby/Sinatra)** — Core authentication engine. OTP generation/validation, Redis-backed state for active codes and sessions. System of record for user accounts in Continuum. Hosts database-backed feature flags (Setting model) for per-region auth behavior.

**Layer 3: Infrastructure** — Redis for caching/rate limiting (brute-force prevention, code expiry TTLs). Rocketman for email delivery of OTP codes. reCAPTCHA Enterprise V3 for bot detection. Signifyd for fraud detection on auth attempts.

**OTP flow:** Consumer requests OTP via API Proxy > Lazlo validates request + checks reCAPTCHA score > Users Service generates OTP, stores in Redis with TTL > Rocketman delivers via email > Consumer submits OTP > Users Service validates against Redis > session token issued.

## Feature Flag Systems

Four distinct feature flag systems:

| System | Technology | Used By |
|--------|-----------|---------|
| **Birdcage** | External HTTP service | Java services: Proxy, Lazlo, Deckard |
| **Setting model** | MySQL-backed JSON | Ruby services: Users, Identity |
| **Config-based** | JSON files per environment/region | All Java services |
| **countryFeatures.json** | Per-country feature toggles | API Lazlo |

Known architectural debt — Java services use Birdcage (dynamic) + config files (static). Ruby services use Setting model exclusively. Country-level toggles in Lazlo control which auth flows are available per market.

## Redis Usage

| Service | Port | Purpose |
|---------|------|---------|
| API Proxy | 6379 | Rate limiting counters |
| Deckard (cache) | 7000 (cluster) | Inventory unit cache |
| Deckard (async) | 6379 | Async update queue |
| Users Service | 6379 | OTP codes (TTL expiry), user sessions |
| Identity Service | 6379 | Session storage |

Same port (6379) services connect to separate Redis instances. Deckard uses two configs — cluster (7000) for read-heavy cache, standalone (6379) for async queue.

## Client-ID Service

- **Technology:** Java/Dropwizard + MySQL
- **Purpose:** API client identification and access management. Every API consumer (mobile apps, web, third-party, internal services) gets a Client-ID determining rate limits, feature access, and routing.
- **Integration:** ClientIdFilter in API Proxy validates Client-ID on every request before downstream routing.

## Encore Auth (New Generation)

The Encore Platform (id:7580) implements a clean-sheet authentication and authorization system for B2B/admin use cases. Owned by the Encore Core Team (id:6):

| Service | Owns DB | Purpose |
|---------|---------|---------|
| Authentication | Yes (PostgreSQL) | AuthN — OAuth login via Google standard flow backed by Okta |
| Authorization | Yes (PostgreSQL) | AuthZ — role-based access control for Encore services |
| Users | Yes (PostgreSQL) | Encore user management (separate from Continuum Users Service) |
| API Tokens | Yes (PostgreSQL) | Service-to-service and external API token management |

Each service owns its own PostgreSQL database (Cloud SQL, private IP only) — the `OwnsDB` pattern enforced across Encore. This contrasts with Continuum's shared MySQL clusters.

Encore auth flows through the Gateway (id:7581) which handles JWT validation, token refresh, and request-level authorization before routing to downstream services. The Audit Log service (also with its own DB) records all auth events.

The Users Wrapper (id:7649) in Encore bridges to Continuum's Users Service when B2B operations need to reference consumer accounts, maintaining the strangler fig migration pattern.

## Source Links

| Document | Link |
|----------|------|
| KT: OTP Authentication System | [GA](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82561368067/KT+OTP+Authentication+System) |
| KT: reCAPTCHA Enterprise V3 | [GA](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82558058896/KT+reCAPTCHA+Enterprise+V3+Integration) |
| KT: Signifyd Fraud Detection | [GA](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82558223114/KT+Signifyd+Fraud+Detection+Integration) |
| Continuum Identity View | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) (domain view: `containers-continuum-platform-identity`) |
| Encore Containers | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82243453341/Encore+Containers) |
| Encore Architecture — High Level | [Encore](https://groupondev.atlassian.net/wiki/spaces/Encore/pages/82181062730/Encore+architecture+-+high+level) |
