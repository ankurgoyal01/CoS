---
service: "itier-mobile"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

`itier-mobile` has two external dependencies and two internal Groupon platform dependencies. The most critical external dependency is Twilio, which handles SMS delivery. All integrations are synchronous HTTP calls made within the request lifecycle. No event-driven or batch integrations exist.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Twilio | REST (HTTPS) | Sends SMS messages containing app download or deep-link URLs to users' phones | Yes | `twilio` (stub) |
| Kochava | HTTP redirect | Third-party iOS attribution tracking; `grpn_dl` query param maps to Kochava campaign links stored in `modules/mobile/DownloadLinks.js` | No | No DSL ref |

### Twilio Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: `twilio` npm package `^3.59.0`; credentials held in `itier_shared_user_secrets` repo (not in this codebase)
- **Auth**: Twilio Account SID and Auth Token (secrets, not documented here)
- **Purpose**: Delivers SMS messages containing Groupon app download links or deep-links when a user submits their phone number on the `/mobile` page
- **Failure mode**: SMS send errors are logged (`[TWILIO-ERRORS]`); the user receives an error response but the HTTP request itself completes. Sender number issues may require swapping phone numbers in code and redeploying.
- **Circuit breaker**: No evidence found in codebase

### Kochava Detail

- **Protocol**: HTTP redirect (302)
- **Base URL / SDK**: Kochava campaign URLs stored statically in `modules/mobile/DownloadLinks.js`
- **Auth**: No auth; campaign links are public redirect URLs
- **Purpose**: iOS app download attribution tracking; `grpn_dl` query parameter selects the Kochava campaign link so Apple App Store downloads are attributed to the correct marketing campaign
- **Failure mode**: Falls back to direct App Store URL if no Kochava link is configured for the given `grpn_dl` value
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| layout-service | REST (HTTPS) | Provides page scaffold/layout for rendered HTML pages (intercept, mobile landing, subscription) | Declared in `.service.yml` dependencies |
| conveyor-cloud | Platform | Kubernetes-based container hosting, deployment, and scaling | Declared in `.service.yml` dependencies |

### layout-service Detail

- **Protocol**: REST (HTTPS) via `remote-layout ^10.12.1`
- **Purpose**: Fetches the global page layout shell (header/footer) that wraps rendered HTML responses
- **Failure mode**: Page renders may degrade to layout-less responses if layout-service is unavailable
- **Circuit breaker**: No evidence found in codebase; handled by `gofer` HTTP client timeout (`timeout: 10000ms`, `connectTimeout: 1000ms`)

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Web browsers (desktop and mobile) | HTTPS | Access `/mobile`, `/dispatch`, `/subscription`, and association file endpoints |
| Groupon native iOS/Android apps | HTTPS / Universal Links / App Links | Resolve deep-link dispatch routes; fetch Apple/Android association files on app install |
| Akamai CDN | HTTPS | Caches static assets and association files; forwards dynamic requests |
| routing-service (GROUT) | HTTP proxy | Routes public traffic from `www.groupon.*` domains to the Hybrid Boundary endpoints of this service |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- Service-level timeout: `connectTimeout: 1000ms`, `timeout: 10000ms` (from `config/base.cson` `serviceClient.globalDefaults`)
- Max sockets per upstream: `maxSockets: 100`
- No circuit breaker or retry configuration found in the codebase
- Twilio health is monitored via the Twilio status page (http://status.twilio.com/) and internal Wavefront dashboards
