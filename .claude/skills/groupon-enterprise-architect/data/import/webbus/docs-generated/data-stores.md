---
service: "webbus"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Webbus is fully stateless and owns no data stores. It holds no persistent state between requests. All runtime state lives in memory for the duration of a single request-response cycle. The `messagebus` client connection is initialised lazily and held in a module-level instance variable for connection reuse across requests, but no data is persisted to disk or an external store.

The owners manual explicitly states: **Data store: N/A** and **Cache Information: N/A**.

## Stores

> Not applicable — this service is stateless and does not own any data stores.

## Caches

> Not applicable — no caching layer is configured. There is no Redis, Memcached, or in-memory cache. The `config/clients.yml` allowlist is loaded once at startup and held in memory as a module-level variable (`@clients`), but this is configuration loading rather than a cache.

## Data Flows

> Not applicable — no data store means no inter-store data flows. Messages received via HTTP are forwarded to the Message Bus synchronously within the same request and are not persisted by this service.
