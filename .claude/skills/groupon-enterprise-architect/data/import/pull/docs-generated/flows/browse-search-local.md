---
service: "pull"
title: "Browse, Search, and Local Request Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "browse-search-local"
flow_type: synchronous
trigger: "HTTP GET /browse, /search, /local, /goods, or /gifting from consumer client"
participants:
  - "continuumPullConsumerClients"
  - "continuumPullItierApp"
  - "pullRouteDispatcher"
  - "pullPageControllers"
  - "pullSearchBrowseOrchestrator"
  - "pullFeatureFlagClient"
  - "pullGeoResolver"
  - "pullApiClientFacade"
  - "pullRenderComposer"
  - "pullTelemetryPublisher"
  - "continuumBirdcageService"
  - "continuumGeoPlacesService"
  - "continuumRelevanceApi"
  - "continuumLayoutService"
  - "continuumLpapiService"
  - "continuumUgcService"
  - "apiProxy"
architecture_ref: "dynamic-pull-browse-request-flow"
---

# Browse, Search, and Local Request Flow

## Summary

This flow handles incoming `GET /browse`, `GET /search`, `GET /local`, `GET /goods`, and `GET /gifting` requests from consumer clients. The Search/Browse Orchestrator (`pullSearchBrowseOrchestrator`) coordinates the full workflow: resolving the user's geographic context, reading experiment and feature flag treatments, fetching ranked deal cards and facets from the Relevance API, gathering supplemental content from API Proxy and LPAPI, loading UGC ratings, and composing a server-rendered HTML listing page. This is the primary flow documented in the central architecture dynamic view `dynamic-pull-browse-request-flow`.

## Trigger

- **Type**: user-action / api-call
- **Source**: Consumer browser or mobile web client (`continuumPullConsumerClients`) issuing `HTTP GET /browse`, `/search`, `/local`, `/goods`, or `/gifting`
- **Frequency**: Per-request (on-demand, every listing page load)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Web Clients | Initiates the request; receives rendered HTML listing page | `continuumPullConsumerClients` |
| Pull I-Tier App | Top-level request handler hosting all internal components | `continuumPullItierApp` |
| Route Dispatcher | Matches route path to the correct feature module | `pullRouteDispatcher` |
| Page Controllers | Manages request lifecycle; delegates to Search/Browse Orchestrator; emits telemetry | `pullPageControllers` |
| Search/Browse Orchestrator | Coordinates the full browse/search/local workflow | `pullSearchBrowseOrchestrator` |
| Feature Flag Client | Resolves experiment and feature flag treatments per request | `pullFeatureFlagClient` |
| Geo Resolver | Determines division and location context for deal scoping | `pullGeoResolver` |
| API Client Facade | Issues outbound calls to Relevance API, API Proxy, LPAPI, UGC | `pullApiClientFacade` |
| Render Composer | Assembles Preact SSR output and hydration payload | `pullRenderComposer` |
| Telemetry Publisher | Emits request metrics and traces | `pullTelemetryPublisher` |
| Birdcage | Provides experiment bucket assignments and feature toggles | `continuumBirdcageService` |
| GeoPlaces | Provides geographic and place metadata for division resolution | `continuumGeoPlacesService` |
| Relevance API | Provides ranked deal cards, facets, and category listings | `continuumRelevanceApi` |
| Layout Service | Provides page layout and widget slot configuration | `continuumLayoutService` |
| LPAPI | Provides landing page metadata and route context | `continuumLpapiService` |
| UGC | Provides user-generated ratings and reviews | `continuumUgcService` |
| API Proxy | Provides supplemental aggregated API payloads | `apiProxy` |

## Steps

1. **Receives listing page request**: Consumer client sends an `HTTP GET` request to one of `/browse`, `/search`, `/local`, `/goods`, or `/gifting`.
   - From: `continuumPullConsumerClients`
   - To: `continuumPullItierApp`
   - Protocol: HTTPS

2. **Dispatches to listing page controller**: Route Dispatcher matches the request path to the appropriate feature module and forwards to Page Controllers.
   - From: `pullRouteDispatcher`
   - To: `pullPageControllers`
   - Protocol: direct (in-process)

3. **Delegates to Search/Browse Orchestrator**: Page Controllers invokes the Search/Browse Orchestrator to handle the full listing page workflow.
   - From: `pullPageControllers`
   - To: `pullSearchBrowseOrchestrator`
   - Protocol: direct (in-process)

4. **Resolves experiments and feature flags**: Search/Browse Orchestrator calls the Feature Flag Client, which calls Birdcage to retrieve experiment bucket assignments and feature toggles for the current request.
   - From: `pullSearchBrowseOrchestrator` -> `pullFeatureFlagClient`
   - To: `continuumBirdcageService`
   - Protocol: REST/HTTPS

5. **Resolves location and division context**: Search/Browse Orchestrator calls the Geo Resolver, which calls GeoPlaces using request IP and header metadata to determine the user's division and geographic scope for deal inventory.
   - From: `pullSearchBrowseOrchestrator` -> `pullGeoResolver`
   - To: `continuumGeoPlacesService`
   - Protocol: REST/HTTPS

