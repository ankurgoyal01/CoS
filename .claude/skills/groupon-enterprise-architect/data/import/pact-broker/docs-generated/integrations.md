---
service: "pact-broker"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 1
---

# Integrations

## Overview

Pact Broker has one internal dependency (its PostgreSQL database) and two external outbound integrations (GitHub Enterprise and GitHub.com) used exclusively for webhook delivery. All external calls are outbound; no external system calls back into Pact Broker except via its HTTP API.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GitHub Enterprise | HTTPS/webhook | Delivers pact lifecycle webhook callbacks to internal CI pipelines | no | `githubEnterprise` |
| GitHub.com | HTTPS/webhook | Delivers pact lifecycle webhook callbacks to public CI pipelines | no | `githubDotCom` |

### GitHub Enterprise Detail

- **Protocol**: HTTPS (outbound HTTP POST webhook)
- **Base URL / SDK**: `github.groupondev.com` — enforced by `PACT_BROKER_WEBHOOK_HOST_WHITELIST`
- **Auth**: Webhook-level credentials configured per-webhook in the Pact Broker database
- **Purpose**: Notifies Groupon's internal GitHub CI (e.g., triggering provider verification builds when a new pact is published)
- **Failure mode**: Webhook delivery failure is recorded in `triggered_webhooks` table. The broker retries internally per pact-foundation defaults. No consumer-facing impact — contract data remains stored.
- **Circuit breaker**: No evidence found in codebase. Retry behavior is managed by the upstream pact-broker application.

### GitHub.com Detail

- **Protocol**: HTTPS (outbound HTTP POST webhook)
- **Base URL / SDK**: `github.com` — enforced by `PACT_BROKER_WEBHOOK_HOST_WHITELIST`
- **Auth**: Webhook-level credentials configured per-webhook in the Pact Broker database
- **Purpose**: Notifies public GitHub CI pipelines for any services using github.com repositories
- **Failure mode**: Same as GitHub Enterprise — failure is logged, retried internally, non-blocking for API callers.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Pact Broker Postgres DB | SQL (PostgreSQL) | Sole persistent store for all broker domain data | `continuumPactBrokerPostgres` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Any Groupon consumer or provider service that publishes pacts or posts verification results via the Pact Broker HTTP API is a consumer of this service. CI/CD pipelines using `can-i-deploy` are also consumers.

## Dependency Health

- **PostgreSQL**: Liveness and readiness probes (`/diagnostic/status/heartbeat`) verify database connectivity at startup and on an ongoing 15-second interval. If the database is unreachable, the app fails its liveness probe and Kubernetes restarts the pod.
- **GitHub Enterprise / GitHub.com**: No active health check. Webhook delivery status is observable through the Pact Broker UI (`/webhooks`) and the `triggered_webhooks` database table.
