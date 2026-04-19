---
service: "content-pages"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

The Content Pages service depends on four downstream systems: a Content Pages GraphQL API (external CMS), Image Service, Rocketman Email Service, and a Routing Service. Image Service is the only fully modeled relationship in the central architecture (`continuumImageService`). The GraphQL API, Rocketman, and Routing Service are referenced in the DSL as stubs. No upstream consumers are identifiable from the service's own architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Content Pages GraphQL API | HTTPS/JSON (GraphQL) | Fetches legal and static page content for rendering | yes | stub-only (`externalGrouponApiGateway_9c3e`) |
| Groupon CDN | HTTPS | Serves static compiled assets to browser clients | no | stub-only (`externalGrouponCdn_8c2b`) |

### Content Pages GraphQL API Detail

- **Protocol**: HTTPS/JSON (GraphQL queries)
- **Base URL / SDK**: `itier-groupon-v2-content-pages` client (v1.0.6)
- **Auth**: Internal service credentials
- **Purpose**: Provides the CMS-managed content for all `/pages/*`, `/legal/*`, `/privacy-hub`, and `/cookie-consent` pages
- **Failure mode**: Content pages cannot be rendered; error page displayed
- **Circuit breaker**: No evidence found; in-memory cache via `itier-cached` provides partial mitigation for repeated requests

### Groupon CDN Detail

- **Protocol**: HTTPS (static asset delivery)
- **Base URL / SDK**: Configured CDN origin
- **Auth**: None (public assets)
- **Purpose**: Delivers webpack-compiled JavaScript and CSS bundles to browser clients
- **Failure mode**: Client-side assets fail to load; page rendering may degrade
- **Circuit breaker**: Not applicable (CDN is one-way outbound delivery)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Image Service | HTTPS | Validates and stores uploaded incident report images | `continuumImageService` |
| Rocketman Email Service | HTTPS | Sends incident and infringement notification emails via `@grpn/rocketman-client` | stub-only (`externalRocketmanEmail_7f2a`) |
| Memcached Cache | Memcached | Caches static and legal page responses (stub-only) | stub-only (`externalMemcachedCache_4da1`) |

### Image Service (`continuumImageService`) Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `image-service-client` v2.1.4
- **Auth**: Internal service credentials
- **Purpose**: Receives multipart image uploads from incident report form submissions; stores images and returns a reference URL
- **Failure mode**: Image upload step fails; incident report submission may be blocked or submitted without image
- **Circuit breaker**: No evidence found

### Rocketman Email Service Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `@grpn/rocketman-client` v1.0.7
- **Auth**: Internal service credentials
- **Purpose**: Delivers incident report and infringement report notification emails to Groupon operations teams
- **Failure mode**: Notification email not sent; report may still be received but operators not alerted
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is consumed directly by end-user browsers and by Groupon's routing/CDN layer serving `/pages/*`, `/legal/*`, `/privacy-hub`, `/cookie-consent`, `/report_incident`, and `/report_infringement` URL paths.

## Dependency Health

- `continuumImageService` is the only modeled outbound dependency in the central architecture
- In-memory caching via `itier-cached` reduces load on the Content Pages GraphQL API
- `itier-instrumentation` (v9.13.4) provides in-service observability for downstream call latency and errors
