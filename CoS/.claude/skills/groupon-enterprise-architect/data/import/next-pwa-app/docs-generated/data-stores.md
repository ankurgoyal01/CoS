---
service: "next-pwa-app"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "redis-cache"
    type: "redis"
    purpose: "Server-side page/data caching"
  - id: "maxmind-geoip"
    type: "file"
    purpose: "IP geolocation database"
  - id: "next-cache"
    type: "file"
    purpose: "Next.js ISR and data cache"
---

# Data Stores

## Overview

next-pwa-app is primarily a stateless frontend application. It does not own a persistent database. Data storage is limited to caching layers (Redis for server-side caching, Next.js file-based cache for ISR/SSG pages) and static data files (MaxMind GeoIP database, pre-built taxonomy/ratings data).

## Stores

### Redis Cache (`redis-cache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | -- (infrastructure-level, not modeled as a container) |
| Purpose | Server-side page and data caching via `@neshca/cache-handler` |
| Ownership | shared (infrastructure-provided) |
| Migrations path | N/A |

#### Access Patterns

- **Read**: Cache lookups for ISR pages and API responses during SSR
- **Write**: Cache population on page render and data fetch
- **Configuration**: `REDIS_CONNECTION_URL` environment variable (empty by default, falling back to in-memory cache)

### MaxMind GeoIP Database (`maxmind-geoip`)

| Property | Value |
|----------|-------|
| Type | File (MMDB binary) |
| Architecture ref | -- |
| Purpose | IP-based geolocation for locale and division detection |
| Ownership | external (MaxMind) |
| Migrations path | N/A (pulled at build time via `pull-maxmind-db` script) |

#### Access Patterns

- **Read**: Looked up per-request in middleware/SSR for geo-details resolution
- **Write**: Downloaded during Docker build, copied into standalone output

### Next.js Cache (`next-cache`)

| Property | Value |
|----------|-------|
| Type | File system / custom cache handler |
| Architecture ref | -- |
| Purpose | ISR page cache, React Server Component cache, data cache |
| Ownership | owned |
| Migrations path | N/A |

#### Access Patterns

- **Read**: Automatic cache lookups by Next.js for static and ISR pages
- **Write**: Automatic cache population after page generation
- **Configuration**: Custom cache handler at `apps/next-pwa/util/next-cache-handler/index.js`, `cacheMaxMemorySize: 0` (disables in-memory cache in favor of the handler)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis (REDIS_CONNECTION_URL) | redis | Server-side ISR/data cache | Varies by page type |
| Next.js file cache | file system | ISR revalidation cache | Per-page revalidation interval |
| Apollo Client in-memory cache | in-memory (browser) | Client-side GraphQL response cache | Session lifetime |

## Data Flows

Static taxonomy data (categories, merchandising tags, deal attributes, ratings) is pre-built at build time into `libs/static/` and bundled with the application. The MaxMind GeoIP database is downloaded at Docker build time and copied into the runtime image. No CDC, ETL, or replication patterns exist within this service.
