---
service: "pull"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Pull is a pure SSR rendering application — it fetches all data at request time from upstream services (`continuumRelevanceApi`, `apiProxy`, `continuumLayoutService`, `continuumLpapiService`, `continuumUgcService`, `continuumWishlistService`, `continuumGeoPlacesService`, `continuumBirdcageService`) and renders it into HTML responses. No data is persisted by Pull itself.

## Stores

> Not applicable. Pull does not own or manage any databases, caches, or object stores.

## Caches

> No evidence found. Pull does not own a dedicated cache layer. Any caching of upstream API responses is handled within `@tanstack/react-query` as an in-process, request-scoped mechanism rather than a persistent shared cache.

## Data Flows

> Not applicable. Pull is stateless — data flows inbound from upstream APIs per request and outbound as rendered HTML. No ETL, CDC, or replication patterns are used.
