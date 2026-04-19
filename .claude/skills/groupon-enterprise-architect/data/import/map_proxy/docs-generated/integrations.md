---
service: "map_proxy"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 0
---

# Integrations

## Overview

MapProxy has two external upstream dependencies — Google Maps for Business and Yandex Maps — both reached via HTTPS redirect (HTTP 302). There are no internal Groupon service dependencies. MapProxy is consumed by multiple internal Groupon platforms (web, mobile, email, layout-service) as an inbound HTTP dependency, making it a shared internal infrastructure service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Maps Static API | HTTPS redirect | Serve static map images for non-Yandex geographies | yes | External |
| Google Maps JavaScript API | HTTPS redirect | Serve dynamic map JS loader for non-Yandex geographies | yes | External |
| Yandex Static Maps API | HTTPS redirect | Serve static map images for CIS geographies | yes | External |

---

### Google Maps Static API

- **Protocol**: HTTPS redirect (HTTP 302 from MapProxy to Google)
- **Base URL**: Configured via `MapProxy.google.domain` + `MapProxy.google.staticLibraryPath` (typically `https://maps.googleapis.com/maps/api/staticmap`)
- **Auth**: HMAC-SHA1 URL signing using `MapProxy.google.signingKey` (private key) and `MapProxy.google.clientID` (Google Maps for Business client ID). Signing is performed by `com.google.maps.UrlSigner` using the HMAC-SHA1 algorithm with web-safe Base64 encoding.
- **Purpose**: Fetch map tile images for static map requests originating from non-Yandex countries. MapProxy constructs the full Google Maps query string (center/zoom/size/markers/channel/client/maptype) and appends the HMAC signature before redirecting the caller.
- **Failure mode**: If signing fails (HMAC/URI error), MapProxy logs an HTTP 500 error line but does not return a response body. The caller receives a connection-close response. If Google Maps is unreachable, the caller's browser follows the 302 and receives a Google error directly.
- **Circuit breaker**: No evidence found in codebase.

---

### Google Maps JavaScript API

- **Protocol**: HTTPS redirect (HTTP 302)
- **Base URL**: Configured via `MapProxy.google.domain` + `MapProxy.google.dynamicLibraryPath` (typically `https://maps.googleapis.com/maps/api/js`)
- **Auth**: HMAC-SHA1 URL signing, same mechanism as static API. Dynamic library URL is pre-signed at startup in `GoogleV3Provider` constructor.
- **Purpose**: Serve the Google Maps JS API loader to browser clients for interactive (dynamic) map rendering. The signed URL includes the `client`, `v=3.exp`, and `callback=MapProxy.loadMxnGooglev3` parameters.
- **Failure mode**: Caller's browser follows the 302 and receives a Google error directly if the endpoint is unreachable.
- **Circuit breaker**: No evidence found in codebase.

---

### Yandex Static Maps API

- **Protocol**: HTTPS redirect (HTTP 302)
- **Base URL**: Configured via `MapProxy.yandex.staticLibraryUrl` (typically the Yandex Static Maps endpoint)
- **Auth**: No signing required for Yandex.
- **Purpose**: Serve static map images for CIS countries (the country is in the `MapProxy.yandex.countryList` configuration). MapProxy translates the Groupon-normalised marker format (with `pos`, `size`, `color`, `label` attributes) into Yandex's native marker notation and enforces Yandex's 450x650 pixel size constraint.
- **Failure mode**: Caller's browser follows the 302 and receives a Yandex error directly.
- **Circuit breaker**: No evidence found in codebase.

---

## Internal Dependencies

> No evidence found in codebase. MapProxy does not call any internal Groupon services.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon web platform (www.groupon.com) | HTTP/HTTPS | Static and dynamic maps on deal/merchant pages, checkout, voucher pages |
| Groupon mobile apps | HTTP/HTTPS | Map display on deal and location screens |
| Email platform | HTTP/HTTPS | Static map images embedded in deal/booking confirmation emails |
| layout-service | HTTP/HTTPS | Dynamic Google Maps JS loader (`/maps/api/js`) for page-level map initialisation |

> Full upstream consumer list is tracked in the central architecture model.

## Dependency Health

MapProxy does not implement circuit breakers or retry logic for its upstream provider dependencies. Since all responses are HTTP 302 redirects, the caller's browser is responsible for following the redirect to the provider. Provider outages are surfaced as errors in Wavefront and Kibana dashboards rather than handled in-process. The internal heartbeat mechanism (`/heartbeat`, `/status`) checks only local file presence, not external dependency health.
