---
service: "web-config"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [ssh, http-proxy]
auth_mechanisms: [tls, basic-auth]
---

# API Surface

## Overview

web-config is a configuration generation and deployment tool, not a runtime HTTP service. It does not expose a REST or gRPC API. Its "surface" consists of:

1. **Fabric CLI tasks** invoked by operators to generate and deploy nginx config.
2. **nginx endpoints** defined in the generated configuration that the deployed nginx instance serves.

The generated nginx configuration defines the live HTTP endpoints handled by the routing tier.

## Endpoints

### nginx Operational Endpoints (generated config)

These endpoints are present in every generated nginx environment config and are served by the deployed nginx process after web-config delivers its artifacts.

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Load-balancer health probe (port 9999 dedicated listener + default server) | Internal networks only (10.0.0.0/8, 100.0.0.0/8, 172.16.0.0/12) |
| GET | `/heartbeat` | Alias for `/grpn/healthcheck` on port 80/443 | Internal networks only |
| GET | `/heartbeat.txt` | Alias for `/grpn/healthcheck` on port 80/443 | Internal networks only |
| GET | `/nginx_status` | nginx stub-status metrics endpoint | Internal networks only |
| GET | `/akamai/akamai-sureroute-test-object.htm` | Akamai SureRoute health check object | None (static file) |
| GET/POST | `/analytic` and `/analytic/*` | Analytics beacon endpoint; returns HTTP 204 with no-cache headers | None |
| GET/POST | `/*` | Catch-all: proxies to `grout_proxy` (127.0.0.1:9000) | Per virtual-host security.conf rules |

### Virtual-Host Specific Locations (example: groupon.com / groupon.de)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| ANY | `/merchant/center/api/v2` | Merchant Center API v2 proxy (client_max_body_size 25m) | Per virtual-host |
| ANY | `/merchant/center/echo/api` | Merchant Center Echo API proxy (client_max_body_size 11m) | Per virtual-host |
| ANY | `/merchant/center/draft/api` | Merchant Center Draft API proxy (client_max_body_size 11m) | Per virtual-host |
| ANY | `/merchant/center/reservations/mbt-api.*` | Merchant Center Reservations MBT API proxy | Per virtual-host |
| ANY | `/goods-gateway/proxy` | Goods Gateway proxy endpoint | Per virtual-host |
| ANY | `/(biz|local|goods|travel)/*` | SEO-optimised paths; proxy_intercept_errors off (410 pass-through) | Per virtual-host |
| ANY | `/merchant/center/(draft|deal|reservations|...)` | Merchant Center portal API group (client_max_body_size 25m) | Per virtual-host |
| GET | `/merchant/center(.*)` | Redirect to `merchant.groupon.{tld}` (HTTP 301) | None |
| GET | `/merchant/admin(.*)` | Redirect to `merchant.groupon.{tld}` (HTTP 301) | None |
| GET | `/apple-app-site-association` | Apple App Site Association file (proxied, no access control) | None |

## Request/Response Patterns

### Common headers

The proxy configuration (`includes/proxy.conf`) injects the following headers on every upstream request:

- `Host`: `$real_host`
- `HTTPS`: `$https_header` (set to `on` when `X-Forwarded-Proto: https`)
- `X-Forwarded-Host`: `$real_host`
- `X-Forwarded-Proto`: `$real_scheme`
- `X-Forwarded-For`: `$proxy_add_x_forwarded_for`
- `True-Client-IP`: `$true_client_ip`
- `X-Brand`: `$brand`

Real client IP is resolved from the `True-Client-IP` header (`set_real_ip_from 0.0.0.0/0`).

### Error format

nginx serves locale-specific, pre-rendered static HTML error pages from `/error/{code}.html` for 4xx and 5xx responses. Error pages are generated at build time from Mustache templates with translation YAML data and stored under `root/{country}/error/`.

### Pagination

> Not applicable. This service generates static config artifacts and does not paginate responses.

## Rate Limits

> No rate limiting configured at the nginx config level. Rate limiting, if any, is applied upstream by Akamai.

## Versioning

The generated nginx configuration is versioned by Git SHA and date stamp (`YYYY.MM.DD_HHmm_<sha>`). The `REVISION` file on each routing host records the deployed version. No HTTP API versioning strategy applies.

## OpenAPI / Schema References

> No evidence found in codebase. The service generates nginx config files, not an HTTP API. No OpenAPI spec, proto files, or GraphQL schema exist.
