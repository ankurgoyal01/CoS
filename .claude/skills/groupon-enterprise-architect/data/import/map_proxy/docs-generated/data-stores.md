---
service: "map_proxy"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. MapProxy holds no persistent state — all request handling results in either an HTTP redirect to an upstream provider or an inline JavaScript response assembled from classpath resources. There is no database, cache, or file store dependency at runtime.

The only file-system dependency is the heartbeat file at the path configured by `MapProxy.heartbeatFile` (typically `/usr/local/mapproxy_service/heartbeat.txt`), which is read (not written) by the `StatusServlet` to determine health status. This is an operational marker file managed by the deployment process, not a data store.

## Stores

> Not applicable. No data stores owned or operated by this service.

## Caches

> No evidence found in codebase. No in-memory or external caching layer is used.

## Data Flows

> Not applicable. The service is stateless; no data flows between stores.
