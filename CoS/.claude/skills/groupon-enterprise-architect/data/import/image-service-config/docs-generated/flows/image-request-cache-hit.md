---
service: "image-service-config"
title: "Image Request Cache Hit"
generated: "2026-03-03"
type: flow
flow_name: "image-request-cache-hit"
flow_type: synchronous
trigger: "HTTP GET request from an upstream consumer to img.grouponcdn.com"
participants:
  - "Client (upstream consumer)"
  - "continuumImageServiceNginxCacheProxy"
  - "continuumImageServiceProxyCacheStore"
architecture_ref: "dynamic-imageServiceConfig"
---

# Image Request Cache Hit

## Summary

An upstream consumer (browser, mobile app, or internal service) sends an HTTP GET request for a resized image to `img.grouponcdn.com`. Nginx checks its disk-backed proxy cache using the cache key `$host$uri`. If a valid cache entry exists, Nginx serves the image directly from the `/var/nginx_proxy_cache` filesystem without contacting the Python backend or AWS S3. This is the primary high-throughput path.

## Trigger

- **Type**: api-call
- **Source**: Upstream consumer (browser, mobile app, or internal API client) using CDN hostname
- **Frequency**: Per-request; this is the dominant code path for a warm cache

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Client (browser / app / API) | Initiates image HTTP GET request | External |
| Virtual Host Router | Routes request based on `Host` header to the image-serving server block | `nginxVirtualHostRouter` |
| Proxy Cache Engine | Looks up cache key `$host$uri`; returns cache entry on hit | `nginxProxyCacheEngine` |
| Nginx Proxy Cache Store | Filesystem at `/var/nginx_proxy_cache`; stores cached responses | `continuumImageServiceProxyCacheStore` |

## Steps

1. **Client sends image request**: Client sends `GET /v1/groupon/deal/450x300/abc123.jpg` to `img.grouponcdn.com:80`.
   - From: Client
   - To: `continuumImageServiceNginxCacheProxy` (via VIP `image-service-vip.snc1`)
   - Protocol: HTTP

2. **Virtual Host Router matches server block**: Nginx `nginxVirtualHostRouter` matches the request against the server block for `img.grouponcdn.com` (or `origin-img.grouponcdn.com` / `image-service-vip.snc1`).
   - From: `nginxVirtualHostRouter`
   - To: `nginxBackendProxy` (location `/`)
   - Protocol: Internal Nginx routing

3. **Proxy Cache Engine checks cache**: `nginxProxyCacheEngine` computes cache key as `img.grouponcdn.com/v1/groupon/deal/450x300/abc123.jpg` and checks `/var/nginx_proxy_cache`.
   - From: `nginxProxyCacheEngine`
   - To: `continuumImageServiceProxyCacheStore` (filesystem)
   - Protocol: Filesystem I/O

4. **Cache hit — entry found**: The cache entry is valid (not expired, within 30-day inactive window). `$upstream_cache_status` is set to `HIT`.
   - From: `continuumImageServiceProxyCacheStore`
   - To: `nginxProxyCacheEngine`
   - Protocol: Filesystem I/O

5. **Nginx returns cached image**: Nginx streams the cached image bytes back to the client. Access log records `upstream_cache_status=HIT`.
   - From: `continuumImageServiceNginxCacheProxy`
   - To: Client
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cache entry expired | Nginx treats as cache miss; proceeds to proxy upstream | Transparent to client; request served fresh |
| Cache entry corrupted | Nginx treats as cache miss | Fresh request served from backend |
| Proxy cache disk unavailable | Nginx bypasses cache; all requests forwarded to backend | Increased backend load; no client-visible error if backend is healthy |

## Sequence Diagram

```
Client -> nginxVirtualHostRouter: GET /v1/groupon/deal/450x300/abc123.jpg
nginxVirtualHostRouter -> nginxProxyCacheEngine: Route to location /
nginxProxyCacheEngine -> ProxyCacheStore: Lookup key "img.grouponcdn.com/v1/groupon/deal/450x300/abc123.jpg"
ProxyCacheStore --> nginxProxyCacheEngine: Cache HIT — return cached bytes
nginxProxyCacheEngine --> Client: HTTP 200 (image/jpeg), X-Upstream-Cache-Status: HIT
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [Image Request Cache Miss](image-request-cache-miss.md)
