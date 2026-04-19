---
service: "janus-ui-cloud"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Janus UI Cloud has one internal dependency (the Janus metadata service) and one external dependency (Google Tag Manager). The gateway container proxies all metadata API traffic to the internal service. The frontend loads analytics tags from the external CDN. There are no message bus integrations or database connections.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Tag Manager | HTTPS | Loads web analytics and tracking tag scripts into the browser | no | `googleTagManager` |

### Google Tag Manager Detail

- **Protocol**: HTTPS (browser-side CDN load)
- **Base URL / SDK**: Google Tag Manager CDN (loaded via script tag in the SPA shell)
- **Auth**: None (public CDN)
- **Purpose**: Delivers analytics and tracking tags to the browser for user behaviour measurement
- **Failure mode**: If GTM is unavailable the analytics script fails silently; the UI continues to function normally
- **Circuit breaker**: No — browser handles the failure transparently

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Janus Web Cloud Metadata Service | HTTP/HTTPS | Provides all persistence and business logic for Janus rule management; all UI CRUD operations are forwarded here | `continuumJanusWebCloudService` |

### Janus Web Cloud Metadata Service Detail

- **Protocol**: HTTP/HTTPS (proxied via Express `http-proxy` middleware on the Gateway)
- **Routing**: All requests matching `/api/*` in the browser are forwarded to the environment-specific Janus metadata endpoint
- **Auth**: Session cookies are propagated through the proxy
- **Purpose**: Stores and serves all schema definitions, canonical mappings, attribute configurations, UDFs, destinations, subscribers, alert rules, and user records that the UI displays and edits
- **Failure mode**: If the metadata service is unavailable, all UI data views return empty or error states; the SPA shell itself remains loadable from cached static assets
- **Circuit breaker**: No evidence of circuit breaker configuration in this repository

## Consumed By

> Upstream consumers are tracked in the central architecture model. Janus UI Cloud is consumed directly by browser users (internal data engineers and platform operators). No machine-to-machine callers consume this service.

## Dependency Health

The deployment configuration (`common.yml`) configures HTTP readiness and liveness probes against port 8080 at path `/`. These probes verify that the Express gateway is accepting connections but do not directly validate connectivity to the upstream metadata service. No explicit retry or circuit breaker patterns for the `continuumJanusWebCloudService` dependency are visible in the codebase.
