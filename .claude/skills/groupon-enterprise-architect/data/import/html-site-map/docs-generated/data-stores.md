---
service: "html-site-map"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

html-site-map is a stateless service. It does not own or operate any databases, caches, or persistent storage. All geographic and category data required to render sitemap pages is fetched at request time from LPAPI (`continuumApiLazloService`) and is not locally persisted or cached between requests. Static assets (CSS, JS) are served from the Groupon CDN (`www<1,2>.grouponcdn.com` in production) and are not stored by this service.

## Stores

> Not applicable — this service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase.

The `itier-cached` library (version 8.1.3) is present as a dependency in `package.json` as part of the itier framework suite, but no application-level cache configuration was found in `config/base.cson` or any stage config files. No Redis, Memcached, or in-memory cache is configured by this service.

## Data Flows

All data originates from LPAPI at page-request time:

1. A browser or crawler requests a sitemap page.
2. The appropriate route handler calls LPAPI's `getPage` endpoint, passing a locale and crosslink type.
3. LPAPI returns crosslinks (location or category links) and location metadata.
4. The LPAPI Client Adapter formats the crosslinks into a normalized array for the view layer.
5. The Server-side Renderer composes the formatted data into an HTML response.
6. No data is written to any store; the response is returned immediately.
