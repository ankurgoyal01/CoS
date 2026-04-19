---
service: "itier-tpp"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

I-Tier TPP is a stateless web application and does not own any data stores. All persistent partner, merchant, deal, and configuration data is managed by downstream services:

- **Partner Service (PAPI)** — authoritative store for partner configurations, onboarding configurations, and merchant mappings
- **Deal Catalog Service** — authoritative store for deal history and catalog data
- **API Lazlo / Groupon V2** — authoritative store for Groupon deal and entity data
- **Geo Details Service** — authoritative store for division and location metadata

The portal reads and writes to these services via synchronous REST calls; it holds no data of its own beyond the in-process request context.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found of caching layers owned by this service. No Redis, Memcached, or in-memory cache is configured in the service's own infrastructure. The `remote-layout` library may cache shared layout fragments in memory within the Node.js process for the duration of the process lifetime.

## Data Flows

All data enters and exits through synchronous REST calls:

- Inbound: authenticated HTTP requests from operations staff or merchant users via the portal UI
- Outbound reads: `continuumTppWebApp` queries `continuumPartnerService`, `continuumApiLazloService`, `continuumDealCatalogService`, and `continuumGeoDetailsService` to populate page data
- Outbound writes: `continuumTppWebApp` sends mutations to `continuumPartnerService`, `bookerApi`, and `mindbodyApi` in response to user form submissions

No ETL, CDC, or replication patterns are present.
