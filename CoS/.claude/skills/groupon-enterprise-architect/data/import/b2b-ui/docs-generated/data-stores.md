---
service: "b2b-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. The RBAC UI is a pure frontend/BFF application. All persistent data (roles, permissions, categories, user accounts) is owned and stored by downstream services (`continuumRbacService`, `continuumUsersService`). The service writes structured log output to `/var/groupon/logs/steno.log` via Filebeat for log shipping, but does not own a database, cache, or object store.

## Stores

> Not applicable — this service owns no data stores.

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-memory cache is configured. Session state is maintained via the auth cookie parsed by the Session Middleware component on each request.

## Data Flows

> Not applicable — data flows are handled by downstream services. The RBAC UI forwards browser requests to `continuumRbacService` and `continuumUsersService` and returns their responses to the client unchanged.
