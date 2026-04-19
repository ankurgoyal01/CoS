---
service: "html-site-map"
title: "Sitemap Categories Page Request"
generated: "2026-03-03"
type: flow
flow_name: "sitemap-categories-page-request"
flow_type: synchronous
trigger: "HTTP GET /sitemap/{regionSlug}/{citySlug}"
participants:
  - "Web crawler / user agent"
  - "continuumHtmlSiteMapWeb"
  - "continuumApiLazloService"
  - "Remote Layout service"
architecture_ref: "dynamic-html-site-map-categories"
---

# Sitemap Categories Page Request

## Summary

This flow handles an HTTP GET request to `/sitemap/{regionSlug}/{citySlug}` — the deepest level of the HTML sitemap hierarchy, which lists all available deal categories for a specific city. The service uses the `citySlug` path parameter to construct an LPAPI resource path, fetches the category crosslinks for that city, parses the city and region names from LPAPI's `fullName` field, and renders a locale-aware HTML page listing category links. This page is the terminal node in the sitemap hierarchy and provides search engines with direct links to Groupon's deal category pages for every supported city.

## Trigger

- **Type**: api-call (user-action or crawler)
- **Source**: Web crawler following a city link from a region's cities page, or a user clicking a city in the sitemap; request is routed to this service by the Groupon Routing Service via Hybrid Boundary
- **Frequency**: On-demand (per request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web crawler / user agent | Originates the HTTP GET request | — (stub in DSL: `unknownWebCrawlerClient_9e12ab3c`) |
| HTML Site Map Web | Handles routing, passes citySlug to LPAPI, renders HTML | `continuumHtmlSiteMapWeb` |
| LPAPI | Provides category crosslinks and city/region name metadata | `continuumApiLazloService` |
| Remote Layout service | Provides shared page shell (header, nav, footer) | stub: `unknownRemoteLayoutContainer_a41bc9f0` |

## Steps

1. **Receives request**: The Request Routing component (`requestRoutingComponent`) matches `GET /sitemap/{regionSlug}/{citySlug}` to the `categories#main` route handler via the OpenAPI route definition in `modules/categories/open-api.js`. Both `regionSlug` and `citySlug` path parameters are extracted.
   - From: Web crawler / user agent
   - To: `continuumHtmlSiteMapWeb` (Request Routing)
   - Protocol: HTTPS

2. **Starts page tracking**: The Categories Sitemap Handler (`sitemapCategoriesComponent`) calls `trackingHub.startPageRequest` with `pageType = 'html-site-map/categories/main'`.
   - From: `sitemapCategoriesComponent`
   - To: itier-instrumentation (in-process)
   - Protocol: direct

3. **Constructs LPAPI resource path**: The handler resolves the LPAPI page ID and categories link type from i18n keys and constructs the path `/{pageId}/{citySlug}` (note: only `citySlug` is used — the LPAPI identifier is city-scoped, not region+city).
   - From: `sitemapCategoriesComponent`
   - To: `lpapiClientComponent`
   - Protocol: direct (in-process)

4. **Fetches category crosslinks from LPAPI**: The LPAPI Client Adapter calls `lpapi.getPage({ id: lpapiId, locale, crosslinks: 'categories' })`. LPAPI returns the category crosslinks array and the city's `fullName` (formatted as `"CityName, RegionName"`).
   - From: `continuumHtmlSiteMapWeb` (`lpapiClientComponent`)
   - To: `continuumApiLazloService`
   - Protocol: HTTPS/JSON

5. **Parses city and region names**: The handler splits `fullName` on `", "` to extract `cityName` (index 0) and `regionName` (index 1) for use in page metadata and breadcrumbs.
   - From: `sitemapCategoriesComponent`
   - To: `sitemapCategoriesComponent`
   - Protocol: direct (in-process)

6. **Formats crosslinks**: `formatCrosslinks()` extracts links of type `categories`, maps each to `{ anchorText, url, path }`, and strips the LPAPI page ID from the URL path to produce relative sitemap paths.
   - From: `lpapiClientComponent`
   - To: `sitemapCategoriesComponent`
   - Protocol: direct (in-process)

7. **Fetches shared page layout**: The Server-side Renderer calls the Remote Layout service to retrieve the shared page shell.
   - From: `pageRenderingComponent`
   - To: Remote Layout service
   - Protocol: HTTPS

8. **Composes and renders HTML response**: `preactPage()` composes the `Categories` Preact component with the formatted categories list, `cityName`, `regionName`, `regionSlug`, `citySlug`, and locale-aware page title and meta description. The Server-side Renderer produces a complete HTML document including breadcrumb navigation (State > Region > City).
   - From: `pageRenderingComponent`
   - To: Web crawler / user agent
   - Protocol: HTTP 200 text/html

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown `citySlug` (LPAPI returns 404) | `handlePageResponse` extracts `statusCode: 404` from LPAPI error | Categories handler returns `{ statusCode: 404 }` — triggers 404 error page flow |
| LPAPI unreachable | `handlePageResponse` defaults `statusCode` to 500 | HTTP 500 response |
| `fullName` is null/undefined (LPAPI data issue) | Optional chaining `fullName?.split(', ') || []` returns empty array | `cityName` and `regionName` are undefined; page renders with blank title tokens |
| Remote Layout service unavailable | Handled by `remote-layout` library | Degraded page (body without shared shell) |

## Sequence Diagram

```
Crawler/User -> continuumHtmlSiteMapWeb: GET /sitemap/{regionSlug}/{citySlug}
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: Construct LPAPI path (/{pageId}/{citySlug})
continuumHtmlSiteMapWeb -> continuumApiLazloService: lpapi.getPage({ id, locale, crosslinks: 'categories' })
continuumApiLazloService --> continuumHtmlSiteMapWeb: { page: { crosslinks: [...categories], location: { fullName: "City, Region" } } }
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: Split fullName -> [cityName, regionName]
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: formatCrosslinks() -> allCategories[]
continuumHtmlSiteMapWeb -> RemoteLayoutService: Fetch page shell
RemoteLayoutService --> continuumHtmlSiteMapWeb: HTML header/nav/footer fragments
continuumHtmlSiteMapWeb -> continuumHtmlSiteMapWeb: SSR Preact Categories component
continuumHtmlSiteMapWeb --> Crawler/User: HTTP 200 text/html (categories sitemap page)
```

## Related

- Architecture dynamic view: `dynamic-html-site-map-categories`
- Related flows: [Sitemap Home Page Request](sitemap-home-page-request.md), [Sitemap Cities Page Request](sitemap-cities-page-request.md), [Error Page Rendering](error-page-rendering.md)
