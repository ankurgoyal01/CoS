---
service: "api-proxy"
title: "Config Reload"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "config-reload"
flow_type: scheduled
trigger: "Periodic background timer or admin POST to /config/* endpoint"
participants:
  - "apiProxy_routeConfigLoader"
  - "apiProxy_filterChainEngine"
  - "continuumClientIdService"
architecture_ref: "dynamic-api-apiProxy_destinationProxy-request-processing"
---

# Config Reload

## Summary

Config Reload is the background maintenance flow that keeps API Proxy's in-process routing state current. The Route Config Loader periodically fetches the latest route definitions and filter directives from the external configuration service (`continuumClientIdService`) and applies them to the in-process cache. The Filter Chain Engine then uses the refreshed configuration for all subsequent request evaluations. An immediate reload can also be triggered via the `/config/*` admin endpoints.

## Trigger

- **Type**: schedule / api-call
- **Source**: Internal background timer (interval configured via `CONFIG_RELOAD_INTERVAL_MS`) or manual `POST /config/reload` admin request
- **Frequency**: Periodic (on a configurable interval); on-demand via admin endpoint

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Route Config Loader | Initiates the reload; fetches updated config from external service; updates in-process cache | `apiProxy_routeConfigLoader` |
| Client ID Service | Provides the authoritative route configuration and client policy data | `continuumClientIdService` |
| Filter Chain Engine | Consumes the refreshed route definitions for all subsequent request evaluations | `apiProxy_filterChainEngine` |

## Steps

1. **Timer fires or admin request received**: The background scheduler reaches the reload interval, or an operator sends `POST /config/*` to force an immediate reload.
   - From: Internal scheduler / operator
   - To: `apiProxy_routeConfigLoader`
   - Protocol: in-process / HTTP (admin endpoint)

2. **Fetch updated configuration**: Route Config Loader sends an HTTPS request to `continuumClientIdService` to retrieve the latest route definitions, filter directives, and per-client policy configuration.
   - From: `apiProxy_routeConfigLoader`
   - To: `continuumClientIdService`
   - Protocol: HTTPS

3. **Validate configuration payload**: Route Config Loader parses and validates the received configuration. If the payload is malformed or incomplete, the reload is aborted and the existing cache is retained.
   - From: `apiProxy_routeConfigLoader`
   - To: `apiProxy_routeConfigLoader` (internal)
   - Protocol: direct (in-process)

4. **Atomically swap in-process cache**: Route Config Loader replaces the current route configuration cache with the newly fetched definitions. Requests in flight continue using the previous config until the swap is complete.
   - From: `apiProxy_routeConfigLoader`
   - To: in-process route cache
   - Protocol: direct (in-process)

5. **Filter Chain Engine picks up new config**: On the next inbound request, the Filter Chain Engine reads from the updated cache, applying the refreshed route definitions and filter directives.
   - From: `apiProxy_filterChainEngine`
   - To: `apiProxy_routeConfigLoader`
   - Protocol: direct (in-process)

6. **Emit reload metric**: Route Config Loader increments the `api_proxy.route_config.reload_success` (or `reload_failure`) counter and emits a structured log entry via logback-steno.
   - From: `apiProxy_routeConfigLoader`
   - To: `metricsStack`
   - Protocol: TCP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumClientIdService` unreachable | Reload aborted; existing cache retained | Stale config served until next successful reload; `api_proxy.route_config.reload_failure` incremented |
| Malformed configuration payload | Reload aborted; payload discarded | Existing cache retained; error logged |
| Partial configuration (missing required fields) | Reload aborted | Existing cache retained; warning logged |
| Admin-triggered reload while background reload is in progress | Second reload queued or skipped | Depends on implementation; single active reload at any time |

## Sequence Diagram

```
Scheduler/Operator -> apiProxy_routeConfigLoader: Reload trigger (timer or POST /config/reload)
apiProxy_routeConfigLoader -> continuumClientIdService: GET route configuration (HTTPS)
continuumClientIdService --> apiProxy_routeConfigLoader: Route definitions + policy config
apiProxy_routeConfigLoader -> apiProxy_routeConfigLoader: Validate and parse configuration
apiProxy_routeConfigLoader -> InProcessCache: Atomically swap route config
apiProxy_routeConfigLoader -> metricsStack: Emit reload_success counter + structured log
apiProxy_filterChainEngine -> apiProxy_routeConfigLoader: [next request] Retrieve route definitions
apiProxy_routeConfigLoader --> apiProxy_filterChainEngine: Updated route definitions
```

## Related

- Architecture dynamic view: `dynamic-api-apiProxy_destinationProxy-request-processing`
- Related flows: [Request Routing](request-routing.md), [BEMOD Sync Update](bemod-sync-update.md)
