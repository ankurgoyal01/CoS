---
service: "clo-ita"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. `clo-ita` is a BFF that aggregates responses from downstream Continuum services. It persists no user, claim, enrollment, or transaction data directly.

## Stores

> Not applicable

## Caches

`clo-ita` uses `itier-cached` to apply Redis-backed response caching for eligible downstream responses. The cache is not owned by this service — it is a shared infrastructure component provided by the itier platform.

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| itier-cached (Redis) | redis | Short-lived caching of downstream API responses to reduce latency and backend load | Managed by itier-cached configuration |

## Data Flows

> Not applicable — no primary store owned. Data flows entirely through synchronous downstream API calls on each request.
