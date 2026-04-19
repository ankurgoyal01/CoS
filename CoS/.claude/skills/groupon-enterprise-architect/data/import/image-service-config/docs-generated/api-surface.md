---
service: "image-service-config"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The Image Service exposes an HTTP interface via the Nginx cache proxy. Consumers submit image requests to the CDN hostname `img.grouponcdn.com` (or internal VIP `image-service-vip.snc1`). The Nginx layer caches responses on disk and forwards cache misses to the Python backend app. The backend validates the requesting client's API key and enforces per-client allowed image-size whitelists defined in `config.yml` before serving or transforming the image. There is no REST framework with versioned route definitions visible in this repo — the app logic resides in the separate `imageservice.py` repository.

## Endpoints

### Nginx-level endpoints (from `nginx.conf`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Proxy all image requests to backend upstream | None (auth enforced by backend app) |
| GET | `/robots.txt` | Returns HTTP 200 with empty body | None |
| GET | `/heartbeat.txt` | Load balancer health check, returns HTTP 200 | None |
| GET | `/nginx_status` | Nginx stub status (metrics), access-log disabled | Internal only |
| GET | `/grpn` | Blocked path — returns HTTP 403 deny | None |
| GET | `/upload_form` (HTTPS redirect) | Redirects non-HTTPS requests for upload form to HTTPS | None |

### S3-proxy server block (from `nginx.conf`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Proxy requests to `image-service.s3.amazonaws.com` with Host header override | None (S3 bucket policy) |

### Backend app (from `supervisord.conf` / `upstream-app1-disabled.conf`)

The Python `imageservice.py` process listens on ports `8000`–`8011` per app node. The Nginx upstream definition (`upstream backend`) load-balances across all ports on all active app nodes.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | (all paths) | Image transformation and retrieval requests | API key validated by Config Loader against `config.yml` |

## Request/Response Patterns

### Common headers

- `Host` — must match one of the configured server names (`img.grouponcdn.com`, `origin-img.grouponcdn.com`, `image-service-vip.snc1`) for routing to succeed
- `X-Forwarded-Proto` — evaluated by Nginx to enforce HTTPS redirect on `/upload_form`
- `X-Akamai-Waf` — logged by Nginx access log for WAF tracking

### Error format

> No evidence found in codebase — error response format is defined in the application code (`imageservice.py`) which resides in a separate repository.

### Pagination

> Not applicable — the Image Service returns individual image files, not paginated collections.

## Rate Limits

> No rate limiting configured in the Nginx or application configuration visible in this repository.

## Versioning

Config version is tracked in `config.yml` under the `version` field (current: `1.6.0`). This controls the configuration bundle version, not the HTTP API version. No URL-path or header-based API versioning is configured.

## OpenAPI / Schema References

> No evidence found in codebase — no OpenAPI spec, proto files, or GraphQL schema present in this repository. The API contract is implicitly defined by the `imageservice.py` application and the client allowed-size policies in `config.yml`.
