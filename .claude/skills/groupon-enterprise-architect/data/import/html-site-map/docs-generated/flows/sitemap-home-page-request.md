---
service: "html-site-map"
title: "Sitemap Home Page Request"
generated: "2026-03-03"
type: flow
flow_name: "sitemap-home-page-request"
flow_type: synchronous
trigger: "HTTP GET /sitemap"
participants:
  - "Web crawler / user agent"
  - "continuumHtmlSiteMapWeb"
  - "continuumApiLazloService"
  - "Remote Layout service"
architecture_ref: "dynamic-html-site-map-home"
---

# Sitemap Home Page Request

## Summary

This flow handles an HTTP GET request to `/sitemap` — the top-level HTML sitemap page that lists all US states and geographic regions available on Groupon. The service fetches the full list of state crosslinks from LPAPI, formats them into navigable HTML links, composes a server-rendered Preact page with shared layout fragments, and returns a complete HTML response. This page is the entry point for both search engine crawlers (indexing Groupon's geographic content hierarchy) and users looking to browse by location.

## Trigger

- **Type**: api-call (user-action or crawler)
- **Source**: Web browser navigating to `https://www.groupon.{tld}/sitemap`, or a web crawler (e.g. Googlebot) following the sitemap link; routed to this service by the Groupon Routing Service via Hybrid Boundary
- **Frequency**: On-demand (per request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web crawler / user agent | Originates the HTTP GET request | — (stub in DSL: `unknownWebCrawlerClient_9e12ab3c`) |
| HTML Site Map Web | Handles routing, calls LPAPI, renders HTML response | `continuumHtmlSiteMapWeb` |
| LPAPI | Provides state/region crosslink data | `continuumApiLazloService` |
| Remote Layout service | Provides shared page shell (header, nav, footer) | stub: `unknownRemoteLayoutContainer_a41bc9f0` |

## Steps

1. **Receives request**: The Request Routing component (`requestRoutingComponent`) matches `GET /sitemap` to the `home#main` route handler via the OpenAPI route definition in `modules/home/open-api.js`.
   - From: Web crawler / user agent
   - To: `continuumHtmlSiteMapWeb` (Request Routing)
   - Protocol: HTTPS

2. **Starts page tracking**: The Home Sitemap Handler (`sitemapHomeComponent`) calls `trackingHub.startPageRequest` with `pageType = 'html-site-map/home/main'` to begin instrumentation.
   - From: `sitemapHomeComponent`
   - To: itier-instrumentation (in-process)
   - Protocol: direct

3. **Resolves LPAPI resource ID**: The handler resolves the LPAPI page ID and link type from i18n keys (`modules.lpapi.page_id`, `modules.lpapi.link_type.states`) and constructs the LPAPI path `/{pageId}/{linkType}`.
   - From: `sitemapHomeComponent`
   - To: `lpapiClientComponent`
   - Protocol: direct (in-process)

4. **Fetches state crosslinks from LPAPI**: The LPAPI Client Adapter (`lpapiClientComponent`) calls `lpapi.getPage({ id, locale, crosslinks })` to retrieve the full list of state links.
   - From: `continuumHtmlSiteMapWeb` (`lpapiClientComponent`)
   - To: `continuumApiLazloService`
   - Protocol: HTTPS/JSON

5. **Formats crosslinks**: `formatCrosslinks()` in `modules/support/lpapi-helper.js` extracts the links matching the `states` type, maps each to `{ anchorText, url, path }`, and derives a relative sitemap path from the fully qualified LPAPI URL.
   - From: `lpapiClientComponent`
   - To: `sitemapHomeComponent`
   - Protocol: direct (in-process)

6. **Fetches shared page layout**: The Server-side Renderer (`pageRenderingComponent`) calls the Remote Layout service via `remote-layout` to retrieve the shared Groupon page shell (header, navigation, footer).
   - From: `pageRenderingComponent`
   - To: Remote Layout service
   - Protocol: HTTPS

7. **Composes and renders HTML response**: `preactPage()` composes the `Home` Preact component with the formatted state list, locale-aware page title and meta description, CDN-hosted CSS asset URL, and the Google Tag Manager snippet; the Server-side Renderer produces a complete HTML document.
   - From: `pageRenderingComponent`
   - To: Web crawler / user agent
   - Protocol: HTTP 200 text/html

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LPAPI returns non-200 status | `handlePageResponse` catches the error and extracts `statusCode` from the thrown error | Home handler returns `{ statusCode }` — itier-server maps this to the corresponding HTTP error response |
| LPAPI is unreachable (network error) | `handlePageResponse` catch block defaults `statusCode` to 500 if not provided | HTTP 500 response |
| Remote Layout service unavailable | Handled by `remote-layout` library; partial page may render | Degraded page (body content without shared shell) |

## Sequence Diagram

```
Crawler/User -> continuumHtmlSiteMapWeb: GET /sitemap
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: Resolve LPAPI path (/{pageId}/{linkType})
continuumHtmlSiteMapWeb -> continuumApiLazloService: lpapi.getPage({ id, locale, crosslinks: 'states' })
continuumApiLazloService --> continuumHtmlSiteMapWeb: { page: { crosslinks: [...states] } }
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: formatCrosslinks() -> allStates[]
continuumHtmlSiteMapWeb -> RemoteLayoutService: Fetch page shell
RemoteLayoutService --> continuumHtmlSiteMapWeb: HTML header/nav/footer fragments
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: SSR Preact Home component
continuumHtmlSiteMapWeb --> Crawler/User: HTTP 200 text/html (full sitemap home page)
```

## Related

- Architecture dynamic view: `dynamic-html-site-map-home`
- Related flows: [Sitemap Cities Page Request](sitemap-cities-page-request.md), [Sitemap Categories Page Request](sitemap-categories-page-request.md), [Error Page Rendering](error-page-rendering.md)
