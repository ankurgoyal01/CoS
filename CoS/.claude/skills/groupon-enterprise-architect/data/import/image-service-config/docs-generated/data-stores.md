---
service: "image-service-config"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumImageServiceProxyCacheStore"
    type: "filesystem-cache"
    purpose: "Nginx disk-backed proxy cache for image responses"
  - id: "imageServiceS3Bucket"
    type: "s3"
    purpose: "Origin storage for original and transformed image assets"
---

# Data Stores

## Overview

The Image Service uses two storage layers: a local Nginx filesystem proxy cache on each cache node that serves cached image responses without hitting the backend, and AWS S3 as the authoritative origin store for image assets. No relational database, Redis, or application-owned database is used.

## Stores

### Nginx Proxy Cache Store (`continuumImageServiceProxyCacheStore`)

| Property | Value |
|----------|-------|
| Type | Filesystem cache (Nginx `proxy_cache`) |
| Architecture ref | `continuumImageServiceProxyCacheStore` |
| Purpose | Caches image HTTP responses keyed by `$host$uri` to avoid repeated backend or S3 round-trips |
| Ownership | owned |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Cache entry (file on disk) | Stores a cached HTTP response for an image at a specific URL path | Cache key: `$host$uri` (e.g., `img.grouponcdn.com/v1/grupon/deal/450x300/abc.jpg`) |

#### Access Patterns

- **Read**: Nginx checks the proxy cache on every incoming request using the `$host$uri` cache key. Cache hits are served directly from `/var/nginx_proxy_cache` without contacting the backend.
- **Write**: Nginx writes a cache entry after a successful upstream response. `proxy_cache_valid 404 1m` means 404 responses are cached for 1 minute; successful responses use nginx default (controlled by upstream Cache-Control headers).
- **Indexes**: Two-level directory hierarchy (`levels=2:2`) under `/var/nginx_proxy_cache`. Cache zone `proxycache` allocated with 1024 MB of keys-zone memory.

### AWS S3 Image Bucket

| Property | Value |
|----------|-------|
| Type | S3 |
| Architecture ref | External (stub: `unknownExternalContainer_imageServiceBucket_8c9e2a41`) |
| Purpose | Authoritative origin storage for all image assets |
| Ownership | external (AWS-managed) |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `image-service` bucket (us-east-1) | Primary S3 bucket for all image objects | Object key (image path) |
| `image-service-west` bucket | Failover/backup S3 bucket in us-west | Object key (image path) |

#### Access Patterns

- **Read**: Nginx S3-proxy route (`nginxS3ProxyRoute`) forwards requests to `image-service.s3.amazonaws.com` with `Host` header override. Falls back to `image-service-west.s3.amazonaws.com` if primary is unavailable (defined in `s3-proxy.conf` as a backup upstream).
- **Write**: Image uploads are handled by the `imageservice.py` application (separate repository) using the AWS S3 SDK. The S3 access key ID (`<REDACTED>`) and bucket name (`image-service`) are configured in `config.yml`.
- **Indexes**: Not applicable.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `proxycache` | Filesystem (Nginx proxy_cache) | Disk-backed HTTP response cache for image requests | Inactive entries purged after 30 days; 404s cached for 1 minute |

## Data Flows

1. Client request arrives at Nginx cache proxy.
2. Nginx checks `proxycache` (filesystem at `/var/nginx_proxy_cache`) using cache key `$host$uri`.
3. On cache hit: Nginx returns the cached response immediately.
4. On cache miss: Nginx forwards to Python app backend via `upstream backend`.
5. Python app fetches the original image from S3 (`image-service` bucket) via the S3-proxy route or directly, transforms it, and returns the response.
6. Nginx writes the response to `proxycache` for subsequent requests.
7. If primary S3 bucket (`image-service.s3.amazonaws.com`) is unavailable, S3-proxy upstream falls back to `image-service-west.s3.amazonaws.com` (configured as `backup` in `s3-proxy.conf`).
