---
service: "cloudability"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["api-key"]
---

# API Surface

## Overview

Cloudability does not expose its own HTTP API. Instead, it acts as a client that calls the Cloudability SaaS REST API. The provisioning CLI scripts interact with the Cloudability Provisioning API (`https://api.cloudability.com/v3/`) using HTTP Basic Auth (API key as username, empty password). The Metrics Agent uploads collected data to Cloudability's ingestion endpoints autonomously once deployed.

## Endpoints

### Cloudability Provisioning API (External — consumed by this service)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `https://api.cloudability.com/v3/containers/provisioning` | Registers a new Kubernetes cluster in Cloudability | API key (HTTP Basic) |
| GET | `https://api.cloudability.com/v3/containers/provisioning` | Lists all registered clusters; used to resolve cluster ID by name | API key (HTTP Basic) |
| GET | `https://api.cloudability.com/v3/containers/provisioning/{id}/config` | Fetches the generated Kubernetes agent manifest for a registered cluster | API key (HTTP Basic) |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for POST registration request
- HTTP Basic Auth: API key as the username field, password field empty

### Error format

The Cloudability API returns HTTP 400 when a cluster registration is attempted for an already-registered cluster. The provisioning scripts treat this as non-fatal (the existing cluster key remains valid).

### Pagination

> No evidence found in codebase.

## Rate Limits

> No rate limiting configured for provisioning CLI calls. The agent upload cadence is governed by the Cloudability Metrics Agent runtime (observed interval: approximately 10 minutes per `Uploading Metrics` log entry).

## Versioning

The Cloudability API is versioned via URL path prefix `/v3/`. This service targets v3 exclusively, as evidenced by all curl calls in `get_agent_config.sh` and `get_raw_config.sh`.

## OpenAPI / Schema References

> No OpenAPI spec or schema files are present in this repository. Refer to the [Cloudability Developers API documentation](https://developers.cloudability.com/) for the upstream API schema.
