---
service: "html-site-map"
title: "Sitemap Cities Page Request"
generated: "2026-03-03"
type: flow
flow_name: "sitemap-cities-page-request"
flow_type: synchronous
trigger: "HTTP GET /sitemap/{regionSlug}"
participants:
  - "Web crawler / user agent"
  - "continuumHtmlSiteMapWeb"
  - "continuumApiLazloService"
  - "Remote Layout service"
architecture_ref: "dynamic-html-site-map-cities"
---

# Sitemap Cities Page Request

## Summary

This flow handles an HTTP GET request to `/sitemap/{regionSlug}` — the second level of the HTML sitemap hierarchy, which lists all cities or metro areas within a given state or region. The service uses the `regionSlug` path parameter to construct an LPAPI resource path, fetches the city crosslinks for that region, formats them as navigable links, and renders a locale-aware HTML page. This page enables crawlers to discover all city-level sitemap pages from a single regional entry point, and helps users drill down from a state to a specific city.

## Trigger

- **Type**: api-call (user-action or crawler)
- **Source**: Web crawler following a state link from `/sitemap`, or a user clicking a state in the sitemap home page; request is routed to this service by the Groupon Routing Service via Hybrid Boundary
- **Frequency**: On-demand (per request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web crawler / user agent | Originates the HTTP GET request | — (stub in DSL: `unknownWebCrawlerClient_9e12ab3c`) |
| HTML Site Map Web | Handles routing, passes regionSlug to LPAPI, renders HTML | `continuumHtmlSiteMapWeb` |
| LPAPI | Provides city crosslinks for the requested region | `continuumApiLazloService` |
| Remote Layout service | Provides shared page shell (header, nav, footer) | stub: `unknownRemoteLayoutContainer_a41bc9f0` |

## Steps

1. **Receives request**: The Request Routing component (`requestRoutingComponent`) matches `GET /sitemap/{regionSlug}` to the `cities#main` route handler via the OpenAPI route definition in `modules/cities/open-api.js`. The `regionSlug` path parameter is extracted.
   - From: Web crawler / user agent
   - To: `continuumHtmlSiteMapWeb` (Request Routing)
   - Protocol: HTTPS

2. **Starts page tracking**: The Cities Sitemap Handler (`sitemapCitiesComponent`) calls `trackingHub.startPageRequest` with `pageType = 'html-site-map/cities/main'`.
   - From: `sitemapCitiesComponent`
   - To: itier-instrumentation (in-process)
   - Protocol: direct

3. **Constructs LPAPI resource path**: The handler resolves the LPAPI page ID and cities link type from i18n keys and constructs the path `/{pageId}/{regionSlug}/{linkType}`.
   - From: `sitemapCitiesComponent`
   - To: `lpapiClientComponent`
   - Protocol: direct (in-process)

4. **Fetches city crosslinks from LPAPI**: The LPAPI Client Adapter calls `lpapi.getPage({ id: lpapiId, locale, crosslinks: 'cities' })`. LPAPI returns the city crosslinks array and the region's `localName`.
   - From: `continuumHtmlSiteMapWeb` (`lpapiClientComponent`)
   - To: `continuumApiLazloService`
   - Protocol: HTTPS/JSON

5. **Formats crosslinks**: `formatCrosslinks()` extracts links of type `cities`, maps each to `{ anchorText, url, path }`, and strips the LPAPI page ID and `cities` path segment to produce relative sitemap paths.
   - From: `lpapiClientComponent`
   - To: `sitemapCitiesComponent`
   - Protocol: direct (in-process)

6. **Fetches shared page layout**: The Server-side Renderer calls the Remote Layout service to retrieve the shared page shell.
   - From: `pageRenderingComponent`
   - To: Remote Layout service
   - Protocol: HTTPS

7. **Composes and renders HTML response**: `preactPage()` composes the `Cities` Preact component with the formatted city list, the region's `localName`, `regionSlug`, CDN CSS asset URL, and locale-aware page title (including the region name). The Server-side Renderer produces a complete HTML document.
   - From: `pageRenderingComponent`
   - To: Web crawler / user agent
   - Protocol: HTTP 200 text/html

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown `regionSlug` (LPAPI returns 404) | `handlePageResponse` extracts `statusCode: 404` from LPAPI error | Cities handler returns `{ statusCode: 404 }` — triggers 404 error page flow |
| LPAPI unreachable | `handlePageResponse` defaults `statusCode` to 500 | HTTP 500 response |
| Remote Layout service unavailable | Handled by `remote-layout` library | Degraded page (body without shared shell) |

## Sequence Diagram

```
Crawler/User -> continuumHtmlSiteMapWeb: GET /sitemap/{regionSlug}
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: Construct LPAPI path (/{pageId}/{regionSlug}/{linkType})
continuumHtmlSiteMapWeb -> continuumApiLazloService: lpapi.getPage({ id, locale, crosslinks: 'cities' })
continuumApiLazloService --> continuumHtmlSiteMapWeb: { page: { crosslinks: [...cities], location: { localName } } }
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: formatCrosslinks() -> allCities[]
continuumHtmlSiteMapWeb -> RemoteLayoutService: Fetch page shell
RemoteLayoutService --> continuumHtmlSiteMapWeb: HTML header/nav/footer fragments
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: SSR Preact Cities component
continuumHtmlSiteMapWeb --> Crawler/User: HTTP 200 text/html (cities sitemap page)
```

## Related

- Architecture dynamic view: `dynamic-html-site-map-cities`
- Related flows: [Sitemap Home Page Request](sitemap-home-page-request.md), [Sitemap Categories Page Request](sitemap-categories-page-request.md), [Error Page Rendering](error-page-rendering.md)
