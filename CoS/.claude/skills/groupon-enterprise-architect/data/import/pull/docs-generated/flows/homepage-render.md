---
service: "pull"
title: "Homepage Render Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "homepage-render"
flow_type: synchronous
trigger: "HTTP GET / from consumer browser or mobile web client"
participants:
  - "continuumPullConsumerClients"
  - "continuumPullItierApp"
  - "pullRouteDispatcher"
  - "pullPageControllers"
  - "pullHomepageOrchestrator"
  - "pullFeatureFlagClient"
  - "pullApiClientFacade"
  - "pullRenderComposer"
  - "pullTelemetryPublisher"
  - "continuumBirdcageService"
  - "continuumLayoutService"
  - "apiProxy"
architecture_ref: "dynamic-pull-browse-request-flow"
---

# Homepage Render Flow

## Summary

The Homepage Render flow handles an incoming `GET /` request from a consumer browser or mobile web client and produces a fully rendered HTML response. The Pull I-Tier App (`continuumPullItierApp`) orchestrates experiment resolution, homepage card and content retrieval from multiple upstream APIs, and server-side Preact rendering — all within a single synchronous request lifecycle. The result is a personalized or contextual homepage HTML page with embedded client-side hydration data.

## Trigger

- **Type**: user-action / api-call
- **Source**: Consumer browser or mobile web client (`continuumPullConsumerClients`) issuing `HTTP GET /`
- **Frequency**: Per-request (on-demand, every homepage page load)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Web Clients | Initiates the request; receives rendered HTML response | `continuumPullConsumerClients` |
| Pull I-Tier App | Top-level request handler; hosts all internal components | `continuumPullItierApp` |
| Route Dispatcher | Matches `GET /` to the homepage feature module | `pullRouteDispatcher` |
| Page Controllers | Manages request lifecycle; delegates to Homepage Orchestrator; emits telemetry | `pullPageControllers` |
| Homepage Orchestrator | Coordinates all homepage-specific data fetching and rendering steps | `pullHomepageOrchestrator` |
| Feature Flag Client | Resolves homepage experiment treatments from Birdcage | `pullFeatureFlagClient` |
| API Client Facade | Issues outbound calls to API Proxy and Layout Service | `pullApiClientFacade` |
| Render Composer | Assembles Preact SSR output and hydration payload | `pullRenderComposer` |
| Telemetry Publisher | Emits request metrics and traces | `pullTelemetryPublisher` |
| Birdcage | Provides feature flag and experiment assignments | `continuumBirdcageService` |
| Layout Service | Provides page layout and widget slot configuration | `continuumLayoutService` |
| API Proxy | Provides homepage deal cards and aggregated content | `apiProxy` |

## Steps

1. **Receives homepage request**: Consumer client sends `HTTP GET /` to the Pull I-Tier App.
   - From: `continuumPullConsumerClients`
   - To: `continuumPullItierApp`
   - Protocol: HTTPS

2. **Dispatches to homepage controller**: Route Dispatcher matches the `/` path to the homepage feature module and forwards the request to Page Controllers.
   - From: `pullRouteDispatcher`
   - To: `pullPageControllers`
   - Protocol: direct (in-process)

3. **Delegates to Homepage Orchestrator**: Page Controllers invokes the Homepage Orchestrator to handle the homepage-specific workflow.
   - From: `pullPageControllers`
   - To: `pullHomepageOrchestrator`
   - Protocol: direct (in-process)

4. **Resolves experiment treatments**: Homepage Orchestrator calls the Feature Flag Client, which calls Birdcage to resolve homepage experiment bucket assignments and feature toggles for the current request context.
   - From: `pullHomepageOrchestrator` -> `pullFeatureFlagClient`
   - To: `continuumBirdcageService`
   - Protocol: REST/HTTPS

5. **Fetches homepage cards and content**: Homepage Orchestrator instructs the API Client Facade to request homepage deal cards and aggregated content from the API Proxy gateway.
   - From: `pullHomepageOrchestrator` -> `pullApiClientFacade`
   - To: `apiProxy`
   - Protocol: REST/HTTPS

6. **Fetches layout configuration**: API Client Facade requests page layout and widget slot configuration from Layout Service to determine homepage page structure.
   - From: `pullApiClientFacade`
   - To: `continuumLayoutService`
   - Protocol: REST/HTTPS

7. **Composes rendered response**: Homepage Orchestrator passes assembled data to the Render Composer, which performs server-side Preact rendering and produces the final HTML with hydration payload.
   - From: `pullHomepageOrchestrator`
   - To: `pullRenderComposer`
   - Protocol: direct (in-process)

8. **Emits request telemetry**: Page Controllers instructs the Telemetry Publisher to emit request duration, status, and any error metrics.
   - From: `pullPageControllers`
   - To: `pullTelemetryPublisher`
   - Protocol: direct (in-process)

9. **Returns rendered HTML page**: Pull I-Tier App sends the composed HTML response back to the consumer client.
   - From: `continuumPullItierApp`
   - To: `continuumPullConsumerClients`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Birdcage unavailable | Feature flag client fails open to default flag values | Homepage renders without experiment treatments; baseline experience served |
| API Proxy unavailable or error | API Client Facade reports upstream failure to Homepage Orchestrator | Homepage renders with degraded or empty card set; error telemetry emitted |
| Layout Service unavailable | Layout configuration unavailable | Homepage may fall back to static default layout; error telemetry emitted |
| Render Composer failure | Unhandled rendering exception | HTTP 5xx returned to consumer client; full error telemetry emitted |

## Sequence Diagram

```
ConsumerClients    -> PullItierApp         : GET /
PullItierApp       -> RouteDispatcher      : Match route to homepage module
RouteDispatcher    -> PageControllers      : Dispatch request
PageControllers    -> HomepageOrchestrator : Delegate homepage workflow
HomepageOrchestrator -> FeatureFlagClient  : Resolve experiment treatments
FeatureFlagClient  -> BirdcageService      : GET feature flag assignments
BirdcageService   --> FeatureFlagClient    : Flag assignments
HomepageOrchestrator -> ApiClientFacade   : Fetch homepage cards and content
ApiClientFacade    -> ApiProxy             : GET homepage aggregated payload
ApiProxy          --> ApiClientFacade      : Homepage deal cards and content
ApiClientFacade    -> LayoutService        : GET layout and widget config
LayoutService     --> ApiClientFacade      : Page layout configuration
HomepageOrchestrator -> RenderComposer    : Compose SSR page
RenderComposer    --> HomepageOrchestrator : HTML + hydration payload
PageControllers    -> TelemetryPublisher   : Emit request metrics
PullItierApp      --> ConsumerClients      : 200 OK — rendered HTML page
```

## Related

- Architecture dynamic view: `dynamic-pull-browse-request-flow`
- Related flows: [Browse, Search, and Local Request](browse-search-local.md), [Wishlist Sync](wishlist-sync.md), [Telemetry Emission](telemetry-emission.md)
