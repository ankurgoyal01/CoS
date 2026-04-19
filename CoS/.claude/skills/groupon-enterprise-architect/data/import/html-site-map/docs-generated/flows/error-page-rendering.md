---
service: "html-site-map"
title: "Error Page Rendering"
generated: "2026-03-03"
type: flow
flow_name: "error-page-rendering"
flow_type: synchronous
trigger: "LPAPI returns non-200 status or route not found"
participants:
  - "Web crawler / user agent"
  - "continuumHtmlSiteMapWeb"
  - "continuumApiLazloService"
  - "Remote Layout service"
architecture_ref: "dynamic-html-site-map-error"
---

# Error Page Rendering

## Summary

This flow handles two error scenarios that result in a custom 404 experience: (1) a request arrives for a known sitemap route (home, cities, or categories) but LPAPI returns a non-200 status for the requested region or city slug — indicating the slug is not recognized; (2) a request arrives for a URL path that does not match any registered sitemap route. In both cases, the Error Handler renders a custom 404 page (`modules/error/views/404.js`) that includes top-category links sourced from a static local data file, providing users with helpful navigation despite the error.

## Trigger

- **Type**: api-call (user-action or crawler) — error condition
- **Source**: Web crawler or user navigating to an invalid sitemap path (e.g. `/sitemap/not-a-state`), or any route handler receiving a non-200 response from LPAPI
- **Frequency**: On-demand (triggered by invalid requests or LPAPI data errors)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web crawler / user agent | Originates the HTTP request that results in an error | — |
| HTML Site Map Web | Detects error condition, delegates to Error Handler, renders 404 page | `continuumHtmlSiteMapWeb` |
| LPAPI | Returns non-200 status that triggers the error path (in scenario 1) | `continuumApiLazloService` |
| Remote Layout service | Provides shared page shell for the 404 page | stub: `unknownRemoteLayoutContainer_a41bc9f0` |

## Steps

**Scenario 1 — LPAPI error path (invalid slug):**

1. **Route handler receives request**: One of the three sitemap route handlers (home, cities, or categories) is invoked for a valid sitemap URL pattern.
   - From: Web crawler / user agent
   - To: `continuumHtmlSiteMapWeb` (Request Routing)
   - Protocol: HTTPS

2. **Calls LPAPI**: The route handler calls `lpapi.getPage()` via the LPAPI Client Adapter.
   - From: `continuumHtmlSiteMapWeb`
   - To: `continuumApiLazloService`
   - Protocol: HTTPS/JSON

3. **LPAPI returns error**: LPAPI responds with a non-200 status (e.g. 404 for unknown slug). `handlePageResponse` catches the thrown error and extracts `statusCode`.
   - From: `continuumApiLazloService`
   - To: `continuumHtmlSiteMapWeb` (`lpapiClientComponent`)
   - Protocol: HTTPS/JSON

4. **Route handler returns status code**: The route handler detects `if (statusCode)` and returns `{ statusCode }` to the itier-server framework, which maps this to the registered error handler.
   - From: `sitemapHomeComponent` / `sitemapCitiesComponent` / `sitemapCategoriesComponent`
   - To: `errorHandlingComponent`
   - Protocol: direct (in-process)

**Scenario 2 — Unmatched route path:**

1. **Request arrives for unknown path**: A URL not matching `/sitemap`, `/sitemap/{regionSlug}`, or `/sitemap/{regionSlug}/{citySlug}` arrives.
   - From: Web crawler / user agent
   - To: `continuumHtmlSiteMapWeb` (Request Routing)
   - Protocol: HTTPS

2. **No route matches**: The itier-server framework finds no matching handler and invokes the `pageNotFound` action from `modules/error/actions.js`.
   - From: Request Routing
   - To: `errorHandlingComponent`
   - Protocol: direct (in-process)

**Common error rendering steps (both scenarios):**

5. **Starts page tracking**: The Error Handler calls `trackingHub.startPageRequest` with `pageType = 'html-site-map/error/404page'`.
   - From: `errorHandlingComponent`
   - To: itier-instrumentation (in-process)
   - Protocol: direct

6. **Loads static top categories**: The Error Handler imports top category links from the static local data file `modules/error/data/top-categories.js` — no LPAPI call is made.
   - From: `errorHandlingComponent`
   - To: local data module (in-process)
   - Protocol: direct

7. **Fetches shared page layout**: The Server-side Renderer calls the Remote Layout service.
   - From: `pageRenderingComponent`
   - To: Remote Layout service
   - Protocol: HTTPS

8. **Renders and returns 404 page**: `preactPage()` composes the `PageNotFound` Preact component with static top categories and the CDN error CSS asset. Returns HTTP 404 with the custom HTML error page.
   - From: `pageRenderingComponent`
   - To: Web crawler / user agent
   - Protocol: HTTP 404 text/html

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LPAPI returns 404 for unknown slug | Route handler returns `{ statusCode: 404 }` → Error Handler renders 404 page | HTTP 404 custom error page |
| LPAPI returns 503 (unavailable) | `handleResponse` returns `{ statusCode: 503 }` | HTTP 503 response |
| LPAPI throws error without statusCode | `handlePageResponse` defaults to `statusCode: 500` | HTTP 500 response |
| Remote Layout unavailable during 404 rendering | `remote-layout` handles gracefully | Degraded 404 page without shared shell |

## Sequence Diagram

```
Crawler/User -> continuumHtmlSiteMapWeb: GET /sitemap/{invalid-slug}
continuumHtmlSiteMapWeb -> continuumApiLazloService: lpapi.getPage(...)
continuumApiLazloService --> continuumHtmlSiteMapWeb: HTTP 404 (slug not found)
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: handlePageResponse extracts statusCode=404
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: if (statusCode) return { statusCode }
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: errorHandlingComponent.pageNotFound()
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: Load topCategories from static data
continuumHtmlSiteMapWeb -> RemoteLayoutService: Fetch page shell
RemoteLayoutService --> continuumHtmlSiteMapWeb: HTML header/nav/footer fragments
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: SSR Preact PageNotFound component
continuumHtmlSiteMapWeb --> Crawler/User: HTTP 404 text/html (custom 404 page)
```

## Related

- Architecture dynamic view: `dynamic-html-site-map-error`
- Related flows: [Sitemap Home Page Request](sitemap-home-page-request.md), [Sitemap Cities Page Request](sitemap-cities-page-request.md), [Sitemap Categories Page Request](sitemap-categories-page-request.md)
