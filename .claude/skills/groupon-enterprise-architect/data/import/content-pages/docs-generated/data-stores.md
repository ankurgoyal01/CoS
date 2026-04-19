---
service: "content-pages"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "in-memory-cache"
    type: "in-memory"
    purpose: "In-process response caching via itier-cached"
---

# Data Stores

## Overview

This service does not own any persistent data stores. All page content is sourced from an upstream Content Pages GraphQL API. A Memcached cache integration is referenced in the DSL (stub-only) for caching legal and static pages, but it is not present in the federated central model. The only confirmed in-process caching is provided by `itier-cached` (in-memory, process-lifetime).

## Stores

> This service is stateless and does not own any data stores.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `itier-cached` in-memory cache | in-memory | Caches CMS content API responses within the Node.js process to reduce upstream GraphQL API calls | Process-lifetime / request-scoped |
| Memcached (external) | memcached | External cache for legal and static page content (stub-only; not modeled in central architecture) | Not discoverable |

## Data Flows

All page content flows inbound from the Content Pages GraphQL API and is rendered server-side on each request (subject to in-process caching). Incident report images uploaded by users flow outbound to `continuumImageService` and are stored there. Incident and infringement report data flows outbound to Rocketman Email Service as email payloads. No persistent state is written or owned by this service.
