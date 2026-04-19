---
service: "gcp-prometheus"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 2
---

# Integrations

## Overview

`gcp-prometheus` integrates with four external systems (GCS, Okta, Kafka, Jaeger) and two internal Groupon platform services (Kubernetes API targets and secrets registry). All metric data paths are internal to the GKE cluster over HTTP or gRPC. External integrations are primarily for authentication (Okta), long-term storage (GCS), log shipping (Kafka), and tracing (Jaeger).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCS (Google Cloud Storage) | GCS API (HTTPS) | Long-term Thanos block storage | yes | `thanosObjectStorage` |
| Okta | OAuth2 (HTTPS) | Grafana user authentication and SSO | yes | — |
| Kafka | TCP / TLS | Filebeat log shipping from all pod sidecars | no | — |
| Jaeger | UDP / HTTP | Distributed tracing for Thanos Receive and Compact | no | — |

### GCS Detail

- **Protocol**: GCS API (HTTPS)
- **Base URL / SDK**: Configured via `OBJSTORE_CONFIG` env var (secret key `thanos.yaml` from `thanos-objectstorage` Kubernetes secret)
- **Auth**: GCP service account (credentials embedded in secret)
- **Purpose**: Stores all Prometheus/Thanos metric blocks for long-term retention. Thanos Receive writes new blocks; Thanos Store Gateway reads them; Thanos Compact reads and rewrites compacted blocks.
- **Failure mode**: If GCS is unavailable, Thanos Receive continues to accept remote-write and buffer to local TSDB. Store Gateway and Compact become non-functional. Recent metric data remains queryable via Thanos Receive Store API.
- **Circuit breaker**: No evidence found in codebase.

### Okta Detail

- **Protocol**: OAuth2 (HTTPS)
- **Base URL / SDK**: Redirect URL `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/login/okta`
- **Auth**: OAuth2 client credentials (`GF_AUTH_OKTA_CLIENT_ID`, `GF_AUTH_OKTA_CLIENT_SECRET` from `grafana` secret)
- **Purpose**: Authenticates Groupon engineers accessing Grafana dashboards.
- **Failure mode**: Grafana login becomes unavailable; existing sessions may persist depending on session config.
- **Circuit breaker**: No evidence found in codebase.

### Kafka Detail

- **Protocol**: Kafka protocol over TCP/TLS (port 9093)
- **Base URL / SDK**: `kafka-logging-kafka-bootstrap.kafka-production.svc.cluster.local:9093` (production Grafana). Staging: MSK (`filebeatMsk: true`).
- **Auth**: TLS mutual authentication; certificates from `telegraf--gateway--default-kafka-secret`
- **Purpose**: Filebeat sidecars on all Thanos and Grafana pods ship container logs to Kafka topic prefix `logging_production_` for centralized log aggregation.
- **Failure mode**: Log shipping stops. Application metrics collection is unaffected.
- **Circuit breaker**: No evidence found in codebase.

### Jaeger Detail

- **Protocol**: Jaeger tracing (UDP/HTTP)
- **Base URL / SDK**: Configured via `--tracing.config` argument with `type: JAEGER` on Thanos Receive, Compact, and Store components
- **Auth**: None evidenced
- **Purpose**: Rate-limited distributed tracing (2 samples/s, `ratelimiting` sampler) for Thanos component operations.
- **Failure mode**: Tracing data loss only; metrics collection continues normally.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Kubernetes targets (`kubernetesTargets`) | HTTP | Prometheus scrapes metrics from cluster workloads and node exporters | `kubernetesTargets` (stub) |
| Groupon Certs (`grouponcerts`) | Kubernetes Secret | TLS certificate bundle mounted by Grafana and Thanos components | — |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Grafana Dashboard UI | HTTP | Engineers query metrics via Thanos Query Frontend |
| Internal alerting systems | HTTP / gRPC | PromQL-based alert evaluation against Thanos Query API |
| PagerDuty (via alertmanager) | HTTPS | Alert escalation to `metrics-platform-team@groupon.pagerduty.com` |

> Upstream consumers beyond Grafana are tracked in the central architecture model.

## Dependency Health

- Thanos components expose `/-/healthy` and `/-/ready` HTTP endpoints used by Kubernetes liveness and readiness probes.
- Grafana health check: `GET /api/health` on port 3000 (HTTPS).
- No explicit retry or circuit breaker configuration is evidenced in the repository. Kubernetes restart policies (`restartPolicy: Always`) handle pod-level recovery.
- Thanos Querier uses `--query.partial-response` to tolerate individual store failures and return partial results rather than failing entirely.
