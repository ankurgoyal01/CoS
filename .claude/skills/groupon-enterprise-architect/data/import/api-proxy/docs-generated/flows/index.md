---
service: "api-proxy"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for API Proxy.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Request Routing](request-routing.md) | synchronous | Inbound HTTP request from client application | Receives inbound request, executes filter chain (auth, rate limit, reCAPTCHA), and forwards to backend destination |
| [Config Reload](config-reload.md) | scheduled | Periodic background timer or admin trigger | Fetches latest route configuration from external config service and refreshes in-process routing state |
| [Rate Limiting Enforcement](rate-limiting-enforcement.md) | synchronous | Per-request, inline with request routing | Evaluates throttling constraints against Redis counters using client-level policy from Client ID Loader |
| [BEMOD Sync Update](bemod-sync-update.md) | scheduled | Periodic background timer | Fetches behaviour-modification data from BASS Service and applies updated routing overlays |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Request Routing** spans `apiProxy` → `continuumClientIdService`, `continuumApiProxyRedis`, Google reCAPTCHA API, and dynamic backend destination services. The architecture dynamic view is `dynamic-api-apiProxy_destinationProxy-request-processing`.
- **BEMOD Sync Update** spans `apiProxy` → BASS Service (via bass-client). Configuration of the BASS upstream endpoint is owned by `api-proxy-config`.
