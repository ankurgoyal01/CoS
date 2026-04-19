---
service: "pact-broker"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [basic-auth]
---

# API Surface

## Overview

Pact Broker exposes a standard pact-foundation REST API and web UI on port 9292. Consumer services use it to publish pact files; provider services use it to record verification results. CI pipelines query the `can-i-deploy` endpoint to determine deployment safety. The API follows the Pact Broker HAL+JSON hypermedia convention defined by the upstream pact-foundation project.

## Endpoints

### Diagnostics

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/diagnostic/status/heartbeat` | Liveness and readiness probe | None (public) |

### Pact Publishing and Retrieval

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| PUT | `/pacts/provider/{provider}/consumer/{consumer}/version/{consumerVersion}` | Publishes a pact contract from a consumer for a specific version | Basic auth (write) |
| GET | `/pacts/provider/{provider}/consumer/{consumer}/latest` | Retrieves the latest pact for a provider/consumer pair | Public read |
| GET | `/pacts/provider/{provider}/consumer/{consumer}/version/{consumerVersion}` | Retrieves a specific versioned pact | Public read |
| GET | `/pacts/provider/{provider}/latest` | Retrieves all latest pacts for a provider | Public read |

### Verification Results

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/pacts/provider/{provider}/consumer/{consumer}/pact-version/{pactVersion}/verification-results` | Records a verification result from a provider | Basic auth (write) |
| GET | `/pacts/provider/{provider}/consumer/{consumer}/pact-version/{pactVersion}/verification-results/latest` | Retrieves latest verification result | Public read |

### Pacticipants and Versions

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/pacticipants` | Lists all registered consumers and providers | Public read |
| GET | `/pacticipants/{name}` | Returns metadata for a named pacticipant | Public read |
| GET | `/pacticipants/{name}/versions` | Lists versions for a pacticipant | Public read |

### Deployment Safety

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/can-i-deploy` | Checks whether a version of a pacticipant can be deployed safely | Public read |

### Webhooks

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/webhooks` | Creates a new webhook configuration | Basic auth (write) |
| GET | `/webhooks` | Lists all configured webhooks | Basic auth |

### Web UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Pact Broker web UI (HAL browser) | Public read (`PACT_BROKER_ALLOW_PUBLIC_READ: true`) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for API requests
- `Accept: application/hal+json` for HAL hypermedia responses

### Error format

Standard HTTP status codes. The upstream pact-broker application returns JSON error bodies with a `errors` or `message` field consistent with the pact-foundation API specification.

### Pagination

> No evidence found in codebase. Pagination behavior follows the upstream pact-foundation/pact-broker defaults.

## Rate Limits

> No rate limiting configured. No rate-limit configuration was found in the deployment manifests or app configuration.

## Versioning

The API follows pact-foundation versioning: pact versions are embedded in URL path segments (`/version/{consumerVersion}`). No URL-level API version prefix is used. The running application version is `2.135.0-pactbroker2.117.1`.

## OpenAPI / Schema References

The pact-foundation/pact-broker application publishes its API as a HAL+JSON hypermedia API. No OpenAPI spec file is present in this repository. Refer to the [pact-foundation Pact Broker API documentation](https://docs.pact.io/pact_broker/api) for the canonical schema reference.
