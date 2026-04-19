---
service: "pull"
title: "Telemetry Emission Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "telemetry-emission"
flow_type: synchronous
trigger: "Completion of every HTTP request handled by Page Controllers"
participants:
  - "continuumPullItierApp"
  - "pullPageControllers"
  - "pullTelemetryPublisher"
architecture_ref: "dynamic-pull-browse-request-flow"
---

# Telemetry Emission Flow

## Summary

The Telemetry Emission flow is an embedded sub-step that executes at the tail of every HTTP request lifecycle managed by the Page Controllers (`pullPageControllers`). After the active domain orchestrator completes rendering (or after an error is caught), Page Controllers instructs the Telemetry Publisher (`pullTelemetryPublisher`) to emit request-scoped metrics, distributed traces, and error telemetry via `itier-instrumentation 9.13.4`. This provides observability into request performance, error rates, and upstream dependency health across all Pull discovery routes.

## Trigger

- **Type**: user-action (embedded within page request lifecycle)
- **Source**: Page Controllers, triggered at the end of every handled request on any route (`/`, `/browse`, `/search`, `/local`, `/goods`, `/gifting`)
- **Frequency**: Per-request (on-demand, every HTTP request to Pull)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pull I-Tier App | Host application; all requests pass through Page Controllers | `continuumPullItierApp` |
| Page Controllers | Triggers telemetry emission after each request; provides request context (route, status, duration, errors) | `pullPageControllers` |
| Telemetry Publisher | Receives request context and emits metrics, traces, and error data to the observability platform | `pullTelemetryPublisher` |

## Steps

1. **Request lifecycle completes**: Page Controllers finishes orchestrating the request — either the rendered HTML response has been assembled, or an error has been caught and an error response prepared.
   - From: `pullPageControllers`
   - To: `pullTelemetryPublisher`
   - Protocol: direct (in-process)

2. **Collects request context**: Telemetry Publisher gathers request-scoped data: route path (e.g., `/browse`), HTTP method, response status code, end-to-end request duration, upstream dependency call durations, and any error details.
   - From: `pullTelemetryPublisher`
   - To: (in-process context)
   - Protocol: direct (in-process)

3. **Publishes metrics**: Telemetry Publisher emits request duration histograms, request counters, and error counters via `itier-instrumentation 9.13.4` to the Groupon observability platform.
   - From: `pullTelemetryPublisher`
   - To: Observability platform (platform-managed)
   - Protocol: itier-instrumentation (platform telemetry protocol)

4. **Publishes distributed traces**: Telemetry Publisher emits distributed trace spans covering the Pull request lifecycle, including spans for upstream calls to Birdcage, GeoPlaces, Relevance API, Layout Service, API Proxy, LPAPI, UGC, and Wishlist.
   - From: `pullTelemetryPublisher`
   - To: Observability platform (platform-managed)
   - Protocol: itier-instrumentation (platform tracing protocol)

5. **Publishes error telemetry**: If the request resulted in an error (upstream failure, rendering exception), Telemetry Publisher emits structured error events including error type, affected upstream service, and request context.
   - From: `pullTelemetryPublisher`
   - To: Observability platform (platform-managed)
   - Protocol: itier-instrumentation (platform telemetry protocol)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Telemetry Publisher fails to emit | Telemetry emission failure is non-blocking; request response is unaffected | Metrics gap for affected requests; no consumer-visible impact |
| Observability platform unavailable | `itier-instrumentation` buffers or drops telemetry | Temporary observability gap; no impact to page rendering |

## Sequence Diagram

```
PageControllers    -> TelemetryPublisher   : Emit telemetry (route, status, duration, errors)
TelemetryPublisher -> ObservabilityPlatform: Publish request metrics (counters, histograms)
TelemetryPublisher -> ObservabilityPlatform: Publish distributed trace spans
TelemetryPublisher -> ObservabilityPlatform: Publish error events (if applicable)
ObservabilityPlatform --> TelemetryPublisher: Acknowledgement (async, non-blocking)
```

## Related

- Architecture dynamic view: `dynamic-pull-browse-request-flow`
- Related flows: [Homepage Render](homepage-render.md), [Browse, Search, and Local Request](browse-search-local.md), [Wishlist Sync](wishlist-sync.md)
