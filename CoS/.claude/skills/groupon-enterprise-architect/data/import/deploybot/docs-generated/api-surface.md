---
service: "deploybot"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [hmac-signature, http-basic, oauth2-oidc]
---

# API Surface

## Overview

deploybot exposes a REST HTTP API that covers three interaction models: webhook ingestion from GitHub, programmatic deployment requests from internal callers, and a browser-facing web UI for status and manual actions. Authentication is enforced per-endpoint — GitHub webhooks use HMAC signature validation (`X-Hub-Signature`), programmatic API calls use HTTP Basic Auth, and OAuth2/OIDC (via Okta) protects all user-facing mutating actions (kill, authorize, promote).

## Endpoints

### Webhook Ingestion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/request/webhook` | Receives GitHub push events to trigger deployments | `X-Hub-Signature` HMAC |

### Deployment Requests

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/request` | Submit a direct programmatic deployment request | HTTP Basic Auth |
| GET | `/v1/deployments/{org}/{project}` | Query deployment history for a project | HTTP Basic Auth |
| POST | `/v1/validate` | Validate `.deploy_bot.yml` config without deploying | HTTP Basic Auth |

### Deployment Management (Web UI / OAuth)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deployments/{key}` | View deployment status and logs in web UI | OAuth2/OIDC (Okta) |
| POST | `/deployments/{key}/kill` | Kill a running deployment | OAuth2/OIDC (Okta) |
| POST | `/deployments/{key}/authorize` | Manually approve a deployment awaiting authorization | OAuth2/OIDC (Okta) |
| POST | `/deployments/{key}/promote/{target}` | Promote a successful deployment to the next environment | OAuth2/OIDC (Okta) |
| GET | `/deployments/{key}/log` | Stream live deployment logs | OAuth2/OIDC (Okta) |

## Request/Response Patterns

### Common headers

- `X-Hub-Signature`: HMAC-SHA1 signature required on `/request/webhook` from GitHub
- `Authorization`: HTTP Basic Auth header required on `/v1/*` endpoints
- `Content-Type: application/json`: Expected for all POST request bodies

### Error format

> No evidence found in codebase for a standardized error response envelope. Errors are returned as HTTP status codes with plain text or JSON body descriptions.

### Pagination

> No evidence found in codebase for pagination on `/v1/deployments/{org}/{project}`. Results are returned in a single response.

## Rate Limits

> No rate limiting configured.

## Versioning

The API uses URL path versioning. Programmatic endpoints are prefixed with `/v1/`. The webhook and web UI endpoints are unversioned. The `.deploy_bot.yml` config file supports `v1` and `v2` schema versions.

## OpenAPI / Schema References

> No evidence found in codebase for an OpenAPI spec, proto files, or GraphQL schema. The `.deploy_bot.yml` per-repo deployment configuration file is the primary schema artifact, supporting `v1` and `v2` formats.
