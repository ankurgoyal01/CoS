---
service: "image-service-config"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

The Image Service has two external dependencies (AWS S3 primary and failover buckets) and one internal Groupon backend dependency (the image-service app VIP). Configuration for all integrations is distributed via Capistrano and maintained in `config.yml` and the nginx upstream conf files.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS S3 (`image-service.s3.amazonaws.com`) | HTTP (proxied) | Primary origin store for image assets | yes | `unknownExternalContainer_imageServiceBucket_8c9e2a41` (stub) |
| AWS S3 (`image-service-west.s3.amazonaws.com`) | HTTP (proxied) | Failover/backup origin store for image assets | yes | `unknownExternalContainer_imageServiceBucket_8c9e2a41` (stub) |

### AWS S3 (Primary — `image-service.s3.amazonaws.com`) Detail

- **Protocol**: HTTP (Nginx proxy_pass with `Host` header override)
- **Base URL / SDK**: `http://image-service.s3.amazonaws.com` (configured in `s3-proxy.conf` and `nginx.conf`)
- **Auth**: AWS IAM credentials — access key `<REDACTED>`, secret key defined in `config.yml` under `s3.secret_access_key` (used by the app runtime, not by Nginx directly)
- **Purpose**: Stores all original and processed image files. The Nginx S3-proxy route (`nginxS3ProxyRoute`) tunnels requests through the VIP `image-service-s3-proxy-vip.snc1` which then forwards to the S3 endpoint.
- **Failure mode**: Falls back to `image-service-west.s3.amazonaws.com` (us-west backup bucket), defined as a `backup` server in `s3-proxy.conf`
- **Circuit breaker**: No — Nginx upstream backup server handles failover passively

### AWS S3 (Failover — `image-service-west.s3.amazonaws.com`) Detail

- **Protocol**: HTTP (Nginx proxy_pass via `upstream s3proxy` backup server entry)
- **Base URL / SDK**: `http://image-service-west.s3.amazonaws.com` (defined in `s3-proxy.conf`)
- **Auth**: Same AWS IAM credentials as primary bucket
- **Purpose**: Backup S3 bucket in AWS us-west region; activated automatically when primary S3 east goes offline
- **Failure mode**: If both primary and backup S3 are unavailable, image requests will fail with upstream errors
- **Circuit breaker**: No — standard Nginx passive upstream failover

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Image Service App (`global-image-service-app-vip:80`) | HTTP | Image transformation and retrieval processing | `continuumImageServiceAppRuntime` |

### Image Service App Detail

- **Protocol**: HTTP — Nginx `proxy_pass http://backend` where `upstream backend` points to `global-image-service-app-vip:80` in production
- **Internal VIP**: `global-image-service-app-vip:80` (production); `image-service-app-vip-staging:80` (staging); `ims-demo1-uat.snc1:39170–39171` (UAT)
- **App node ports**: Each app node runs 12 Python worker processes on ports `8000`–`8011` (visible in `upstream-app1-disabled.conf` through `upstream-app4-disabled.conf`)
- **Purpose**: Receives proxied image HTTP requests from Nginx, validates client API key and size policy, performs image transformation, and returns the image response
- **Failure mode**: If all upstream backend servers are unavailable, Nginx returns a gateway error to the client; cache hits are unaffected

## Consumed By

Upstream consumers are identified by named API client entries in `config.yml`. Each client has a unique `api_key` and an `allowed_sizes` whitelist:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `deal` (api_key: `1d0d2402...`) | HTTP | Deal image delivery |
| `merchant` (api_key: `1d0d2402...`) | HTTP | Merchant image delivery |
| `user` (api_key: `1d0d2402...`) | HTTP | User profile image delivery |
| `sparta` (api_key: `4397c6c7...`) | HTTP | Native app image delivery |
| `mpp` (api_key: `0e553151...`) | HTTP | Mobile push/promotions image delivery |
| `coupons` (api_key: `b9c1f71e...`) | HTTP | Coupon image delivery |
| `asset` (api_key: `1d0d2402...`) | HTTP | General asset delivery (original sizes only) |
| `publisher` (api_key: `683ca8dc...`) | HTTP | Publisher image delivery |
| `getaways` (api_key: `8a8be2a5...`) | HTTP | Getaways product image delivery |
| `travelshop` (api_key: `70dd3e15...`) | HTTP | Travel shop image delivery |
| `mainstreet` (api_key: `3490fdde...`) | HTTP | Mainstreet image delivery |
| `iam` / `iam_raw` (api_key: `65925cd7...`) | HTTP | IAM image delivery |
| `item_master` (api_key: `fba0b928...`) | HTTP | Item master image delivery |
| `msse` (api_key: `3c328352...`) | HTTP | MSSE image delivery |
| `seocmsimages` (api_key: `929448ff...`) | HTTP | SEO CMS image delivery |
| `gpn` (api_key: `da239ed8...`) | HTTP | GPN image delivery |
| _+16 additional named clients_ | HTTP | Various Groupon internal services |

> Upstream consumers are also tracked in the central architecture model.

## Dependency Health

- **S3 failover**: Nginx passive failover — if `image-service.s3.amazonaws.com` does not respond, traffic automatically shifts to `image-service-west.s3.amazonaws.com` (marked as `backup` in `s3-proxy.conf`).
- **Backend app health**: Load balancer health is controlled by `/heartbeat.txt` — cache nodes are added or removed from the LB pool by creating or deleting `/var/groupon/nginx/heartbeat/heartbeat.txt` (Capistrano tasks: `add_cache_to_lb`, `remove_cache_from_lb`).
- **Nginx status**: The `/nginx_status` endpoint (stub_status) on `127.0.0.1:80` exposes active connections and request counts for monitoring.
