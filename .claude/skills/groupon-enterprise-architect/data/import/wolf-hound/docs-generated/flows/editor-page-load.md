---
service: "wolf-hound"
title: "Editor Page Load (Data Aggregation) Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "editor-page-load"
flow_type: synchronous
trigger: "Editor opens the workboard or navigates to an editorial page in the UI"
participants:
  - "bffApiLayer"
  - "viewRenderingLayer"
  - "routeControllers"
  - "domainServiceAdapters"
  - "outboundHttpClient"
  - "continuumWolfhoundApi"
  - "continuumWhUsersApi"
  - "continuumMarketingEditorialContentService"
  - "continuumMarketingDealService"
  - "continuumDealsClusterService"
  - "continuumRelevanceApi"
  - "continuumBhuvanService"
architecture_ref: "components-wolf-hound"
---

# Editor Page Load (Data Aggregation) Flow

## Summary

When an editor opens the Wolfhound workboard or navigates to an editorial page, the BFF performs a data aggregation step — dispatching multiple HTTP calls to downstream Continuum services and composing their responses into a unified editor payload. This fan-out pattern populates the editor UI with page content, available templates, image/tag metadata, deal data, cluster rules, relevance search results, and geoplace metadata simultaneously. The view rendering layer then assembles and returns the complete editor view to the frontend.

## Trigger

- **Type**: user-action
- **Source**: Editor navigates to the workboard or opens an editorial page (initial page load or refresh)
- **Frequency**: On demand (per page navigation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Frontend API Layer | Triggers page load; receives composed editor view | `bffApiLayer` |
| View Rendering Layer | Assembles server-rendered view and static bundles for the editor shell | `viewRenderingLayer` |
| Route Controllers | Routes load request; orchestrates data fetching | `routeControllers` |
| Domain Service Adapters | Fans out HTTP calls to all required downstream services | `domainServiceAdapters` |
| Outbound HTTP Client | Executes all outbound HTTP requests with instrumentation | `outboundHttpClient` |
| Wolfhound API | Supplies page/template data and taxonomy | `continuumWolfhoundApi` |
| Users API | Validates session and resolves group/permission context | `continuumWhUsersApi` |
| Marketing Editorial Content Service | Supplies image and tag metadata for the editor panels | `continuumMarketingEditorialContentService` |
| Marketing Deal Service | Supplies deal divisions and deal details | `continuumMarketingDealService` |
| Deals Cluster Service | Supplies cluster rules and top cluster content | `continuumDealsClusterService` |
| Relevance API | Supplies deal cards and relevance-ranked search results | `continuumRelevanceApi` |
| Bhuvan Service | Supplies geoplaces and division metadata | `continuumBhuvanService` |

## Steps

1. **Request editor view**: The frontend API layer (or initial browser request) asks the BFF for the editor workboard or specific page view.
   - From: `bffApiLayer`
   - To: `routeControllers`
   - Protocol: REST (HTTP GET `/pages/:id` or workboard route)

2. **Validate session**: The route controller checks the session; the domain service adapter queries `continuumWhUsersApi` to resolve user identity and group permissions.
   - From: `outboundHttpClient`
   - To: `continuumWhUsersApi`
   - Protocol: REST (HTTP)

3. **Fetch page and template data**: The domain service adapter fetches the editorial page and available templates from `continuumWolfhoundApi`.
   - From: `outboundHttpClient`
   - To: `continuumWolfhoundApi`
   - Protocol: REST (HTTP)

4. **Fetch image and tag metadata**: The domain service adapter queries `continuumMarketingEditorialContentService` for image and tag metadata used in content panels.
   - From: `outboundHttpClient`
   - To: `continuumMarketingEditorialContentService`
   - Protocol: REST (HTTP)

5. **Fetch deal data**: The domain service adapter retrieves deal divisions and deal details from `continuumMarketingDealService`.
   - From: `outboundHttpClient`
   - To: `continuumMarketingDealService`
   - Protocol: REST (HTTP)

6. **Fetch cluster data**: The domain service adapter loads cluster rules and top cluster content from `continuumDealsClusterService`.
   - From: `outboundHttpClient`
   - To: `continuumDealsClusterService`
   - Protocol: REST (HTTP)

7. **Fetch relevance results**: The domain service adapter queries `continuumRelevanceApi` for deal cards and relevance-ranked search results.
   - From: `outboundHttpClient`
   - To: `continuumRelevanceApi`
   - Protocol: REST (HTTP)

8. **Fetch geoplace metadata**: The domain service adapter retrieves geoplaces and division metadata from `continuumBhuvanService`.
   - From: `outboundHttpClient`
   - To: `continuumBhuvanService`
   - Protocol: REST (HTTP)

9. **Compose editor view**: The domain service adapters aggregate the results from all upstream services. The route controller passes the composed data to the view rendering layer.
   - From: `routeControllers`
   - To: `viewRenderingLayer`
   - Protocol: direct (in-process)

10. **Return editor view**: The view rendering layer assembles the server-rendered Hogan template or Vue app shell with the aggregated data and returns the full HTML/JSON response.
    - From: `viewRenderingLayer`
    - To: `bffApiLayer`
    - Protocol: HTTP response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | `routeControllers` rejects at step 2 | BFF returns 401; editor redirected to login |
| `continuumWolfhoundApi` unavailable | Critical — page data unavailable | BFF returns 500/503; editor cannot load |
| `continuumWhUsersApi` unavailable | Critical — auth cannot be resolved | BFF returns 500/503; editor cannot load |
| `continuumMarketingEditorialContentService` unavailable | Non-critical — image/tag panel degrades | Editor loads with image/tag panel showing error state |
| `continuumMarketingDealService` unavailable | Non-critical — deals panel degrades | Editor loads with deals panel showing error state |
| `continuumDealsClusterService` unavailable | Non-critical — clusters panel degrades | Editor loads with clusters panel showing error state |
| `continuumRelevanceApi` unavailable | Non-critical — relevance panel degrades | Editor loads with relevance panel showing error state |
| `continuumBhuvanService` unavailable | Non-critical — geoplace selector degrades | Editor loads with location targeting unavailable |

## Sequence Diagram

```
bffApiLayer           -> routeControllers                        : GET /pages/:id (or workboard)
routeControllers      -> domainServiceAdapters                   : validate session and orchestrate data fetch
outboundHttpClient    -> continuumWhUsersApi                     : GET user/group permissions
outboundHttpClient    -> continuumWolfhoundApi                   : GET page and template data
outboundHttpClient    -> continuumMarketingEditorialContentService: GET image and tag metadata
outboundHttpClient    -> continuumMarketingDealService           : GET deal divisions and details
outboundHttpClient    -> continuumDealsClusterService            : GET cluster rules and content
outboundHttpClient    -> continuumRelevanceApi                   : GET deal cards and relevance results
outboundHttpClient    -> continuumBhuvanService                  : GET geoplace division metadata
[all responses received]
domainServiceAdapters --> routeControllers                       : aggregated editor data
routeControllers      -> viewRenderingLayer                      : compose editor view
viewRenderingLayer    --> bffApiLayer                            : complete editor view (HTML/JSON)
```

## Related

- Architecture dynamic view: `dynamic-editorial-publish-flow`
- Related flows: [Editorial Publish](editorial-publish.md), [Page Create and Save](page-create-save.md)
