---
service: "image-service-config"
title: "Image Request Cache Miss"
generated: "2026-03-03"
type: flow
flow_name: "image-request-cache-miss"
flow_type: synchronous
trigger: "HTTP GET request from an upstream consumer to img.grouponcdn.com for an image not in cache"
participants:
  - "Client (upstream consumer)"
  - "continuumImageServiceNginxCacheProxy"
  - "continuumImageServiceProxyCacheStore"
  - "continuumImageServiceAppRuntime"
  - "AWS S3 (image-service bucket)"
architecture_ref: "dynamic-imageServiceConfig"
---

# Image Request Cache Miss

## Summary

An upstream consumer requests a resized image that is not present in the Nginx proxy cache. The Virtual Host Router routes the request through the Backend Proxy (`nginxBackendProxy`) to the Python image-service app backend. The app validates the client API key and requested size against `config.yml`, fetches the original image from AWS S3, performs the resize transformation, and returns the result. Nginx stores the response in the proxy cache for subsequent requests.

## Trigger

- **Type**: api-call
- **Source**: Upstream consumer (browser, mobile app, or named API client from `config.yml`) requesting an image URL not yet cached
- **Frequency**: Per-request; common for newly uploaded images or cold cache nodes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Client (browser / app / API) | Initiates image HTTP GET request | External |
| Virtual Host Router | Routes request to image-serving server block | `nginxVirtualHostRouter` |
| Backend Proxy | Forwards cache-miss requests upstream to app backend | `nginxBackendProxy` |
| Proxy Cache Engine | Detects cache miss; writes response after backend returns | `nginxProxyCacheEngine` |
| Nginx Proxy Cache Store | Filesystem; updated with new cache entry on successful backend response | `continuumImageServiceProxyCacheStore` |
| Image Request Handler | Receives proxied request; validates API key and image size | `imageRequestHandler` |
| Config Loader | Supplies client API key and allowed-size policy | `imageServiceConfigLoader` |
| Image Resize Engine | Fetches original image from S3 and performs transformation | `imageResizeEngine` |
| AWS S3 (`image-service` bucket) | Origin store for original image assets | External (S3) |

## Steps

1. **Client sends image request**: Client sends `GET /v1/groupon/deal/450x300/abc123.jpg` to `img.grouponcdn.com:80`.
   - From: Client
   - To: `continuumImageServiceNginxCacheProxy`
   - Protocol: HTTP

2. **Virtual Host Router matches server block**: Nginx matches request to the CDN server block and routes to `location /`.
   - From: `nginxVirtualHostRouter`
   - To: `nginxBackendProxy`
   - Protocol: Internal Nginx routing

3. **Proxy Cache Engine detects miss**: Cache key `img.grouponcdn.com/v1/groupon/deal/450x300/abc123.jpg` is not found in `/var/nginx_proxy_cache`. `$upstream_cache_status` = `MISS`.
   - From: `nginxProxyCacheEngine`
   - To: `continuumImageServiceProxyCacheStore` (filesystem lookup)
   - Protocol: Filesystem I/O

4. **Backend Proxy forwards request**: `nginxBackendProxy` forwards the request to `upstream backend` (`global-image-service-app-vip:80`), which round-robins across the 48 worker ports (4 nodes × 12 processes each) within `proxy_read_timeout 30s`.
   - From: `nginxBackendProxy`
   - To: `imageRequestHandler` (Python app, one of ports 8000–8011 on one of the app nodes)
   - Protocol: HTTP

5. **Config Loader validates request**: `imageServiceConfigLoader` reads `config.yml`, looks up the client by API key, and verifies that the requested image dimension (e.g., `450x300`) is in the client's `allowed_sizes` list.
   - From: `imageRequestHandler`
   - To: `imageServiceConfigLoader`
   - Protocol: In-process call

6. **Image Resize Engine fetches original from S3**: `imageResizeEngine` retrieves the original image from the `image-service` S3 bucket using the S3 credentials from `config.yml` (`access_key_id: <REDACTED>`, `proxy_host: <S3_PROXY_VIP>`).
   - From: `imageResizeEngine`
   - To: AWS S3 `image-service` bucket
   - Protocol: S3 API (HTTP via S3-proxy VIP)

7. **Image Resize Engine transforms image**: Resizes and/or crops the original image to the requested dimensions.
   - From: `imageResizeEngine` (in-process)
   - To: `imageRequestHandler`
   - Protocol: In-process call

8. **App returns transformed image**: `imageRequestHandler` returns the transformed image bytes to Nginx backend proxy with appropriate HTTP headers.
   - From: `imageRequestHandler`
   - To: `nginxBackendProxy`
   - Protocol: HTTP

9. **Proxy Cache Engine stores response**: `nginxProxyCacheEngine` writes the response to `/var/nginx_proxy_cache` using the cache key. Entry remains active for up to 30 days (`inactive=30d`).
   - From: `nginxProxyCacheEngine`
   - To: `continuumImageServiceProxyCacheStore`
   - Protocol: Filesystem I/O

10. **Nginx returns image to client**: Nginx streams the transformed image bytes to the client. Access log records `upstream_cache_status=MISS`.
    - From: `continuumImageServiceNginxCacheProxy`
    - To: Client
    - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client API key not found in `config.yml` | `imageServiceConfigLoader` rejects the request | App returns 4xx error to client |
| Requested size not in client's `allowed_sizes` | `imageServiceConfigLoader` rejects the request | App returns 4xx error to client |
| S3 primary bucket unavailable | `imageResizeEngine` / S3-proxy upstream fails over to `image-service-west.s3.amazonaws.com` | Increased latency; backup region serves the asset |
| Both S3 buckets unavailable | Image fetch fails in `imageResizeEngine` | App returns 5xx; Nginx logs upstream error; client receives 502/504 |
| Backend app timeout (>30s) | Nginx `proxy_read_timeout 30` exceeded | Nginx returns 504 Gateway Timeout to client |
| Backend app completely unavailable | All upstream servers in `upstream backend` fail health check | Nginx returns 502 Bad Gateway; cached responses still served for HIT paths |

## Sequence Diagram

```
Client -> nginxVirtualHostRouter: GET /v1/groupon/deal/450x300/abc123.jpg
nginxVirtualHostRouter -> nginxBackendProxy: Route to location /
nginxBackendProxy -> nginxProxyCacheEngine: Check proxy cache
nginxProxyCacheEngine -> ProxyCacheStore: Lookup "img.grouponcdn.com/...abc123.jpg"
ProxyCacheStore --> nginxProxyCacheEngine: Cache MISS
nginxBackendProxy -> imageRequestHandler: HTTP GET (proxy_pass to global-image-service-app-vip:80)
imageRequestHandler -> imageServiceConfigLoader: Validate API key + allowed size
imageServiceConfigLoader --> imageRequestHandler: Authorized (450x300 allowed)
imageRequestHandler -> imageResizeEngine: Fetch and resize image
imageResizeEngine -> S3_image-service: GET original image (via image-service-s3-proxy-vip.snc1)
S3_image-service --> imageResizeEngine: Original image bytes
imageResizeEngine --> imageRequestHandler: Resized image bytes
imageRequestHandler --> nginxBackendProxy: HTTP 200 (image/jpeg)
nginxBackendProxy -> nginxProxyCacheEngine: Store response in cache
nginxProxyCacheEngine -> ProxyCacheStore: Write cache entry
nginxBackendProxy --> Client: HTTP 200 (image/jpeg), upstream_cache_status: MISS
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [Image Request Cache Hit](image-request-cache-hit.md), [S3 Proxy Request](s3-proxy-request.md)
