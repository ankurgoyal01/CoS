---
service: "machine-learning-toolkit"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest", "https"]
auth_mechanisms: ["api-key"]
---

# API Surface

## Overview

The Machine Learning Toolkit exposes a private HTTPS REST API via AWS API Gateway. The API is `PRIVATE_ONLY` (accessible only within the Groupon VPC) and secured by API key in the request header. It serves two purposes: platform healthchecks and proxying inference requests to backend SageMaker endpoints. The API structure is versioned by path segment and each model project deploys its own inference resource under its assigned version prefix.

## Endpoints

### Platform Healthcheck

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/healthcheck` | Verify the API Gateway itself is healthy; returns `{ "message": "I am healthy" }` when `scope=internal` | None (no API key required) |

### Version Healthcheck

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/{version}` | Verify that a specific model version root is reachable; returns `{ "message": "I am healthy" }` when `scope=internal` | None (no API key required) |

### Model Inference

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/{version}/{api_name}` | Submit an inference request to the named SageMaker endpoint for the given version; proxied via AWS API Gateway integration to the SageMaker runtime invocation URI | API key (`X-API-Key` header, required) |

> The `{version}` and `{api_name}` path segments are dynamically provisioned per project via Terraform. No static, hard-coded endpoint names are documented here because they are project-specific configuration inputs.

### Async Inference

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/{version}/{api_name}` (async variant) | Submit an asynchronous inference request; the `s3loc` header provides the S3 input location; routed to the SageMaker async-invocations URI | API key (`X-API-Key` header, required) |

## Request/Response Patterns

### Common headers

| Header | Direction | Required | Purpose |
|--------|-----------|----------|---------|
| `X-API-Key` | Request | Yes (inference endpoints) | API Gateway usage plan authentication |
| `scope` | Request query string | Yes (healthcheck) | Pass `internal` to receive a 200 healthy response |
| `s3loc` | Request | Yes (async inference only) | S3 location of the async inference input payload |
| `Content-Type: application/json` | Request | Yes (inference endpoints) | Inference endpoints only accept JSON |

### Error format

| Status | Meaning | Response Body |
|--------|---------|---------------|
| `200` | Success | Inference result JSON from SageMaker |
| `400` | Bad request | `{ "message": "<error message>", "status": 400 }` |
| `403` | Unauthorized | Missing or invalid API key |
| `415` | Unsupported media type | Non-JSON body submitted to inference endpoint |
| `424` | Model error | `#set($inputRoot = $input.path('$')) $inputRoot.OriginalMessage` — SageMaker application error propagated as-is |
| `503` | Service unavailable | SageMaker endpoint unavailable or throttled |

### Pagination

> Not applicable. Inference endpoints are single-request/single-response.

## Rate Limits

Rate limiting is applied through AWS API Gateway usage plans provisioned per model API. Stage-level throttle settings are managed by the `continuumMlToolkitUsagePlans` component.

| Tier | Limit | Window |
|------|-------|--------|
| Per API key | Configured per project via Terraform `api_config` | Per usage plan stage |

> Exact throttle values are project-specific inputs to the platform Terraform module and are not fixed at the platform level.

## Versioning

The API uses URL path versioning. Each model project specifies a `version` value (e.g., `v1`, `v2`) when registering an API through the Terraform module. All inference endpoints for that project are nested under `/{version}/{api_name}`. The healthcheck at `/{version}` confirms version-level availability.

## OpenAPI / Schema References

A stub OpenAPI schema exists at `doc/swagger/swagger.yaml` (relative to the service repo root). As of the current inventory, it contains placeholder `TBD` values and does not reflect the dynamically provisioned inference endpoints. The `old_swagger.yaml` at `doc/swagger/old_swagger.yaml` is a historical artifact.

The active API contract for each model endpoint is defined at deploy time through the Terraform `api_config` variable, which controls path, version, request schema, and async mode.
