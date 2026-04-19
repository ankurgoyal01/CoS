---
service: "place-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

The M3 Place Service integrates with one external third-party system (Google Maps) and two internal Groupon platform dependencies (M3 Merchant Service and Voltron). It also depends on three data stores (Postgres, OpenSearch, Redis) documented in [Data Stores](data-stores.md). Upstream consumers are internal Groupon services identified by a registered `client_id`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Maps Places API | HTTPS/REST (SDK) | Look up Google place candidates for geo-enrichment of M3 places | no | `googleMaps` |

### Google Maps Places API Detail

- **Protocol**: HTTPS via `google-maps-services` Java SDK (version 2.0.0)
- **Base URL / SDK**: `com.google.maps:google-maps-services:2.0.0` — uses `GeoApiContext` with `PlacesApi.findPlaceFromText()`
- **Auth**: API key configured via `google_places_api_key` (read from `ConfigProvider` / config-central at startup)
- **Purpose**: Given a place's address and merchant name, queries Google Maps Find Place From Text to retrieve Google place candidates (place ID, formatted address, name, lat/lng). Results are cached in Redis.
- **Fields requested**: `FORMATTED_ADDRESS`, `GEOMETRY`, `NAME`, `PLACE_ID`
- **Failure mode**: `InternalServerException` thrown on API error; returns null response if place or location data is missing. Metrics emitted via `MetricUtil.submitHTTPOutMetrics`.
- **Circuit breaker**: No evidence of circuit breaker configuration in this codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| M3 Merchant Service | HTTPS/JSON | Fetches merchant metadata to enrich place responses when merchant details are requested by the caller | `continuumM3MerchantService` |
| Voltron Platform | RPC/HTTP | Invokes Voltron workflow tasks for place processing, write orchestration, and history record retrieval | Voltron platform (not in federated model) |

### M3 Merchant Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Configured via `M3MerchantClient` (`src/main/java/com/groupon/m3/placereadservice/client/M3MerchantClient.java`)
- **Auth**: Internal service-to-service (internal network)
- **Purpose**: Loads merchant details associated with a place when the caller's `client_id` or request parameters require merchant enrichment in the response
- **Failure mode**: Place response can degrade gracefully without merchant data
- **Circuit breaker**: No evidence of explicit circuit breaker in this codebase

### Voltron Platform Detail

- **Protocol**: RPC/HTTP via `voltron-tasks` (version 7.0.53) and `voltron-shared` (version 4.0.6)
- **Auth**: Internal
- **Purpose**: Invokes Voltron workflow tasks for place write processing (transformation from ICF to M3 format) and retrieval of place history records
- **Failure mode**: `VoltronRejectedInputException` and `VoltronSynchronousException` are defined; write pipeline can return errors to caller on Voltron failure

## Consumed By

> Upstream consumers are tracked in the central architecture model. All callers must supply a registered `client_id` query parameter. Known caller patterns include internal deal services, merchant tools, and consumer APIs that require place metadata.

## Dependency Health

- **Google Maps**: Failure results in an `InternalServerException` logged with place ID. No automatic retry or circuit breaker configured; Google candidate cache in Redis reduces dependency on live API calls.
- **M3 Merchant Service**: Place responses degrade gracefully if merchant enrichment is unavailable.
- **Voltron**: Write operations return error responses (`VoltronRejectedInputException`, `VoltronSynchronousException`) to the caller on failure.
- **Postgres**: Monitored via DaaS Dashboard (NA and EU links in `.service.yml`); loss of Postgres causes read failures that fall back to OpenSearch index.
- **OpenSearch**: Monitored via application and ELK dashboards; loss of OpenSearch degrades search and count capabilities.
- **Redis**: Monitored via RaaS Dashboard (NA and EU links in `.service.yml`); Redis failure causes cache misses that increase load on Postgres/OpenSearch.
