---
service: "n8n"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest, webhook, http]
auth_mechanisms: [oauth2, api-key, ssl-cert]
---

# API Surface

## Overview

n8n exposes a REST API and a webhook receiver, both routed through separate internal domains. The editor UI and REST API are accessible on the internal VPN domain (`n8n.groupondev.com` and instance variants). Webhook endpoints are routed via a separate public API domain (`n8n-api.groupondev.com` and instance variants) to allow external systems to trigger workflows without VPN access. The runner broker endpoint (port 5679) is an internal HTTP endpoint used only by task runner sidecars.

## Endpoints

### Health and Readiness

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthz` | Liveness probe — confirms process is alive | None |
| GET | `/healthz/readiness` | Readiness probe — confirms service is ready to receive traffic | None |

### n8n REST API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rest/*` | n8n built-in REST API (workflows, executions, credentials, users) | API key / session |
| POST | `/rest/oauth2-credential/callback` | OAuth2 redirect callback for credential setup | OAuth2 |

### Webhook Receiver

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `/webhook/*` | Receives inbound webhook triggers that activate workflows | Configured per-workflow |
| GET/POST | `/webhook-test/*` | Receives test webhook triggers during workflow development | Configured per-workflow |

### Runner Broker (Internal Only)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| HTTP | Port 5679 | Task broker endpoint — task runners fetch jobs and post results | `N8N_RUNNERS_AUTH_TOKEN` (k8s secret) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for REST API calls
- `X-N8N-API-KEY` header or session cookie for authenticated REST API access

### Error format

> No evidence found in codebase. Standard n8n error responses apply — HTTP status codes with JSON body containing `message` and `code` fields.

### Pagination

> No evidence found in codebase. Standard n8n REST API pagination applies — `limit` and `offset` query parameters on list endpoints.

## Rate Limits

> No rate limiting configured. No rate limiting configuration was found in the deployment manifests.

## Versioning

The REST API follows n8n's built-in versioning. No custom versioning strategy is applied at the Groupon deployment level. The n8n image version is pinned per-component in `.meta/deployment/cloud/components/*/common.yml`.

## OpenAPI / Schema References

> No evidence found in codebase. n8n provides a built-in OpenAPI spec accessible at `/api/v1/openapi.json` on a running instance, but no custom OpenAPI spec is maintained in this repository.
