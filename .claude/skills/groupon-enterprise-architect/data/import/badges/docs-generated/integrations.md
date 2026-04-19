---
service: "badges-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 6
---

# Integrations

## Overview

The Badges Service has six internal Groupon service dependencies and no external third-party integrations. All outbound calls are synchronous HTTPS/JSON over the internal Groupon network. Dependencies are accessed through the `externalClientGateway` component and dedicated client classes. Failed calls return zero/default values to avoid propagating dependency failures to callers.

## External Dependencies

> No evidence found in codebase.

The Badges Service has no external (third-party, internet-facing) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Janus (deal stats aggregator) | HTTPS/JSON (async) | Retrieves last-24-hour view/purchase stats, last-7-day purchases, last-purchase timestamp, and last-5-minute views for urgency message and badge signal computation | `continuumJanusApi` |
| Deal Catalog Service (DCS) | HTTPS/JSON | Fetches lists of deal UUIDs associated with merchandising taxonomy tags for `MerchandisingBadgeJob` | `continuumDealCatalogApi` |
| Localization API | HTTPS/JSON | Fetches localized string packages for badge display text and urgency message copy | `continuumLocalizationApi` |
| Taxonomy API v2 | HTTPS/JSON | Loads badge taxonomy definitions and localized taxonomy structures used for badge decoration | `continuumTaxonomyApi` |
| Watson KV (recently viewed) | HTTPS/JSON | Retrieves recently-viewed deal history keyed by consumer ID or anonymous visitor ID for personalized feed badges | `continuumRecentlyViewedApi` |
| STaaS (Redis) | RESP | Persistent badge cache — managed Redis cluster; declared as `staas` in `.service.yml` dependencies | `continuumBadgesRedis` |

### Janus Detail

- **Protocol**: HTTPS/JSON, async via `async-http-client` 2.11.0
- **Endpoints used**:
  - `GET {janusEndpoint}/v1/getEvents?dealId=...&timeAggregation=hourly&startDateTime=NOW-24hour&endDateTime=NOW&eventType=dealPurchase|dealView`
  - `GET {janusEndpoint}/v1/getEvents?dealId=...&timeAggregation=daily&startDateTime=NOW-7day&endDateTime=NOW&eventType=dealPurchase`
  - `GET {janusEndpoint}/v1/deal_last_purchase_time?deal_uuid=...`
  - `GET {janusEndpoint}/v1/getEvents?dealId=...&timeAggregation=5min&startDateTime=NOW-5min&endDateTime=NOW&eventType=dealView`
- **Auth**: Internal network trust
- **Purpose**: Supplies deal-level purchase and view event counts that drive Selling Fast, Recently Purchased, and timer-based urgency messages
- **Failure mode**: On timeout or exception, returns `DealStats.getAllZerosInstance()` or `0L` default; `timeoutMeter` and `exceptionMeter` Codahale metrics are incremented
- **Caching**: Results cached in Redis with configurable TTLs; 24-hour stats use a stale-while-revalidate pattern refreshing every 5 minutes

### Deal Catalog Service (DCS) Detail

- **Protocol**: HTTPS/JSON via Apache HttpComponents `fluent-hc`
- **Auth**: Internal network trust
- **Purpose**: `MerchandisingBadgeJob` calls DCS to obtain deal UUIDs for a given merchandising taxonomy UUID, then writes those deal-badge assignments to Redis
- **Failure mode**: IOException logged and current job execution skipped for the affected badge type; logged via `LOG.error`
- **Circuit breaker**: No explicit circuit breaker; errors are caught and logged per execution

### Localization API Detail

- **Protocol**: HTTPS/JSON
- **Auth**: Internal network trust
- **Purpose**: `LocalizationJob` (scheduled) fetches localized string packages and populates the in-memory `LocalizationUtil` cache used for badge display text
- **Failure mode**: `Optional.empty()` returned; cache remains stale from previous successful fetch

### Taxonomy API v2 Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Configured via `badgesTaxonomyConfig.url` with timeouts `connectTimeout`, `connectionRequestTimeout`, `socketTimeout`, and `refreshInterval`
- **Auth**: Internal network trust
- **Purpose**: Supplies badge taxonomy definitions and localized taxonomy badge data for badge decoration in the `badgeEngine`
- **Failure mode**: Falls back to previously cached taxonomy data

### Watson KV (recently viewed) Detail

- **Protocol**: HTTPS/JSON via Apache `httpclient`
- **Base URL**: `recentlyViewedServiceConfig.url` + `profile/<consumerId>` or `anonymous/<visitorId>`
- **Auth**: Internal network trust
- **Purpose**: Provides the recently-viewed deal list for personalized feed badge generation; up to 6 active, non-adult, non-previously-purchased deals are selected
- **Failure mode**: `CouldNotConnectToWatsonException` thrown and caught upstream; empty list returned

## Consumed By

> Upstream consumers are tracked in the central architecture model.

The primary known consumer is RAPI (the Groupon API aggregation layer), which calls `GET /badges/v1/badgesByItems` for deal grid and detail page rendering across web, email, and mobile channels. The `.service.yml` description confirms: "Powers badges across web, email and mobile via RAPI."

## Dependency Health

- **Janus**: Monitored via `janusExceptionMeter` and `janusTimeoutExceptionMeter` Codahale metrics; per-endpoint timers (`janusGetEventsTimer`, `janusLastPurchaseTimeTimer`) track latency
- **Watson KV / recently viewed**: Monitored via `get_watson_recently_viewed` custom timer metric
- **Redis**: Monitored via `LettuceDBHandle*` pool metrics; dual-client setup (Lettuce async cluster + Jedis sync pool)
- All dependencies listed in `.service.yml` `dependencies` array: `staas`, `janus`, `watson-kv`, `raas`, `taxonomyv2`
