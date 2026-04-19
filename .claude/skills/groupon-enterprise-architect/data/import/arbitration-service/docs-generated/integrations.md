---
service: "arbitration-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

The Arbitration Service has five downstream integration targets: two external SaaS systems (Optimizely for experimentation, Jira for approval workflows), one internal operational notification service, one internal metrics pipeline, and three owned data stores. It is consumed by marketing delivery clients which call its HTTP API synchronously during campaign send workflows.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Optimizely | HTTPS / Go SDK | Fetch experiment definitions and variant context for algorithm configuration | yes | `optimizelyService` |
| Jira | HTTPS | Create and update approval workflow tickets for delivery rule changes | no | `continuumJiraService` |
| Notification Email Service | SMTP/HTTP | Send operational notification emails for alerts and workflow events | no | `notificationEmailService` |

### Optimizely Detail

- **Protocol**: HTTPS via `github.com/optimizely/go-sdk`
- **Base URL / SDK**: Configured via `OPTIMIZELY_SDK_KEY` environment variable; SDK manages CDN-based datafile fetching
- **Auth**: SDK key (`OPTIMIZELY_SDK_KEY`)
- **Purpose**: Provides experiment definitions and feature flag variants used by `experimentationAdapter` to influence arbitration algorithm behavior and A/B test campaign selection logic
- **Failure mode**: Service falls back to in-memory cached config from last successful fetch; startup preload ensures a baseline config is always available
- **Circuit breaker**: > No evidence found in codebase

### Jira Detail

- **Protocol**: HTTPS REST API
- **Base URL / SDK**: Configured via `JIRA_URL` environment variable
- **Auth**: Basic auth via `JIRA_USERNAME` and `JIRA_TOKEN`
- **Purpose**: When delivery rules are created or updated via the admin API, the `deliveryRuleManager` component creates or updates a Jira ticket to track the approval workflow for the pending configuration change
- **Failure mode**: Delivery rule change is persisted to PostgreSQL; Jira ticket creation failure is a non-blocking operational notification concern
- **Circuit breaker**: > No evidence found in codebase

### Notification Email Service Detail

- **Protocol**: SMTP/HTTP
- **Base URL / SDK**: > No evidence found in codebase for specific endpoint configuration
- **Auth**: > No evidence found in codebase
- **Purpose**: Sends operational notification emails for workflow events and alerts via `notificationAdapterArbSer`
- **Failure mode**: Notification failures are non-blocking; core arbitration is unaffected
- **Circuit breaker**: > No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `absPostgres` | PostgreSQL | Campaign metadata, delivery rules, user attributes | `absPostgres` |
| `absCassandra` | CQL | Send history, frequency caps, high-volume operational records | `absCassandra` |
| `absRedis` | Redis | Decisioning counters, cached campaign data, TTL rate limit keys | `absRedis` |
| `telegrafMetrics` | StatsD/UDP | Request counters and latency timers | `telegrafMetrics` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `marketingDeliveryClients` | REST/HTTPS | Invokes `/best-for`, `/arbitrate`, and `/revoke` APIs during campaign send workflows |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- `absRedis` is on the hot decisioning path; degradation directly impacts arbitration throughput and latency
- `absCassandra` is queried on every best-for and arbitration request; failures prevent send record persistence and cap enforcement
- `absPostgres` failures impact delivery rule reads; in-memory cache mitigates impact for already-loaded rules
- `optimizelyService` failures fall back to cached experiment config; does not block arbitration
- `continuumJiraService` and `notificationEmailService` failures are non-blocking operational concerns

> Specific retry policies, timeouts, and circuit breaker configurations are not discoverable from the service inventory. Operational procedures to be defined by service owner.