6. **Fetches landing page metadata**: API Client Facade requests landing page metadata and route context from LPAPI, providing the browse/local page configuration and category mapping.
   - From: `pullSearchBrowseOrchestrator` -> `pullApiClientFacade`
   - To: `continuumLpapiService`
   - Protocol: REST/HTTPS

7. **Fetches ranked deal cards and facets**: API Client Facade requests search/browse relevance data — ranked deal cards, category facets, and filter options — from the Relevance API using resolved geo context and search parameters.
   - From: `pullApiClientFacade`
   - To: `continuumRelevanceApi`
   - Protocol: REST/HTTPS

8. **Fetches layout configuration**: API Client Facade requests page layout and widget slot configuration from Layout Service.
   - From: `pullApiClientFacade`
   - To: `continuumLayoutService`
   - Protocol: REST/HTTPS

9. **Fetches supplemental API payloads**: API Client Facade calls API Proxy for supplemental aggregated content data to complement the Relevance API deal cards.
   - From: `pullApiClientFacade`
   - To: `apiProxy`
   - Protocol: REST/HTTPS

10. **Fetches UGC ratings and reviews**: API Client Facade calls UGC Service to retrieve user-generated ratings and review data for deals appearing in the listing.
    - From: `pullApiClientFacade`
    - To: `continuumUgcService`
    - Protocol: REST/HTTPS

11. **Composes rendered listing page**: Search/Browse Orchestrator passes all assembled data to the Render Composer, which performs server-side Preact rendering and produces the final HTML with embedded hydration payload.
    - From: `pullSearchBrowseOrchestrator`
    - To: `pullRenderComposer`
    - Protocol: direct (in-process)

12. **Emits request telemetry**: Page Controllers instructs the Telemetry Publisher to emit request duration, status code, route, and any error metrics.
    - From: `pullPageControllers`
    - To: `pullTelemetryPublisher`
    - Protocol: direct (in-process)

13. **Returns rendered HTML page**: Pull I-Tier App sends the composed HTML listing page back to the consumer client.
    - From: `continuumPullItierApp`
    - To: `continuumPullConsumerClients`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Relevance API unavailable | API Client Facade reports failure to Search/Browse Orchestrator | Browse/search pages cannot render deal cards — critical failure; HTTP 5xx or empty state |
| Birdcage unavailable | Feature Flag Client fails open to default flag values | Listing page renders without experiment treatments; baseline UI served |
| GeoPlaces unavailable | Geo Resolver falls back to default division | Deals may not be scoped to correct geographic market |
| LPAPI unavailable | Landing page metadata unavailable | Browse/local pages fall back to generic listing layout |
| Layout Service unavailable | Layout configuration unavailable | Page falls back to static default layout structure |
| UGC unavailable | Ratings and reviews omitted from response | Page renders without user-generated content; non-critical degradation |
| API Proxy error | Supplemental content payload unavailable | Page renders with incomplete supplemental content; error telemetry emitted |

## Sequence Diagram

```
ConsumerClients     -> PullItierApp              : GET /browse (or /search, /local, /goods, /gifting)
PullItierApp        -> RouteDispatcher           : Match route to feature module
RouteDispatcher     -> PageControllers           : Dispatch request
PageControllers     -> SearchBrowseOrchestrator  : Delegate listing page workflow
SearchBrowseOrchestrator -> FeatureFlagClient    : Resolve experiments and feature flags
FeatureFlagClient   -> BirdcageService           : GET experiment assignments
BirdcageService    --> FeatureFlagClient          : Flag/experiment assignments
SearchBrowseOrchestrator -> GeoResolver          : Resolve location and division context
GeoResolver         -> GeoPlacesService          : GET geographic and place metadata
GeoPlacesService   --> GeoResolver               : Division and location context
SearchBrowseOrchestrator -> ApiClientFacade      : Fetch deals, facets, layout, UGC, supplemental
ApiClientFacade     -> LpapiService              : GET landing page metadata and route context
LpapiService       --> ApiClientFacade            : Landing page configuration
ApiClientFacade     -> RelevanceApi              : GET ranked deal cards and facets
RelevanceApi       --> ApiClientFacade            : Deal cards, facets, filters
ApiClientFacade     -> LayoutService             : GET layout and widget config
LayoutService      --> ApiClientFacade            : Page layout configuration
ApiClientFacade     -> ApiProxy                  : GET supplemental API payloads
ApiProxy           --> ApiClientFacade            : Supplemental content
ApiClientFacade     -> UgcService                : GET ratings and reviews
UgcService         --> ApiClientFacade            : Ratings and reviews
SearchBrowseOrchestrator -> RenderComposer       : Compose SSR listing page
RenderComposer     --> SearchBrowseOrchestrator   : HTML + hydration payload
PageControllers     -> TelemetryPublisher         : Emit request metrics and traces
PullItierApp       --> ConsumerClients            : 200 OK — rendered listing HTML page
```

## Related

- Architecture dynamic view: `dynamic-pull-browse-request-flow`
- Related flows: [Homepage Render](homepage-render.md), [Wishlist Sync](wishlist-sync.md), [Telemetry Emission](telemetry-emission.md)
