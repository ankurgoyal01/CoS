---
service: "gcp-prometheus"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [http, grpc]
auth_mechanisms: [okta, tls-cert]
---

# API Surface

## Overview

`gcp-prometheus` exposes several internal HTTP and gRPC interfaces across its Thanos and Grafana components. These are not public-facing REST APIs; they serve as integration points between platform components (Prometheus, Thanos, Grafana) and for health/readiness probing by Kubernetes. External users interact via the Grafana UI. The Thanos Query Frontend HTTP endpoint is the primary external-facing query interface (consumed by Grafana datasource).

## Endpoints

### Thanos Receive

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/v1/receive` (port 19291) | Accepts Prometheus remote-write payloads | Internal / TLS |
| GET | `/-/healthy` (port 10902) | Liveness probe | None |
| GET | `/-/ready` (port 10902) | Readiness probe | None |
| — | gRPC port 10901 | Store API — serves recent blocks to Thanos Query | Internal gRPC |

### Thanos Query

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/-/healthy` (port 10902) | Liveness probe | None |
| GET | `/-/ready` (port 10902) | Readiness probe | None |
| GET/POST | `/api/v1/query`, `/api/v1/query_range` (port 10902) | PromQL query API | Internal |
| — | gRPC port 10901 | Store API fanout to upstream stores | Internal gRPC |

### Thanos Query Frontend

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/api/v1/query`, `/api/v1/query_range` (port 9090) | Cached and split PromQL queries forwarded to Thanos Query | Internal |
| GET | `/-/ready` (port 9090) | Readiness probe | None |
| GET | `/-/healthy` (port 9090) | Liveness probe | None |

### Thanos Store Gateway

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/-/healthy` (port 10902) | Liveness probe | None |
| GET | `/-/ready` (port 10902) | Readiness probe | None |
| — | gRPC port 10901 (headless service `thanos-store-gateway`) | Serves historical blocks to Thanos Query | Internal gRPC |

### Thanos Compact

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/-/healthy` (port 10902) | Liveness probe | None |
| GET | `/-/ready` (port 10902) | Readiness probe | None |

### Grafana

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/health` (port 3000, HTTPS) | Liveness and readiness probe | None |
| GET/POST | `/login/okta` | Okta OAuth2 redirect callback | Okta |
| GET | `/` (port 3000) | Dashboard UI | Okta SSO |

### Prometheus Federation (Conveyor)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/federate` | Federation endpoint scraped by `prometheusConveyor` | Internal |

## Request/Response Patterns

### Common headers

- Thanos gRPC endpoints use standard gRPC framing over TCP on port 10901.
- Grafana uses HTTPS with TLS certificates sourced from the `grouponcerts` secret (`/var/groupon/tls.crt`, `/var/groupon/tls.key`).

### Error format

> No evidence found in codebase. Error formats follow standard Thanos/Prometheus HTTP API conventions (JSON `{"status":"error","errorType":"...","error":"..."}`).

### Pagination

> No rate limits are configured for internal Thanos endpoints. Thanos Query enforces `--query.timeout=5m` for all queries.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Thanos Store gRPC | 50,000,000 series samples per request | Per request (`--store.grpc.series-sample-limit`) |
| Thanos Query | 5 minutes query timeout | Per query (`--query.timeout=5m`) |

## Versioning

No API versioning strategy. Component versions are pinned in Kubernetes manifests and advanced via Helm chart updates.

## OpenAPI / Schema References

> No evidence found in codebase. Thanos exposes OpenAPI-compatible Prometheus HTTP API. Refer to the [Thanos documentation](https://thanos.io/tip/components/query.md/) for schema details.
