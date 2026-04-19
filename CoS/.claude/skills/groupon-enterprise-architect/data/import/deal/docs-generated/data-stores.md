---
service: "deal"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

The deal service is stateless and owns no data stores. All deal data, pricing, merchant information, cart state, and wishlist data is fetched at render time from downstream backend APIs via the Groupon V2 Client and GraphQL APIs. There is no local database, cache, or persistent storage layer within this service.

## Stores

> Not applicable. This service is stateless and does not own any data stores.

## Caches

> Not applicable. No application-level cache is owned by this service. CDN-level caching (Akamai) may apply to rendered pages upstream of this service.

## Data Flows

> Not applicable. No data flows between stores within this service. All data is fetched from upstream APIs per request and discarded after the HTTP response is sent.
