---
service: "map_proxy"
title: "Static Map Proxy Request (v1)"
generated: "2026-03-03"
type: flow
flow_name: "static-map-proxy-v1"
flow_type: synchronous
trigger: "HTTP GET to /maps/api/staticmap"
participants:
  - "mapProxy_requestIngress"
  - "mapProxy_googleAdapter"
architecture_ref: "components-continuum-map-proxy-service"
---

# Static Map Proxy Request (v1)

## Summary

The v1 static map flow is a simple signing proxy for Google Maps Static API requests. The caller constructs a Google Maps Static API request and sends it to MapProxy at `/maps/api/staticmap`. MapProxy appends the Google Maps for Business client ID (if absent), sanitises the `channel` parameter (replacing pipe characters that Google rejects), signs the full request URI using HMAC-SHA1, and issues an HTTP 302 redirect to the signed Google Maps URL. Unlike the v2 flow, this endpoint does not perform provider selection — it always routes to Google.

## Trigger

- **Type**: api-call
- **Source**: Groupon web and email platform clients that send near-raw Google Maps Static API parameters
- **Frequency**: On demand, per map image render

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (browser / HTTP client) | Initiates the GET request with Google Maps parameters | External |
| Request Ingress Servlets | Receives request, appends client ID, sanitises channel, initiates signing and redirect | `mapProxy_requestIngress` |
| Google Maps Adapter (UrlSigner) | Performs HMAC-SHA1 signing of the request URI | `mapProxy_googleAdapter` |
| Google Maps Static API | Upstream external image provider | External |

## Steps

1. **Receive request**: Caller sends `GET /maps/api/staticmap` with Google Maps Static API parameters (e.g. `center`, `zoom`, `size`, `markers`, `channel`, etc.).
   - From: Caller
   - To: `mapProxy_requestIngress` (StaticMapsServlet)
   - Protocol: HTTP/HTTPS

2. **Detect protocol**: StaticMapsServlet reads the `X-Forwarded-Proto` header to determine whether to construct an `http://` or `https://` redirect URL. Falls back to the request's `isSecure()` flag if the header is absent.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal)
   - Protocol: direct

3. **Append client ID**: CommonMapsServlet's `queryString()` method checks if the `client` query parameter is present. If absent, appends `&client={MapProxy.google.clientID}` to the query string.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal)
   - Protocol: direct

4. **Sanitise channel parameter**: If a `channel` parameter is present, replaces any `%7C` (URL-encoded pipe) or literal `|` characters with `-`, since Google Maps for Business does not accept pipe characters in channel names.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_requestIngress` (internal, regex)
   - Protocol: direct

5. **Sign request**: Instantiates `UrlSigner` with the `MapProxy.google.signingKey` private key. Calls `signer.signRequest(requestURI, queryString)` which computes HMAC-SHA1 of `{path}?{query}`, Base64-encodes the signature (web-safe), and appends `&signature={sig}` to the resource string.
   - From: `mapProxy_requestIngress`
   - To: `mapProxy_googleAdapter` (UrlSigner)
   - Protocol: direct

6. **Log and redirect**: Logs a structured request line including method, protocol, URI, query string, HTTP status, latency, request ID, host, referer, and user-agent. Sets `Connection: close`. Issues HTTP 302 redirect to `{protocol}://{MapProxy.staticMapHost}{signedResource}`.
   - From: `mapProxy_requestIngress`
   - To: Caller
   - Protocol: HTTP 302

7. **Caller fetches image**: Caller's browser or HTTP client follows the 302 redirect to fetch the image from Google Maps Static API.
   - From: Caller
   - To: Google Maps Static API
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HMAC signing failure (`NoSuchAlgorithmException`, `InvalidKeyException`, `URISyntaxException`) | Logs HTTP 500 error line with full request context; does not set response status or body | Caller receives a connection-close response with no body; map image fails to load |
| `channel` contains pipe characters | Pipes are silently replaced with `-` | Request proceeds normally with sanitised channel |
| `client` parameter absent | Client ID is appended from `MapProxy.google.clientID` config | Request proceeds normally |

## Sequence Diagram

```
Caller -> mapProxy_requestIngress: GET /maps/api/staticmap?center=...&zoom=...&size=...&channel=...
mapProxy_requestIngress -> mapProxy_requestIngress: Detect protocol (X-Forwarded-Proto or isSecure)
mapProxy_requestIngress -> mapProxy_requestIngress: Append client ID if absent
mapProxy_requestIngress -> mapProxy_requestIngress: Sanitise channel (replace | with -)
mapProxy_requestIngress -> mapProxy_googleAdapter: UrlSigner.signRequest(requestURI, queryString)
mapProxy_googleAdapter -> mapProxy_googleAdapter: HMAC-SHA1(path?query, signingKey)
mapProxy_googleAdapter --> mapProxy_requestIngress: signed resource string (?...&signature=...)
mapProxy_requestIngress -> Caller: HTTP 302 Location: https://maps.googleapis.com/maps/api/staticmap?...&signature=...
Caller -> Google Maps Static API: GET <signed URL>
Google Maps Static API --> Caller: image/png
```

## Related

- Related flows: [Static Map Request (v2)](static-map-request-v2.md), [Provider Selection](provider-selection.md)
- Architecture component view: `components-continuum-map-proxy-service`
