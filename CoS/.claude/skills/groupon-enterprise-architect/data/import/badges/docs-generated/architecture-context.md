---
service: "badges-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumBadgesService", "continuumBadgesRedis"]
---

# Architecture Context

## System Context

The Badges Service is a backend microservice within the **Continuum** platform (deal-platform group). It sits between upstream API aggregation layers (RAPI) that need badge and urgency-message data for deal display, and downstream data services (Janus, Deal Catalog, Localization, Taxonomy, Watson KV) that supply the raw signals required to compute and decorate badges. The service owns its own Redis cache (`continuumBadgesRedis`) for high-throughput badge state storage.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Badges Service | `continuumBadgesService` | Service | Java, Dropwizard | 1.0.x | Provides badge and urgency-message APIs plus scheduled badge update jobs |
| Badges Redis | `continuumBadgesRedis` | Cache / Store | Redis | — | Caches badge data, user-item badge data, and supporting state |

## Components by Container

### Badges Service (`continuumBadgesService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `badges_apiResource` — API Resource Layer | Exposes REST resources/controllers for badges and urgency-message endpoints; routes incoming HTTP requests to the Badge Engine | Dropwizard Resource |
| `badgeEngine` — Badge Engine | Collects badge candidates, ranks them, applies taxonomy decorators, and formats response payloads | Java Service |
| `feedService` — Feed Service | Builds data feeds from Redis cache and recently-viewed input for badge generation; coordinates per-consumer and per-visitor personalisation signals | Java Service |
| `externalClientGateway` — External Client Gateway | Coordinates all outbound HTTP calls to Janus (deal stats), Taxonomy API, Localization API, Deal Catalog Service, and Watson KV (recently viewed) | HTTP Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBadgesService` | `continuumBadgesRedis` | Reads and writes badge cache and user-item badge entries | RESP |
| `continuumBadgesService` | `continuumJanusApi` | Retrieves deal statistics (views, purchases, last purchase time) for urgency message and badge generation | HTTPS/JSON |
| `continuumBadgesService` | `continuumDealCatalogApi` | Fetches deal catalog attributes (deal IDs by merchandising tag) for badge composition | HTTPS/JSON |
| `continuumBadgesService` | `continuumLocalizationApi` | Fetches localized strings and localization metadata for badge copy | HTTPS/JSON |
| `continuumBadgesService` | `continuumTaxonomyApi` | Loads badge taxonomy and localized taxonomy structures | HTTPS/JSON |
| `continuumBadgesService` | `continuumRecentlyViewedApi` | Loads recently-viewed deal history for personalized feed badges | HTTPS/JSON |
| `badges_apiResource` | `badgeEngine` | Requests badge and urgency-message evaluation | Direct (in-process) |
| `badgeEngine` | `feedService` | Fetches input feeds for ranking and decoration | Direct (in-process) |
| `feedService` | `externalClientGateway` | Retrieves external data needed for feed enrichment | Direct (in-process) |
| `badgeEngine` | `externalClientGateway` | Retrieves taxonomy/localization/deal-stats context | Direct (in-process) |

> Note: Relationships to `continuumJanusApi`, `continuumDealCatalogApi`, `continuumLocalizationApi`, `continuumTaxonomyApi`, and `continuumRecentlyViewedApi` are declared as stub-only in the local workspace DSL because those targets are not yet in the federated central model.

## Architecture Diagram References

- Container: `containers-badges`
- Component: `components-badgesServiceComponents`
- Dynamic (badge lookup flow): `dynamic-badgeLookupFlow`
