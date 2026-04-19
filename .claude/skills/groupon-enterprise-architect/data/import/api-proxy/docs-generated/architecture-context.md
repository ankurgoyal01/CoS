---
service: "api-proxy"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["apiProxy", "continuumApiProxyRedis"]
---

# Architecture Context

## System Context

API Proxy sits at the outermost edge of the Continuum platform, directly receiving traffic from all Groupon client applications — legacy Android, legacy iOS, legacy web, and Merchant Center. It is the sole entry point through which consumer and merchant API calls reach backend Continuum services. Within the broader Groupon architecture it operates as an `Internal` container inside `continuumSystem`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| API Proxy | `apiProxy` | Gateway | Java / Vert.x / Netty | 3.5.4 / 4.1.19 | Edge gateway that routes client applications to aggregation APIs; executes filter chain for auth, rate limiting, and policy enforcement |
| API Proxy Redis | `continuumApiProxyRedis` | Cache / Data store | Redis | — | Distributed Redis store used for shared rate-limit counters and throttling state |

## Components by Container

### API Proxy (`apiProxy`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Router (`apiProxy_requestRouter`) | Accepts inbound HTTP requests and dispatches them through configured route and filter processing | Java |
| Filter Chain Engine (`apiProxy_filterChainEngine`) | Executes ordered request/response filters for routing, auth, redirects, and policy enforcement | Java |
| Route Config Loader (`apiProxy_routeConfigLoader`) | Loads and refreshes route configuration used to resolve destination mappings and filter directives | Java |
| Client ID Loader (`apiProxy_clientIdLoader`) | Fetches and caches client identification settings and credentials from external configuration endpoints | Java |
| Rate Limiter (`apiProxy_rateLimiter`) | Applies global and client-level throttling decisions during request handling | Java |
| reCAPTCHA Client (`apiProxy_recaptchaClient`) | Calls Google reCAPTCHA verification endpoint for protected request paths | Java |
| Destination Proxy (`apiProxy_destinationProxy`) | Forwards matched requests to selected backend destination services and streams responses back to callers | Java |
| BEMOD Sync (`apiProxy_bemodSync`) | Background worker that fetches marked/blacklisted/whitelisted behaviour-modification data from BASS for routing overlays | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `apiProxy_requestRouter` | `apiProxy_filterChainEngine` | Passes inbound request context for policy and routing evaluation | direct |
| `apiProxy_filterChainEngine` | `apiProxy_routeConfigLoader` | Retrieves route definitions and filter directives | direct |
| `apiProxy_filterChainEngine` | `apiProxy_rateLimiter` | Checks whether request should be throttled | direct |
| `apiProxy_rateLimiter` | `apiProxy_clientIdLoader` | Retrieves client-specific limits and policy overrides | direct |
| `apiProxy_filterChainEngine` | `apiProxy_recaptchaClient` | Validates reCAPTCHA tokens when required | direct |
| `apiProxy_filterChainEngine` | `apiProxy_destinationProxy` | Forwards allowed requests to resolved backend destination | direct |
| `apiProxy_bemodSync` | `apiProxy_routeConfigLoader` | Refreshes BEMOD routing overlays and behaviour-modification rules | direct |
| `apiProxy` | `continuumApiProxyRedis` | Reads and increments rate-limit counters | RESP/TCP |
| `apiProxy` | `continuumClientIdService` | Fetches client identity and policy configuration | HTTPS |
| `apiProxy` | `metricsStack` | Publishes request metrics, logs, and traces | TCP/HTTPS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-api-apiProxy_destinationProxy`
- Dynamic (request processing): `dynamic-api-apiProxy_destinationProxy-request-processing`
