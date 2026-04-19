---
service: "map_proxy"
title: "Static Map Request (v2)"
generated: "2026-03-03"
type: flow
flow_name: "static-map-request-v2"
flow_type: synchronous
trigger: "HTTP GET to /api/v2/static"
participants:
  - "mapProxy_requestIngress"
  - "mapProxy_providerSelection"
  - "mapProxy_googleAdapter"
  - "mapProxy_yandexAdapter"
architecture_ref: "dynamic-map-proxy-static-request"
---

# Static Map Request (v2)

## Summary

The v2 static map flow is the primary path for rendering static map images on Groupon's platforms. A caller (web app, mobile client, or email renderer) sends a GET request to `/api/v2/static` with geographic coordinates, zoom, size, and optional markers. MapProxy selects the appropriate provider (Google or Yandex) based on the request's country context, constructs a provider-specific signed URL, and issues an HTTP 302 redirect. The caller's browser or HTTP client follows the redirect to fetch the image directly from the upstream provider.

This flow is documented in the Structurizr dynamic view `dynamic-map-proxy-static-request`.

## Trigger

- **Type**: api-call
- **Source**: Any Groupon web, mobile, or email platform rendering a map image
- **Frequency**: On demand, per page/email render that includes a map

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (browser / HTTP client) | Initiates the GET request with map parameters | External |
| Request Ingress Servlets | Receives and validates the request; delegates to provider selection | `mapProxy_requestIngress` |
| Provider Selection | Resolves Google or Yandex based on country context | `mapProxy_providerSelection` |
| Google Maps Adapter | Builds and signs the Google Static Maps API URL | `mapProxy_googleAdapter` |
| Yandex Maps Adapter | Builds the Yandex Static Maps API URL with marker translation | `mapProxy_yandexAdapter` |
| Google Maps Static API | Upstream external image provider (non-Yandex countries) | External |
| Yandex Static Maps API | Upstream external image provider (Yandex countries) | External |

## Steps

1. **Receive request**: Caller sends `GET /api/v2/static` with parameters `lat`, `lng`, `zoom`, `size`, `client`, and optionally `country`, `markers`.
   - From: Caller
   - To: `mapProxy_requestIngress` (StaticMapsV2Servlet)
   - Protocol: HTTP/HTTPS

2. **Validate required parameters**: StaticMapsV2Servlet checks that `lat`, `lng`, `zoom`, `size`, and `client` are all non-blank. Returns HTTP 400 immediately if any is missing.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal validation)
   - Protocol: direct

3. **Cap zoom level**: If the supplied `zoom` value exceeds 18, it is capped at 18 (the maximum supported by Google and Yandex).
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal)
   - Protocol: direct

4. **Resolve provider**: Calls `MapProvider.create(request, country)`. The resolution order is: (a) `country` query parameter; (b) `X-Country` HTTP header; (c) TLD parsed from `Referer` header host; (d) TLD parsed from `Host` header. If the resolved country code is in the `MapProxy.yandex.countryList`, a `YandexV2Provider` is instantiated; otherwise a `GoogleV3Provider` is instantiated.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_providerSelection`
   - Protocol: direct

5. **Build provider URL (Google path)**: GoogleV3Provider assembles the query string: `maptype=roadmap`, `sensor=false`, `size={size}`, `channel={client}`, `center={lat},{lng}`, `zoom={zoom}` (when no markers, or when a single marker is supplied), and translated `markers=...` for each marker. Appends `client={clientId}`. Signs the full path + query string using HMAC-SHA1 and the `MapProxy.google.signingKey`, producing a `&signature=...` suffix.
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_googleAdapter`
   - Protocol: direct

6. **Build provider URL (Yandex path)**: YandexV2Provider assembles the Yandex query string: `lang=en-US`, `l=map`, `size={width},{height}` (capped at 450x650), `ll={lng},{lat}`, `z={zoom}`, and `pt=...` for markers (translating color names to Yandex codes and enforcing numeric-only labels).
   - From: `mapProxy_providerSelection`
   - To: `mapProxy_yandexAdapter`
   - Protocol: direct

7. **Log and redirect**: StaticMapsV2Servlet logs a structured info line including URI, country, provider name, lat, lng, zoom, size, client, and markers. Sets `Connection: close` header. Issues HTTP 302 redirect to the provider URL.
   - From: `mapProxy_requestIngress`
   - To: Caller
   - Protocol: HTTP 302

8. **Caller fetches image**: The caller's browser or HTTP client follows the 302 redirect and fetches the map image directly from the upstream provider (Google or Yandex). MapProxy is not involved in this final step.
   - From: Caller
   - To: Google Maps Static API or Yandex Static Maps API
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required parameter (`lat`, `lng`, `zoom`, `size`, or `client`) | StaticMapsV2Servlet logs `[StaticV2] Bad request:` and sets HTTP 400; returns immediately with no body | Caller receives HTTP 400 |
| Zoom value exceeds 18 | Zoom is silently capped to 18 | Request proceeds normally |
| Country cannot be resolved | Defaults to GoogleV3Provider | Request proceeds with Google as provider |
| Country is in Yandex list but Yandex size constraints violated | YandexV2Provider silently truncates width to 450 and height to 650 | Map is rendered at reduced size |
| Marker label is alphabetic on Yandex path | Label is discarded (Yandex only supports numeric labels) | Marker is rendered without a label |

## Sequence Diagram

```
Caller -> mapProxy_requestIngress: GET /api/v2/static?lat=...&lng=...&size=...&client=...
mapProxy_requestIngress -> mapProxy_requestIngress: Validate required params (400 if missing)
mapProxy_requestIngress -> mapProxy_requestIngress: Cap zoom at 18
mapProxy_requestIngress -> mapProxy_providerSelection: MapProvider.create(request, country)
mapProxy_providerSelection -> mapProxy_googleAdapter: new GoogleV3Provider() [non-Yandex country]
mapProxy_googleAdapter --> mapProxy_providerSelection: signed Google Static Maps URL
mapProxy_providerSelection -> mapProxy_yandexAdapter: new YandexV2Provider() [Yandex country]
mapProxy_yandexAdapter --> mapProxy_providerSelection: Yandex Static Maps URL
mapProxy_providerSelection --> mapProxy_requestIngress: provider.buildQueryUrl(...)
mapProxy_requestIngress -> Caller: HTTP 302 Location: <provider URL>
Caller -> Google Maps Static API: GET <signed URL>
Google Maps Static API --> Caller: image/png
```

## Related

- Architecture dynamic view: `dynamic-map-proxy-static-request`
- Related flows: [Provider Selection](provider-selection.md), [Static Map Proxy Request (v1)](static-map-proxy-v1.md)
