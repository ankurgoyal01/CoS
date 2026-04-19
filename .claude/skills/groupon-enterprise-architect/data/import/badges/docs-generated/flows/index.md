---
service: "badges-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for the Badges Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Badge Lookup Request](badge-lookup-request.md) | synchronous | Inbound `GET /badges/v1/badgesByItems` or `POST /badges/v1/badgesByItems` API call | Evaluates which deals in a submitted list should carry badges and returns structured badge payloads |
| [Urgency Message Computation](urgency-message-computation.md) | synchronous | Inbound `POST /api/v3/urgency_messages` or `/api/v4/urgency_messages` API call | Computes countdown timer and inventory-signal urgency messages for a single deal |
| [Merchandising Badge Refresh Job](merchandising-badge-refresh.md) | scheduled | Quartz schedule (`MerchandisingBadgeJob`, ENABLE_JOBS=true) | Polls Deal Catalog Service for deals associated with merchandising taxonomy tags and writes badge assignments to Redis |
| [Localization Cache Refresh Job](localization-cache-refresh.md) | scheduled | Quartz schedule (`LocalizationJob`, ENABLE_JOBS=true) | Fetches current localized string packages from the Localization API and populates the in-memory localization cache |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- [Badge Lookup Request](badge-lookup-request.md) spans `continuumBadgesService` → `continuumBadgesRedis`, `continuumJanusApi`, `continuumTaxonomyApi`, `continuumLocalizationApi`, and `continuumRecentlyViewedApi`
- [Merchandising Badge Refresh Job](merchandising-badge-refresh.md) spans `continuumBadgesService` → `continuumDealCatalogApi` → `continuumBadgesRedis`
- Architecture dynamic view for the badge lookup flow: `dynamic-badgeLookupFlow` (defined in `architecture/views/dynamics/badge-lookup-flow.dsl`)
