---
service: "travel-browse"
title: "Localization and i18n"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "localization-i18n"
flow_type: synchronous
trigger: "SSR request lifecycle — locale resolution on every request"
participants:
  - "continuumGetawaysBrowseWebApp"
  - "requestRouting"
  - "pageModules"
  - "renderingEngine"
  - "geodetailsV2Api"
architecture_ref: "dynamic-localization-i18n"
---

# Localization and i18n

## Summary

The localization and i18n flow describes how travel-browse resolves the request locale and applies internationalised content to each server-side rendered page. The service reads the `Accept-Language` header (and geo-slug context) to determine the active locale, loads the appropriate translation strings, and passes them to the rendering engine so that all user-visible text is rendered in the correct language before the HTML is delivered to the browser.

## Trigger

- **Type**: SSR request lifecycle
- **Source**: Embedded in every incoming page request processed by `continuumGetawaysBrowseWebApp`; fires before page module data assembly
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Getaways Browse Web App | Hosts the SSR pipeline; reads `Accept-Language` header | `continuumGetawaysBrowseWebApp` |
| Routing & Controllers | Extracts locale hints from request headers and geo-slug route parameter | `requestRouting` |
| Page Modules | Loads translation strings and builds i18n context for page assembly | `pageModules` |
| Rendering Engine | Renders React components using the resolved i18n context | `renderingEngine` |
| Geodetails V2 API | Provides geo metadata (country, currency, locale default) for the geo slug | `geodetailsV2Api` |

## Steps

1. **Receives request with locale signals**: `requestRouting` receives the incoming HTTP request and extracts locale signals: `Accept-Language` header value and the `:geo_slug` route parameter.
   - From: Browser / CDN
   - To: `requestRouting`
   - Protocol: HTTP

2. **Resolves geo locale default**: `pageModules` uses the geo metadata resolved from `geodetailsV2Api` (see [Browse Page Render](browse-page-render.md) Step 5) to determine the default locale and currency for the geographic market.
   - From: `pageModules`
   - To: Geo metadata (in-memory, already fetched as part of browse pipeline)
   - Protocol: Direct (in-process)

3. **Determines active locale**: `pageModules` selects the active locale by applying precedence rules: explicit user preference > `Accept-Language` header > geo-slug default locale.
   - From: `pageModules`
   - To: Internal locale resolution logic
   - Protocol: Direct (in-process)

4. **Loads translation strings**: `pageModules` loads the i18n translation bundle for the resolved locale. Translation files are bundled with the application (compiled at build time via Webpack 5).
   - From: `pageModules`
   - To: Bundled locale files (in-process)
   - Protocol: Direct (in-process)

5. **Builds i18n context**: `pageModules` assembles the i18n context object (locale code, currency, date format, translation function) and includes it in the page view model.
   - From: `pageModules`
   - To: `renderingEngine`
   - Protocol: Direct (in-process)

6. **Renders localised HTML**: `renderingEngine` uses the i18n context to render all user-visible text strings (page titles, labels, CTAs, price formatting, date formatting) in the active locale language.
   - From: `renderingEngine`
   - To: HTML output
   - Protocol: Direct (in-process)

7. **Returns localised HTML response**: `continuumGetawaysBrowseWebApp` delivers the fully localised HTML page to the browser. The active locale is embedded in the HTML (e.g., `<html lang="...">`) to support browser-side hydration consistency.
   - From: `continuumGetawaysBrowseWebApp`
   - To: Browser / CDN
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unrecognised `Accept-Language` header locale | Fall back to geo-slug default locale | Page renders in the geographic market default language |
| Geo slug resolves to unknown locale | Fall back to `en-US` (English, United States) | Page renders in English |
| Translation bundle for locale not found | Fall back to `en-US` bundle | English content rendered; no user-visible error |
| Geodetails unavailable (no geo metadata) | Use `Accept-Language` only; default to `en-US` if ambiguous | Page renders in English or browser-requested language |

## Sequence Diagram

```
Browser/CDN          -> requestRouting:    GET /travel/:geo_slug/hotels (Accept-Language: fr-FR)
requestRouting       -> pageModules:       Dispatch with locale signals (geo_slug, Accept-Language)
pageModules          -> pageModules:       Resolve geo metadata (from geodetailsV2Api response)
pageModules          -> pageModules:       Apply locale precedence: user pref > Accept-Language > geo default
pageModules          -> pageModules:       Load i18n bundle for resolved locale (bundled assets)
pageModules          -> renderingEngine:   View model with i18n context (locale, translations, formatters)
renderingEngine      -> renderingEngine:   Render React components with localised strings
renderingEngine      --> pageModules:      Localised HTML string
continuumGetawaysBrowseWebApp --> Browser/CDN: HTTP 200 + localised HTML (<html lang="fr">)
```

## Related

- Architecture dynamic view: `dynamic-localization-i18n`
- Related flows: [Browse Page Render](browse-page-render.md), [Market-Rate Inventory Fetch](market-rate-inventory-fetch.md)
- See [Configuration](../configuration.md) for locale-related environment variables
- See [Integrations](../integrations.md) for Geodetails V2 API dependency details
- See [Flows Index](index.md) for all flows
