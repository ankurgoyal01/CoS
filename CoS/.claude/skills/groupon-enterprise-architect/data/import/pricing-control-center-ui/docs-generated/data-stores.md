---
service: "pricing-control-center-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. All pricing data, sale records, and user information are retrieved at request time from the `pricing-control-center-jtier` backend API. The only client-side state this service manages is short-lived browser cookie data:

- `authn_token` cookie: Doorman-issued authentication token, max-age 6 hours, set on `/post-user-auth-token` callback.
- `user` cookie: JSON-serialised user profile object (`email`, `firstName`, `lastName`, `role`, `channels`), max-age 6 hours, set after identity lookup against jtier.

## Stores

> No evidence found in codebase. This service is stateless and does not own any data stores.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `authn_token` | HTTP cookie (browser) | Stores Doorman authentication token to avoid repeated SSO redirects | 6 hours (21,600,000 ms) |
| `user` | HTTP cookie (browser) | Stores user identity (email, name, role, channels) to avoid repeated jtier identity lookups | 6 hours (21,600,000 ms) |

Note: The base config (`config/base.cson`) references a `birdcage` service client with `baseUrl: false` (disabled) and a `localize` client also set to `baseUrl: false`. No memcached or Redis integration is configured for application caching. Integration tests do start a memcached daemon (`memcached -d -u memcached && npm run test:integration`) suggesting the iTier framework may optionally use it, but no application-level memcached usage is evidenced in this service's code.

## Data Flows

All data originates in `pricing-control-center-jtier`. This UI fetches data synchronously per request and returns it to the browser rendered as HTML or JSON. No ETL, CDC, or replication patterns are used.
