---
service: "deal"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 6
---

# Integrations

## Overview

The deal service has 8 downstream dependencies — 2 external (MapProxy/Mapbox, Gig Components) and 6 internal Continuum services. All integrations are synchronous HTTP calls issued at page render time. The service uses `itier-groupon-v2-client` as the primary client library for Groupon V2 backend APIs and `@grpn/graphql` for GraphQL-based endpoints.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MapProxy / Mapbox | REST | Renders merchant location map on deal page | no | > No evidence found in codebase. |
| Gig Components | REST | Renders gig-type (task/service) deal content blocks | no | > No evidence found in codebase. |

### MapProxy / Mapbox Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: MapProxy internal proxy to Mapbox APIs
- **Auth**: > No evidence found in codebase.
- **Purpose**: Provides map tile data for merchant location display on deal pages
- **Failure mode**: Map section degrades gracefully; page renders without map
- **Circuit breaker**: > No evidence found in codebase.

### Gig Components Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Internal Gig Components service
- **Auth**: > No evidence found in codebase.
- **Purpose**: Renders content blocks specific to gig-type deals (tasks, services)
- **Failure mode**: Gig content section omitted; remainder of deal page renders
- **Circuit breaker**: > No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Groupon V2 Client (Deal API) | REST | Fetches deal metadata, description, images, and options | > No evidence found in codebase. |
| Groupon V2 Client (Pricing API) | REST | Fetches deal pricing and discount data | > No evidence found in codebase. |
| Groupon V2 Client (Merchant API) | REST | Fetches merchant name, address, and contact info | > No evidence found in codebase. |
| Groupon V2 Client (Cart API) | REST | Adds deal to consumer cart (purchase flow) | > No evidence found in codebase. |
| Groupon V2 Client (Wishlists API) | REST | Reads and mutates consumer wishlist entries | > No evidence found in codebase. |
| GraphQL APIs | GraphQL/HTTP | Fetches supplemental deal and merchant data | > No evidence found in codebase. |
| Experimentation Service | REST | Assigns A/B test variants for experiment-gated features | > No evidence found in codebase. |
| Online Booking Service | REST | Fetches appointment availability slots for bookable deals | > No evidence found in codebase. |

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Known upstream consumers include:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon Web Browser (Consumer) | HTTP | Requests deal page HTML for display |
| Groupon Mobile App (Consumer) | HTTP | Requests deal page for mobile web view |
| Akamai CDN | HTTP | Caches and proxies deal page responses to consumers |

## Dependency Health

> No evidence found in codebase for explicit circuit breaker or retry configuration at the application layer. The `itier-server` framework provides standard timeout and error propagation patterns. If a downstream dependency fails, the deal page renders a partial response or error state depending on whether the dependency is critical to the primary render path.
