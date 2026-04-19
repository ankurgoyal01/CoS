---
service: "merchant-page"
title: "Map Image Signing Flow"
generated: "2026-03-03"
type: flow
flow_name: "map-image-signing"
flow_type: synchronous
trigger: "HTTP GET /merchant-page/maps/image"
participants:
  - "mapsRouteHandler"
  - "mapSigningAdapter"
  - "gims"
architecture_ref: "dynamic-merchant-page-request-flow"
---

# Map Image Signing Flow

## Summary

The Map Image Signing flow generates a signed URL for a static map image showing the merchant's location, then issues an HTTP redirect to that signed URL. The Maps Route Handler receives size, marker, and provider parameters from the browser client, calls GIMS (the Groupon Image / Map Signing Service) via the `@grpn/itier-maps` library, and redirects the browser to the signed map tile URL. This allows the browser to display a static map image without exposing the API credentials used to sign the request.

## Trigger

- **Type**: api-call (AJAX/image request from hydrated browser client or server-side `<img>` tag)
- **Source**: Browser requests the map image URL embedded in the merchant page
- **Frequency**: On-demand (once per merchant page view that includes a map)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Maps Route Handler | Receives the map image request and delegates signing | `mapsRouteHandler` |
| Map Signing Adapter | Generates signed map URL via `@grpn/itier-maps` | `mapSigningAdapter` |
| GIMS | Signs and returns the map tile URL | `gims` |

## Steps

1. **Receives map image request**: Maps Route Handler receives `GET /merchant-page/maps/image` with query parameters (`size`, `markers`, `provider`).
   - From: browser client
   - To: `mapsRouteHandler`
   - Protocol: HTTPS

2. **Parses marker data**: Parses the `markers` query parameter from JSON string to an array of marker objects.
   - From: `mapsRouteHandler`
   - To: in-process
   - Protocol: direct

3. **Resolves map configuration**: Reads `clientId` and `defaultZoom` from `config.mapConfig`; reads `apiProxyBaseUrl` and `connectTimeout` from `config.serviceClient.globalDefaults`.
   - From: `mapsRouteHandler`
   - To: keldor config (in-process)
   - Protocol: direct

4. **Requests signed map URL**: Calls `@grpn/itier-maps` `getMapUrl` with map options (zoom, markers, language, size, maptype `roadmap`) and provider config (defaults to `maptiler`).
   - From: `mapSigningAdapter`
   - To: `gims`
   - Protocol: HTTPS/JSON via `apiProxyBaseUrl`

5. **Receives signed URL**: GIMS returns a signed URL for the map tile.
   - From: `gims`
   - To: `mapSigningAdapter`
   - Protocol: HTTPS/JSON

6. **Issues redirect**: Maps Route Handler returns an HTTP redirect to the signed map tile URL.
   - From: `mapsRouteHandler`
   - To: browser client
   - Protocol: HTTPS (302 redirect)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GIMS call fails (network error, signing failure) | Error silently caught (`catch { // no-op }`); `mapUrl` remains `undefined` | `redirect(undefined)` — browser receives redirect with no URL; map image fails to load |
| Invalid `markers` JSON | `JSON.parse` throws; error propagates through itier-server | Request may error or markers default to `[]` |
| Missing `size` parameter | Passed as `undefined` to GIMS; GIMS may return error | Map image fails silently |

## Sequence Diagram

```
Browser          mapsRouteHandler     mapSigningAdapter (@grpn/itier-maps)    gims
   |                   |                        |                              |
   |--GET /merchant-page/maps/image?size=320x200&markers=[...]-->|             |
   |                   |                        |                              |
   |                   |--Parse markers, resolve config (in-process)           |
   |                   |                        |                              |
   |                   |--Generate signed URL-->|                              |
   |                   |                        |--Sign map image request----->|
   |                   |                        |<--signed URL----------------|
   |                   |                        |                              |
   |                   |<--signed URL-----------|                              |
   |                   |                        |                              |
   |<--302 redirect to signed map tile URL------|                              |
   |                   |                        |                              |
   |--GET <signed map tile URL>------(to MapTiler CDN, external)-----------   |
```

## Related

- Architecture dynamic view: `dynamic-merchant-page-request-flow`
- Related flows: [Merchant Page Request](merchant-page-request.md)
