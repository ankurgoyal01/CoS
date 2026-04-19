---
service: "HotzoneGenerator"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 5
---

# Integrations

## Overview

HotzoneGenerator depends on five internal Continuum services, all called via synchronous HTTPS/JSON. There are no external (third-party) dependencies. All base URLs are environment-specific and loaded from per-environment `.properties` files via `AppConfig`. The job also reads a classpath-bundled JSON resource for division coefficients (GConfig data baked into the jar at build time).

## External Dependencies

> No evidence found in codebase. HotzoneGenerator has no external (third-party) dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Proximity Notifications API | HTTPS/JSON | Reads active campaign configs; writes generated hotzones; manages campaign/send-log lifecycle | `continuumHotzoneGeneratorJob` → Proximity Notifications API (stub) |
| Marketing Deal Service (MDS) | HTTPS/JSON | Fetches deal listings by category, country, and trending filters; fetches division lists | `continuumMarketingDealService` |
| Taxonomy Service v2 | HTTPS/JSON | Resolves English display names for taxonomy category GUIDs | `continuumTaxonomyService` |
| Deal Catalog Service | HTTPS/JSON | Fetches inventory product IDs per deal UUID | `continuumDealCatalogService` |
| Internal API Proxy (GAPI / deal-clusters) | HTTPS/JSON | Fetches merchant open hours per deal redemption location; fetches trending category data from deal-clusters endpoint | `apiProxy` |

### Proximity Notifications API Detail

- **Protocol**: HTTPS/JSON
- **Base URL (production NA)**: `http://proximity-notifications.production.service/v1/proximity/location/hotzone` and `http://proximity-notifications.production.service/proximity` (geofence base)
- **Auth**: `client_id=ec-team` query parameter
- **Purpose**: Central state store for all hotzone and campaign data. This job reads configs and writes back all generated output.
- **Failure mode**: `cleanupDB()` and `insertHotzonesWithAPI()` call `System.exit(1)` on failure, aborting the run.
- **Circuit breaker**: No — failures propagate immediately; run aborts.

### Marketing Deal Service (MDS) Detail

- **Protocol**: HTTPS/JSON
- **Base URL (production NA)**: `http://marketing-deal-service.production.service/`
- **Auth**: HTTP username `groupon` (passed via `Optional.of("groupon")` in `HttpClient.get()`)
- **Purpose**: Primary deal data source. Fetches up to 5 pages × 5,000 deals per category config and per country for new-deal hotzones.
- **Failure mode**: Logged via Steno; individual country/division failures are caught and skipped. Hotzone generation for the affected config is degraded but the run continues.
- **Circuit breaker**: No.

### Taxonomy Service v2 Detail

- **Protocol**: HTTPS/JSON
- **Base URL (production)**: `http://taxonomyv2.production.service/categories/`
- **Auth**: No auth evidence found.
- **Purpose**: Resolves a category GUID to a human-readable English name used in auto-campaign creation.
- **Failure mode**: Caught and logged; empty string used as fallback category name, allowing campaign creation to proceed.
- **Circuit breaker**: No.

### Deal Catalog Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL (production)**: `http://deal-catalog.production.service/deal_catalog/v2/deals/`
- **Auth**: `clientId=36b3b7d857a447aa-campaign-management` (property key `dealCatalog.clientId`)
- **Purpose**: Retrieves inventory product IDs for each deal; these are embedded in the hotzone payload.
- **Failure mode**: Not explicitly caught in the deal enrichment loop; exceptions bubble up as stack traces.
- **Circuit breaker**: No.

### Internal API Proxy (GAPI / deal-clusters) Detail

- **Protocol**: HTTPS/JSON
- **Base URL (production NA)**: `http://api-proxy--internal-us.production.service`; EMEA: `http://api-proxy--internal-eu.production.service`
- **Auth**: `client_id` / `gapi.clientId` property (`847cf93c1ffa22bb5376f18192721483`)
- **Purpose**: Two uses — (1) fetches merchant redemption-location open hours for time-window merging, (2) fetches deal-cluster trending navigation categories.
- **Failure mode**: Open-hours fetch exceptions are silently caught; deals without open hours are skipped when `useOpenHours=true`. Deal-cluster failures are logged and the division is skipped.
- **Circuit breaker**: No.

## Consumed By

> Upstream consumers are tracked in the central architecture model. HotzoneGenerator is a batch initiator and has no inbound callers.

## Dependency Health

- No circuit breakers or retry logic are implemented. Most HTTP calls are wrapped in try/catch that either logs and continues (non-critical paths) or calls `System.exit(1)` for critical paths (hotzone insertion, campaign cleanup, send-log deletion).
- The Proximity API client ID (`proximity.clientId=ec-team`) is passed as a query parameter on all calls.
- Division coefficients are loaded from a classpath resource (baked into the jar), so GConfig is not called at runtime. Failure to load causes an empty map fallback (radius coefficient defaults to `1.0`).
