---
service: "map_proxy"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMapProxyService"]
---

# Architecture Context

## System Context

MapProxy sits within the `continuumSystem` (Continuum Platform) as a single-container service. It acts as an internal gateway: Groupon's web, mobile, and email platforms send map requests to MapProxy rather than calling Google Maps or Yandex directly. MapProxy normalises the request, selects the appropriate provider by geography, signs the upstream URL, and responds with an HTTP 302 redirect. There are no inter-container dependencies within Continuum — MapProxy is a single-purpose, stateless service that has two upstream external API dependencies (Google Maps and Yandex Maps).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Map Proxy Service | `continuumMapProxyService` | Backend service | Java 8, Jetty | 1.0.x | Java Jetty servlet service that serves Groupon static and dynamic map endpoints, selecting map providers by geography and signing provider requests. |

## Components by Container

### Map Proxy Service (`continuumMapProxyService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Ingress Servlets (`mapProxy_requestIngress`) | Servlet endpoints for `/maps/api/staticmap`, `/maps/api/js`, `/api/v2/static`, `/api/v2/dynamic`, `/status`, `/heartbeat`, `/changelog`, and tracking routes. Validates required parameters and delegates to provider selection or asset composition. | Java Servlets (StaticMapsServlet, DynamicMapsServlet, StaticMapsV2Servlet, DynamicMapsV2Servlet) |
| Provider Selection (`mapProxy_providerSelection`) | Country- and header-based logic that determines whether the request should be routed to Google V3 or Yandex V2. Resolution order: `country` query param → `X-Country` header → Referer TLD → Host header. Defaults to Google if country is blank or not in the Yandex country list. | MapProvider abstract class |
| Google Maps Adapter (`mapProxy_googleAdapter`) | Builds the signed Google Maps Static API URL including `client`, `channel`, `maptype`, `size`, `center`, `zoom`, and `markers` parameters. Signs the request using HMAC-SHA1 via UrlSigner. Also constructs the signed dynamic Maps JavaScript API URL. | GoogleV3Provider + UrlSigner |
| Yandex Maps Adapter (`mapProxy_yandexAdapter`) | Builds the Yandex Static Maps API URL, translating marker formats and enforcing Yandex size constraints (max 450x650). No signing required for Yandex. | YandexV2Provider |
| Dynamic JS Composer (`mapProxy_assetComposer`) | For the v2 dynamic endpoint, loads JS templates and provider-specific libraries from the classpath, injects the signed provider library URL, static files base URL, and callback function name, and emits a composite JavaScript payload to the caller. | Classpath Resource Loader (DynamicMapsV2Servlet) |
| Operational Endpoints (`mapProxy_operationalEndpoints`) | Heartbeat/status checks (reads `heartbeat.txt` file; returns 200 if present, 404 if absent) and request tracking logs for service health and diagnostics. | StatusServlet + TrackingServlet |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `mapProxy_requestIngress` | `mapProxy_providerSelection` | Selects map provider by country, headers, and request context | Java method call |
| `mapProxy_requestIngress` | `mapProxy_assetComposer` | Builds dynamic JavaScript map response payloads | Java method call |
| `mapProxy_requestIngress` | `mapProxy_operationalEndpoints` | Captures health checks and request tracking | Java method call |
| `mapProxy_providerSelection` | `mapProxy_googleAdapter` | Routes Google map requests | Java method call |
| `mapProxy_providerSelection` | `mapProxy_yandexAdapter` | Routes Yandex map requests | Java method call |
| `continuumMapProxyService` | Google Maps API | Redirects signed static/dynamic map requests | HTTPS HTTP 302 |
| `continuumMapProxyService` | Yandex Maps API | Redirects Yandex static map requests | HTTPS HTTP 302 |

## Architecture Diagram References

- Component view: `components-continuum-map-proxy-service`
- Dynamic view (static map request): `dynamic-map-proxy-static-request`
