---
service: "bhuvan"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

Bhuvan has three external HTTP dependencies for geo data enrichment (Google Maps/MapTiler/Avalara, Bhoomi geocoding, and the Optimize/Finch experimentation platform) and one internal infrastructure dependency (daas_postgres for managed Postgres). External HTTP clients are built using the JTier Retrofit wrapper. No message bus dependencies exist.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Maps & Address Provider APIs (Google Maps, MapTiler, Avalara) | REST/HTTP | Address normalization, geocoding, place details, timezone, autocomplete | yes | `continuumMapsProviderApis` |
| Bhoomi Geocoding Service | REST/HTTP | IP address to lat/lng coordinate resolution | yes | `continuumBhoomiService` |
| Experimentation Service (Optimize / Finch / Expy) | REST/HTTP | A/B experiment bucketing for autocomplete and geo behavior | no | `continuumExperimentationService` |

### Maps & Address Provider APIs Detail

- **Protocol**: REST/HTTP JSON
- **Base URL / SDK**: `geolib-google` (v0.1.36), `geolib-avs` (v0.1.36) geolib client libraries via JTier Retrofit
- **Auth**: API keys (managed via secrets/config; not documented here)
- **Purpose**: Provides geocoding (address to coordinate), reverse geocoding, place details, autocomplete suggestions, address validation (Avalara), and timezone resolution for the `GeoDetailsService` when internal data is insufficient.
- **Failure mode**: GeoDetailsService falls back to cached results or returns a degraded response when external providers are unavailable.
- **Circuit breaker**: Not explicitly evidenced; JTier Retrofit provides timeout configuration.

### Bhoomi Geocoding Service Detail

- **Protocol**: REST/HTTP JSON
- **Base URL / SDK**: `BhoomiClient` via `jtier-retrofit`; service registered as dependency `raas` in `.service.yml`
- **Auth**: Internal service-to-service (no public auth required)
- **Purpose**: Resolves IP addresses to geographic coordinates when the MaxMind local database cannot resolve an IP. Used by `BhoomiClientService` within `GeoDetailsService`.
- **Failure mode**: IP geolocation returns `null` or falls back to a default location.
- **Circuit breaker**: Not explicitly evidenced.

### Experimentation Service (Optimize / Finch / Expy) Detail

- **Protocol**: REST/HTTP JSON (or local datafile evaluation)
- **Base URL / SDK**: `finch` library (v4.0.33); `ExperimentationFactory` / `ExperimentationService`
- **Auth**: Internal service token
- **Purpose**: Buckets incoming requests into A/B experiment variants to control autocomplete behavior tuning and other geo-related experiments.
- **Failure mode**: Service operates without experiment overrides; default behavior applies.
- **Circuit breaker**: Not explicitly evidenced; Finch supports local datafile fallback.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS Postgres | Postgres (JDBI3) | Managed Postgres connection pool and provisioning | `continuumBhuvanPostgres` |
| Redis (RaaS) | Redis (Lettuce) | Managed Redis cluster for caching and spatial index | `continuumBhuvanRedisCluster` |

> Note: `daas_postgres` and `raas` are listed as service dependencies in `.service.yml`. The Postgres and Redis clusters are infrastructure services managed by Groupon's Data-as-a-Service (DaaS) and Redis-as-a-Service (RaaS) platforms.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Bhuvan is an internal service consumed by other Groupon services requiring geo entity resolution, location detection, or address/autocomplete capabilities (e.g., commerce, deal, and frontend services within the Continuum platform).

## Dependency Health

- **Postgres**: The JTier DaaS Postgres connection pool manages connection health. The `jtier-daas-postgres` library handles pool lifecycle and failover.
- **Redis**: Lettuce async client with Redis Memorystore. Health is tracked via the Dropwizard health check endpoint (`/grpn/healthcheck`).
- **ElasticSearch**: ElasticSearch REST client (v8.12.1) connects to the managed cluster. No explicit circuit breaker evidenced; timeouts are configured at client level.
- **External APIs**: HTTP calls to Google/MapTiler/Avalara/Bhoomi use JTier Retrofit with configurable timeouts. No explicit circuit breaker pattern evidenced.
- **MaxMind**: In-process file read; no network calls — no health dependency.
