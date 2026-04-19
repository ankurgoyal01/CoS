---
service: "content-pages"
title: "Content Page Retrieval Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "content-page-retrieval"
flow_type: synchronous
trigger: "User navigates to a /pages/{permalink} or /legal/{permalink} URL"
participants:
  - "continuumContentPagesService"
  - "contentPagesController"
  - "permalinksService"
architecture_ref: "dynamic-content-page-retrieval"
---

# Content Page Retrieval Flow

## Summary

This flow handles requests for CMS-managed content pages — general content pages at `/pages/{permalink}` and legal documents at `/legal/{permalink}`. The service resolves the permalink, fetches the corresponding content from the Content Pages GraphQL API via `itier-groupon-v2-content-pages`, and renders the result as an HTML page using Preact server-side rendering. In-process caching via `itier-cached` reduces repeated GraphQL API calls for the same permalink.

## Trigger

- **Type**: user-action
- **Source**: User browser navigates to a `/pages/{permalink}` or `/legal/{permalink}` URL
- **Frequency**: per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User browser | Initiates page request | — |
| Content Pages Controller | Handles the route; orchestrates content fetch and render | `contentPagesController` |
| Permalinks Service | Resolves permalink to content identifier | `permalinksService` |
| itier-cached | Provides in-memory response cache | in-process |
| Content Pages GraphQL API | Source of CMS page content | stub-only |
| Preact | Renders the fetched content to HTML | in-process |

## Steps

1. **Receives page request**: User browser sends `GET /pages/{permalink}` or `GET /legal/{permalink}`.
   - From: `User browser`
   - To: `contentPagesController`
   - Protocol: HTTPS

2. **Checks in-process cache**: Controller checks `itier-cached` for a cached response for the requested permalink.
   - From: `contentPagesController`
   - To: `itier-cached`
   - Protocol: direct

3. **(Cache miss) Resolves permalink**: Permalinks Service maps the permalink slug to a content identifier.
   - From: `contentPagesController`
   - To: `permalinksService`
   - Protocol: direct

4. **(Cache miss) Fetches content from GraphQL API**: `itier-groupon-v2-content-pages` client executes a GraphQL query for the resolved content identifier.
   - From: `permalinksService`
   - To: `Content Pages GraphQL API`
   - Protocol: HTTPS/JSON (GraphQL)

5. **Receives content response**: GraphQL API returns the page content payload (title, body, metadata).
   - From: `Content Pages GraphQL API`
   - To: `contentPagesController`
   - Protocol: HTTPS/JSON

6. **Stores response in cache**: Controller stores the content response in `itier-cached` for subsequent requests.
   - From: `contentPagesController`
   - To: `itier-cached`
   - Protocol: direct

7. **Renders page HTML**: Controller passes content data to Preact for server-side rendering.
   - From: `contentPagesController`
   - To: `Preact`
   - Protocol: direct

8. **Returns rendered HTML**: Controller sends the rendered HTML page to the user browser.
   - From: `contentPagesController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Permalink not found | `permalinksService` returns not-found | `errorPagesController` renders 404 page |
| Content Pages GraphQL API unavailable | `itier-groupon-v2-content-pages` client throws error | `errorPagesController` renders 500 error page |
| GraphQL API returns empty content | Controller detects null/empty response | `errorPagesController` renders 404 page |

## Sequence Diagram

```
User browser -> contentPagesController: GET /pages/{permalink}
contentPagesController -> itier-cached: Check cache for permalink
itier-cached --> contentPagesController: Cache miss
contentPagesController -> permalinksService: Resolve permalink to content ID
permalinksService -> Content Pages GraphQL API: GraphQL query for content
Content Pages GraphQL API --> permalinksService: Content payload
permalinksService --> contentPagesController: Resolved content data
contentPagesController -> itier-cached: Store content in cache
contentPagesController -> Preact: Server-side render content
Preact --> contentPagesController: Rendered HTML
contentPagesController --> User browser: 200 OK (HTML page)
```

## Related

- Architecture dynamic view: No dynamic view defined in DSL
- Related flows: [Privacy Hub Navigation](privacy-hub-navigation.md), [Error Page Rendering](error-page-rendering.md)
