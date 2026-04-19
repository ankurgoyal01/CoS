---
service: "map_proxy"
title: "Dynamic Map JavaScript Request (v2)"
generated: "2026-03-03"
type: flow
flow_name: "dynamic-map-js-request-v2"
flow_type: synchronous
trigger: "HTTP GET to /api/v2/dynamic"
participants:
  - "mapProxy_requestIngress"
  - "mapProxy_providerSelection"
  - "mapProxy_googleAdapter"
  - "mapProxy_yandexAdapter"
  - "mapProxy_assetComposer"
architecture_ref: "components-continuum-map-proxy-service"
---

# Dynamic Map JavaScript Request (v2)

## Summary

The v2 dynamic flow returns a composed JavaScript payload that enables interactive map rendering on Groupon's web and mobile pages. The caller sends a GET request to `/api/v2/dynamic`; MapProxy selects the appropriate provider (Google or Yandex) by geography, loads a JS template and provider library from the classpath, substitutes runtime values (provider library URL, static files base URL, callback function name), and writes the completed JavaScript to the response body. Unlike the static and v1 dynamic flows, this endpoint does not redirect — it returns `text/javascript` inline.

## Trigger

- **Type**: api-call
- **Source**: Groupon web, mobile, or layout-service clients that need to initialise an interactive map
- **Frequency**: On demand, once per page load that includes a dynamic map widget

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (browser / HTTP client) | Initiates the GET request for dynamic JS | External |
| Request Ingress Servlets | Validates the request and drives response composition | `mapProxy_requestIngress` |
| Provider Selection | Resolves Google or Yandex based on country context | `mapProxy_providerSelection` |
| Google Maps Adapter | Supplies the pre-signed Google Maps JS library URL | `mapProxy_googleAdapter` |
| Yandex Maps Adapter | Supplies the Yandex Maps dynamic library URL | `mapProxy_yandexAdapter` |
| Dynamic JS Composer | Loads classpath templates, substitutes placeholders, emits JS | `mapProxy_assetComposer` |

## Steps

1. **Receive request**: Caller sends `GET /api/v2/dynamic` with `client` (required) and optionally `country` and `callback`.
   - From: Caller
   - To: `mapProxy_requestIngress` (DynamicMapsV2Servlet)
   - Protocol: HTTP/HTTPS

2. **Validate client parameter**: DynamicMapsV2Servlet checks that `client` is non-blank. Returns HTTP 400 immediately if absent.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal validation)
   - Protocol: direct

3. **Default callback**: If `callback` parameter is absent, it is set to the string literal `"null"` (not the null value), which is substituted into the JS template to produce a no-op.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal)
   - Protocol: direct

4. **Resolve provider**: Calls `MapProvider.create(request, country)` using the same resolution order as the static v2 flow (country param → `X-Country` header → Referer TLD → Host header). Instantiates either `GoogleV3Provider` or `YandexV2Provider`.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_providerSelection`
   - Protocol: direct

5. **Load JS template**: DynamicMapsV2Servlet reads the provider-specific JS template from the classpath path `provider.getTemplateFilename()` (e.g. `/js-templates/googlev3.js` or `/js-templates/yandexv2.js`). Returns HTTP 404 if the template is not found on the classpath.
   - From: `mapProxy_assetComposer`
   - To: classpath resource
   - Protocol: direct (DataInputStream)

6. **Load provider JS library**: Reads the provider-specific compiled JS library from `provider.getProviderFilename()` (e.g. `/js-libraries/googlev3.js` or `/js-libraries/yandexv2.js`).
   - From: `mapProxy_assetComposer`
   - To: classpath resource
   - Protocol: direct (DataInputStream)

7. **Compose payload**: Substitutes three placeholders in the JS template:
   - `{{ libraryUrl }}` → `provider.getDynamicLibraryUrl()` — the pre-signed Google Maps JS URL (or the Yandex library URL).
   - `{{ staticFilesBaseUrl }}` → `provider.getStaticFilesBaseUrl()` — the base URL for serving Mapstraction static files (from `MapProxy.staticFilesBaseUrl`).
   - `{{ allFilesIncluded }}` → the full text of the provider JS library file.
   - `{{ callback }}` → the callback function name from the request, or `"null"`.
   - From: `mapProxy_assetComposer`
   - To: `mapProxy_assetComposer` (internal string substitution)
   - Protocol: direct

8. **Return JavaScript payload**: Sets `Content-Type: text/javascript;charset=UTF-8` and HTTP 200. Writes the composed JS to the response body. Logs `[DynamicV2] uri=..., country=..., provider=..., client=..., callback=...`.
   - From: `mapProxy_requestIngress`
   - To: Caller
   - Protocol: HTTP 200 with body

9. **Caller initialises map**: The caller executes the returned JavaScript, which loads the provider library (Google Maps JS or Yandex Maps JS) and invokes `MapProxy.createMap('dom-element')` via the Mapstraction abstraction layer.
   - From: Caller (browser)
   - To: Google Maps JavaScript API or Yandex Maps dynamic library
   - Protocol: HTTPS (browser-initiated)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `client` parameter is absent | HTTP 400, logs `[DynamicV2] Bad request:` | Caller receives HTTP 400 |
| Provider JS template not found on classpath | HTTP 404, logs `[DynamicV2] File not found:` | Caller receives HTTP 404; map fails to load |
| IOException reading classpath resources | HTTP 500, logs `[DynamicV2] IOException` | Caller receives HTTP 500 |
| `callback` parameter absent | Defaults to string `"null"` | JS payload is returned without a load callback |
| Country not in Yandex list (ambiguous country) | Defaults to GoogleV3Provider | Google JS library is returned |

## Sequence Diagram

```
Caller -> mapProxy_requestIngress: GET /api/v2/dynamic?client=...&country=...&callback=...
mapProxy_requestIngress -> mapProxy_requestIngress: Validate client (400 if blank)
mapProxy_requestIngress -> mapProxy_requestIngress: Default callback to "null" if absent
mapProxy_requestIngress -> mapProxy_providerSelection: MapProvider.create(request, country)
mapProxy_providerSelection --> mapProxy_requestIngress: GoogleV3Provider or YandexV2Provider
mapProxy_assetComposer -> classpath: load /js-templates/{provider}.js
classpath --> mapProxy_assetComposer: JS template bytes
mapProxy_assetComposer -> classpath: load /js-libraries/{provider}.js
classpath --> mapProxy_assetComposer: library JS bytes
mapProxy_assetComposer -> mapProxy_assetComposer: substitute {{ libraryUrl }}, {{ staticFilesBaseUrl }}, {{ allFilesIncluded }}, {{ callback }}
mapProxy_requestIngress -> Caller: HTTP 200 text/javascript (composed JS payload)
Caller -> Google Maps JS API: load maps.googleapis.com/maps/api/js?... (browser-initiated)
```

## Related

- Related flows: [Provider Selection](provider-selection.md), [Static Map Request (v2)](static-map-request-v2.md)
- Architecture component view: `components-continuum-map-proxy-service`
