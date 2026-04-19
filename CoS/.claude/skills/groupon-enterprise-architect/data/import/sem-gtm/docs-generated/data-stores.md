---
service: "sem-gtm"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

`sem-gtm` is stateless at the Groupon infrastructure level. It does not own or directly manage any databases, caches, or persistent storage. The GTM Cloud image maintains its own internal ephemeral state for active preview sessions within the container's memory, but this state is not persisted across pod restarts. Tag configuration state is stored and versioned externally in Google's Tag Manager platform, loaded at startup via `CONTAINER_CONFIG`.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. No Groupon-managed cache (Redis, Memcached, etc.) is configured.

## Data Flows

Tag configuration data is pulled from Google's GTM platform at container startup using the `CONTAINER_CONFIG` credential bundle. Incoming tag event payloads are processed in-memory by the GTM runtime and forwarded to configured tag destinations (Google Analytics, Google Ads, etc.) without being persisted locally.
