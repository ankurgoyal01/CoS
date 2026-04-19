---
service: "pull"
title: "Wishlist Sync Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "wishlist-sync"
flow_type: synchronous
trigger: "Homepage or listing page render for a signed-in user session"
participants:
  - "continuumPullItierApp"
  - "pullPageControllers"
  - "pullHomepageOrchestrator"
  - "pullSearchBrowseOrchestrator"
  - "pullApiClientFacade"
  - "pullRenderComposer"
  - "continuumWishlistService"
architecture_ref: "dynamic-pull-browse-request-flow"
---

# Wishlist Sync Flow

## Summary

The Wishlist Sync flow occurs as an embedded sub-step within both the Homepage Render and Browse/Search/Local Request flows when the incoming request is from a signed-in user (identified by a session cookie). The Pull I-Tier App reads the user's current wishlist state from the Wishlist Service (`continuumWishlistService`) during server-side rendering, embedding wishlist indicators (saved/wishlisted status) into the rendered deal card HTML and hydration payload. This ensures that authenticated users see their saved deals highlighted on page load without a separate client-side fetch.

## Trigger

- **Type**: user-action (embedded within page render)
- **Source**: A signed-in consumer session cookie is present on an incoming `GET /`, `GET /browse`, `GET /search`, `GET /local`, `GET /goods`, or `GET /gifting` request
- **Frequency**: Per-request for authenticated users (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pull I-Tier App | Hosts all components; receives user session context | `continuumPullItierApp` |
| Page Controllers | Manages request lifecycle; provides session context to orchestrators | `pullPageControllers` |
| Homepage Orchestrator | Initiates wishlist fetch for homepage renders | `pullHomepageOrchestrator` |
| Search/Browse Orchestrator | Initiates wishlist fetch for listing page renders | `pullSearchBrowseOrchestrator` |
| API Client Facade | Issues outbound call to Wishlist Service | `pullApiClientFacade` |
| Render Composer | Embeds wishlist state into SSR output and hydration payload | `pullRenderComposer` |
| Wishlist Service | Provides current wishlist items for the authenticated user | `continuumWishlistService` |

## Steps

1. **Identifies signed-in user**: Page Controllers reads the session cookie from the incoming request and determines the user is authenticated; passes identity context to the active domain orchestrator (Homepage or Search/Browse).
   - From: `pullPageControllers`
   - To: `pullHomepageOrchestrator` or `pullSearchBrowseOrchestrator`
   - Protocol: direct (in-process)

2. **Requests wishlist data**: The active orchestrator instructs the API Client Facade to fetch the current user's wishlist data from the Wishlist Service using the user session identity.
   - From: `pullHomepageOrchestrator` or `pullSearchBrowseOrchestrator` -> `pullApiClientFacade`
   - To: `continuumWishlistService`
   - Protocol: REST/HTTPS

3. **Returns wishlist items**: Wishlist Service responds with the set of deal or item IDs currently saved in the user's wishlist.
   - From: `continuumWishlistService`
   - To: `pullApiClientFacade`
   - Protocol: REST/HTTPS

4. **Merges wishlist state with page data**: The active orchestrator merges the wishlist item IDs with the deal card dataset assembled from other upstream calls (Relevance API, API Proxy).
   - From: `pullHomepageOrchestrator` or `pullSearchBrowseOrchestrator`
   - To: `pullRenderComposer`
   - Protocol: direct (in-process)

5. **Renders wishlist indicators in HTML**: Render Composer produces SSR HTML with wishlist saved/unsaved state embedded per deal card, plus the matching hydration payload for client-side re-hydration.
   - From: `pullRenderComposer`
   - To: `continuumPullItierApp` (response assembly)
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Wishlist Service unavailable | API Client Facade reports failure; orchestrator proceeds without wishlist data | Page renders without wishlist indicators; deal cards appear in un-saved state for all items; non-critical degradation |
| Wishlist Service slow response | Request times out after platform-configured timeout | Page renders without wishlist state (timeout fallback); error telemetry emitted |
| Unauthenticated request | No session cookie present — wishlist fetch is skipped entirely | Wishlist sync step does not execute; page renders normally without wishlist indicators |

## Sequence Diagram

```
PageControllers    -> Orchestrator         : Pass authenticated user session context
Orchestrator       -> ApiClientFacade      : Fetch wishlist for user
ApiClientFacade    -> WishlistService      : GET /wishlist (user session)
WishlistService   --> ApiClientFacade      : Wishlist item IDs
ApiClientFacade   --> Orchestrator         : Wishlist state
Orchestrator       -> RenderComposer       : Compose page with wishlist indicators per deal card
RenderComposer    --> Orchestrator         : HTML with wishlist state + hydration payload
```

## Related

- Architecture dynamic view: `dynamic-pull-browse-request-flow`
- Related flows: [Homepage Render](homepage-render.md), [Browse, Search, and Local Request](browse-search-local.md), [Telemetry Emission](telemetry-emission.md)
