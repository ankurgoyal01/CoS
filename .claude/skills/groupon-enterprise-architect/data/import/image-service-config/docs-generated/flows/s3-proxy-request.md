---
service: "image-service-config"
title: "S3 Proxy Request"
generated: "2026-03-03"
type: flow
flow_name: "s3-proxy-request"
flow_type: synchronous
trigger: "HTTP request sent to the S3-proxy server name (image-service-s3-proxy-vip.snc1 or image-service.s3.amazonaws.com)"
participants:
  - "Client or image-service app runtime"
  - "continuumImageServiceNginxCacheProxy"
  - "AWS S3 (image-service bucket)"
architecture_ref: "dynamic-imageServiceConfig"
---

# S3 Proxy Request

## Summary

The S3-proxy server block in Nginx acts as a transparent HTTP tunnel to the AWS S3 `image-service` bucket. When a client or internal service sends a request to the VIP `image-service-s3-proxy-vip.snc1` (or the bare S3 hostname `image-service.s3.amazonaws.com`), Nginx matches it to the S3-proxy server block and forwards it to the `s3proxy` upstream with the `Host: image-service.s3.amazonaws.com` header set. A passive backup upstream (`image-service-west.s3.amazonaws.com`) provides failover if the primary bucket is unavailable.

## Trigger

- **Type**: api-call
- **Source**: Python `imageResizeEngine` (within `continuumImageServiceAppRuntime`) or other internal services using the S3-proxy VIP
- **Frequency**: Per-request on cache miss; every original image fetch

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Image Resize Engine | Initiates S3 image fetch via S3-proxy VIP | `imageResizeEngine` |
| S3 Proxy Route (Nginx server block) | Receives requests on S3-proxy server names; forwards to `upstream s3proxy` | `nginxS3ProxyRoute` |
| AWS S3 Primary (`image-service.s3.amazonaws.com`) | Authoritative origin for image objects | External (AWS) |
| AWS S3 Backup (`image-service-west.s3.amazonaws.com`) | Passive failover bucket in us-west | External (AWS) |

## Steps

1. **App runtime requests original image**: `imageResizeEngine` sends an HTTP GET to `image-service-s3-proxy-vip.snc1` (resolved to the Nginx S3-proxy server) for the original image path.
   - From: `imageResizeEngine`
   - To: `continuumImageServiceNginxCacheProxy` (S3-proxy server block listener on port 80)
   - Protocol: HTTP

2. **Virtual Host Router matches S3-proxy server block**: Nginx `nginxVirtualHostRouter` matches the `Host` header against `image-service.s3.amazonaws.com` or `image-service-s3-proxy-vip.snc1` and routes to the S3-proxy server block.
   - From: `nginxVirtualHostRouter`
   - To: `nginxS3ProxyRoute`
   - Protocol: Internal Nginx routing

3. **S3 Proxy Route sets Host header and forwards**: `nginxS3ProxyRoute` applies `proxy_set_header Host image-service.s3.amazonaws.com` and issues `proxy_pass http://s3proxy`.
   - From: `nginxS3ProxyRoute`
   - To: `upstream s3proxy` (primary: `image-service.s3.amazonaws.com`)
   - Protocol: HTTP

4. **Primary S3 bucket responds**: AWS S3 us-east returns the original image object bytes.
   - From: AWS S3 `image-service` bucket
   - To: `nginxS3ProxyRoute`
   - Protocol: HTTP

5. **Nginx returns image to requester**: `nginxS3ProxyRoute` streams the S3 response back to the requesting app node.
   - From: `continuumImageServiceNginxCacheProxy`
   - To: `imageResizeEngine`
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Primary S3 (`image-service.s3.amazonaws.com`) unavailable | Nginx passive failover to `image-service-west.s3.amazonaws.com` (backup server in `upstream s3proxy`) | Transparent; request served from backup with potential latency increase |
| Both S3 endpoints unavailable | Nginx upstream fails; returns 502 to requesting app | `imageResizeEngine` receives error; original image unavailable; app returns 5xx to client |
| S3 returns 403 (access denied) | S3 error passed through Nginx proxy | App receives 403; invalid S3 credentials (config.yml `s3.secret_access_key`) should be investigated |
| S3 returns 404 (object not found) | S3 404 response passed through | App receives 404; original image does not exist in bucket |

## Sequence Diagram

```
imageResizeEngine -> nginxS3ProxyRoute: GET /original-image-path (Host: image-service-s3-proxy-vip.snc1)
nginxS3ProxyRoute -> upstream_s3proxy_primary: GET /original-image-path (Host: image-service.s3.amazonaws.com)
upstream_s3proxy_primary -> S3_image-service_east: GET /original-image-path
S3_image-service_east --> upstream_s3proxy_primary: HTTP 200 (image bytes)
upstream_s3proxy_primary --> nginxS3ProxyRoute: HTTP 200 (image bytes)
nginxS3ProxyRoute --> imageResizeEngine: HTTP 200 (image bytes)

alt Primary S3 unavailable
  nginxS3ProxyRoute -> upstream_s3proxy_backup: GET /original-image-path (Host: image-service-west.s3.amazonaws.com)
  upstream_s3proxy_backup -> S3_image-service_west: GET /original-image-path
  S3_image-service_west --> nginxS3ProxyRoute: HTTP 200 (image bytes)
  nginxS3ProxyRoute --> imageResizeEngine: HTTP 200 (image bytes)
end
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [Image Request Cache Miss](image-request-cache-miss.md)
- S3 upstream config: `s3-proxy.conf`
