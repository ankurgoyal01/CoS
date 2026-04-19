---
service: "contract_service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

Contract Service has a minimal integration footprint. It owns its MySQL database via Groupon's DaaS platform, emits metrics to the Wavefront/Telegraf metrics stack, and is consumed by two internal Groupon services. There are no third-party external SaaS integrations. All inter-service communication is synchronous REST over HTTP.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| MySQL via DaaS | mysql | Primary data store for all contract and definition records | yes | `continuumContractMysql` |
| Metrics Stack (Telegraf/Wavefront) | UDP/Telegraf | Emits request count and latency metrics for monitoring dashboards | no | `metricsStack` |

### MySQL via DaaS Detail

- **Protocol**: MySQL wire protocol via `mysql2` gem and ActiveRecord
- **Base URL / SDK**: `cicero-rw-na-production-db.gds.prod.gcp.groupondev.com` (production), `cicero-rw-na-staging-db.gds.stable.gcp.groupondev.com` (staging) — from `.meta/deployment/cloud/components/app/production-us-central1.yml` and `staging-us-central1.yml`
- **Auth**: Database credentials injected via Kubernetes secrets (see `config/database.yml` using `RollerHostConfig`)
- **Purpose**: Stores all contract definitions, templates, contracts, version history, and signature records
- **Failure mode**: Service becomes unable to create, read, or update contracts. ActiveRecord connection retry logic (`config/initializers/unping.rb`) attempts one reconnect on lost connection before raising.
- **Circuit breaker**: No circuit breaker configured. A connection retry-once pattern is implemented via `execute_with_active_retry` in the `ActiveRetryConnection` module.

### Metrics Stack (Telegraf/Wavefront) Detail

- **Protocol**: Telegraf metrics agent (sidecar in pod) with Wavefront as backend
- **Base URL / SDK**: Telegraf URL injected via `TELEGRAF_URL` environment variable at pod start
- **Auth**: No auth documented; agent-level configuration
- **Purpose**: Emits service performance metrics visible in dashboards at `https://groupon.wavefront.com/dashboard/contract_service` and `https://groupon.wavefront.com/dashboard/cicero`
- **Failure mode**: Metrics stop being recorded; service continues to function normally
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS (Database as a Service) | MySQL | Managed MySQL hosting for the contract database | `continuumContractMysql` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Merchant Self-Service Engine (`continuumMerchantSelfService`) | REST / HTTP | Uploads contract definitions, creates contracts, retrieves signed contracts during deal workflows |
| CLO Campaign service | REST / HTTP | Retrieves contract records (referenced in RUNBOOK.md as a dependent service) |

> Upstream consumers are tracked in the central architecture model at `continuumMerchantSelfService -> continuumContractService`.

## Dependency Health

- **MySQL**: The service implements a single-retry connection strategy on `MySQL server has gone away` and `Lost connection` errors (see `config/initializers/unping.rb`). Connection pool settings: default pool size 5, `wait_timeout` 10ms, `connect_timeout` 50ms, `read_timeout` 1000ms, `write_timeout` 1000ms.
- **Metrics stack**: Best-effort fire-and-forget; no health check or fallback.
- Overall: No service mesh circuit breaker or retry middleware is visible in the application code. Hybrid Boundary (Envoy sidecar) handles mTLS and traffic interception at the pod level in Kubernetes.
