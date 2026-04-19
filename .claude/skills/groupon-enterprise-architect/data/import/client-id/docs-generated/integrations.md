---
service: "client-id"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

Client ID Service has one external integration (Jira REST API for self-service ticket creation) and two internal Groupon service consumers that pull from it (API Proxy and API Lazlo). All outbound calls are synchronous HTTP. There is no message-bus integration. The Jira integration is annotated as a stub in the federated architecture model because Jira is not currently included in the federated DSL.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jira REST API | REST (HTTPS/JSON) | Creates Jira issues for self-service client registration requests | No | `jiraServiceApi` (stub) |

### Jira REST API Detail

- **Protocol**: HTTPS / JSON (`application/json`)
- **Base URL**: Configured via `jiraServiceClientHost` in YAML config; production value `http://jira.production.service/`; API path suffix `rest/api/2/issue`
- **Auth**: Internal Groupon SSO headers — `X-GRPN-SamAccountName`, `X-Remote-User`, `X-OpenID-Extras` sent on each request
- **Purpose**: When a developer uses the `/self-service/newClientToken` flow to request a new client + token, the Jira Gateway component creates a Jira issue to track the support request
- **Failure mode**: `JiraRestClient` throws a `WebApplicationException` on HTTP 400 (bad request) or any non-success response; callers receive an error response. The self-service flow fails if Jira is unreachable
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MySQL primary | JDBI / MySQL | Read/write for all domain entities | `continuumClientIdDatabase` |
| MySQL read replica | JDBI / MySQL | High-volume reads for sync and search | `continuumClientIdReadReplica` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| API Proxy | REST (HTTPS / JSON) | Periodically syncs client and token data via `/v3/services/{serviceName}` using `updatedAfter` timestamp for incremental updates; drives runtime request authentication and rate limit enforcement |
| API Lazlo | REST (HTTPS / JSON) | Queries client and token information via `/v2/search` and related endpoints |

> Upstream consumers are also tracked in the central architecture model under the Continuum platform.

## Dependency Health

- **MySQL primary/replica**: Monitored via Hikari connection pool metrics (`connectionTimeout: 40000ms`, `leakDetectionThreshold: 10000ms`). Connection pool status is visible in Dropwizard admin metrics on port `9001`.
- **Jira REST API**: No circuit breaker or retry logic detected. The `httpClient` has `connectTimeout: 2s`, `readTimeout: 1s`, `writeTimeout: 2s` in production config; failures propagate as HTTP errors to the caller.
- **API Proxy sync timing**: API Proxy includes the `updated_at` of the most recent token in its sync request. If the GDS-managed DB sync between environments creates timestamp drift, the API Proxy sync window may skip tokens — see the Runbook for the resolution procedure.
