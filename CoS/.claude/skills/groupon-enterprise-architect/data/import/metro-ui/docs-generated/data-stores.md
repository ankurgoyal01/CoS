---
service: "metro-ui"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Metro UI delegates all persistent data operations to downstream services: deal data is stored and managed by `continuumDealManagementApi`, geo and place data is owned by `continuumGeoDetailsService` and `continuumM3PlacesService`, and campaign/eligibility data is managed by `continuumMarketingDealService`.

## Stores

> Not applicable — Metro UI owns no databases, object stores, or caches.

## Caches

> No evidence found of any in-process or external cache (Redis, Memcached, etc.) owned or managed by this service.

## Data Flows

All data read and write operations flow through outbound HTTPS/JSON calls from `metroUi_integrationAdapters` to:

- `continuumDealManagementApi` — deal records, drafts, deal metadata
- `continuumGeoDetailsService` — geo autocomplete and place detail lookups
- `continuumM3PlacesService` — merchant place records
- `continuumMarketingDealService` — campaign and merchant eligibility data

No CDC, ETL, or replication patterns are owned by this service.
