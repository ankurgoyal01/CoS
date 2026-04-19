---
service: "itier-3pip-docs"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

`itier-3pip-docs` is a stateless web application. It does not own or directly manage any persistent data stores (no database, cache, or object storage). All partner configuration and onboarding data is owned and stored by the Partner API (PAPI) backend, which this service queries via GraphQL. Deal data is owned by the Lazlo/GAPI service. Session state is maintained via cookies managed by `continuumUsersService`.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. No application-level cache (Redis, Memcached, or in-memory) is configured. Static assets are served via CDN (Groupon CDN hosts configured as `staging<1,2>.grouponcdn.com` and `www<1,2>.grouponcdn.com` in `config/base.cson`).

## Data Flows

All data flows for this service are synchronous and pass-through:

- **Partner configuration data**: Fetched at request time from PAPI via GraphQL (`@grpn/graphql-papi`) and returned directly to the frontend.
- **Deal data**: Fetched at request time from `continuumApiLazloService` via `@grpn/api-lazlo-client` for deal enrichment during test-deal setup.
- **Simulator logs**: Fetched at request time from PAPI via GraphQL (`PAPI_simulatorLogs` query).
- **Uptime metrics**: Fetched at request time from PAPI via GraphQL (`PAPI_partnerUptime` query).
- **Application logs**: Written to disk (`/var/groupon/logs/steno.log.*`) and shipped to Kafka by the Filebeat sidecar for downstream log aggregation.
