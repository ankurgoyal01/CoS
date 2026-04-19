---
service: "partner-attributes-mapping-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

PAMS exposes a REST JSON API versioned under the `/v1` path prefix. All endpoints require a `client-id` header for access control. Mapping endpoints additionally accept an `X-Brand` header to scope operations to a partner namespace. The service groups endpoints into three functional areas: ID mapping operations, partner secret management, and HMAC signature operations.

## Endpoints

### Mapping — Create and Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/mapping` | Store partner-to-Groupon ID mappings (ignores existing duplicates) | `client-id` header (required) |
| `POST` | `/v1/search_partner_mappings` | Look up Groupon IDs for a list of partner IDs | `client-id` header (required) |
| `POST` | `/v1/search_groupon_mappings` | Look up partner IDs for a list of Groupon IDs | `client-id` header (required) |

### Mapping — Update and Delete

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `PUT` | `/v1/groupon_mappings` | Update the partner ID for an existing Groupon ID mapping (single mapping per request) | `client-id` header (required) |
| `PUT` | `/v1/partner_mappings` | Update the Groupon ID for an existing partner ID mapping (single mapping per request) | `client-id` header (required) |
| `DELETE` | `/v1/groupon_mapping/{grouponId}` | Delete a mapping by Groupon UUID | `client-id` header (required) |

### Partner Secret Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/partners/{partner_name}/secrets/generate` | Generate and persist an HMAC secret for a named partner | `client-id` header (required) |
| `PUT` | `/v1/partners/{partner_name}/secrets/update` | Update the HMAC secret for a named partner | `client-id` header (required) |

### Signature Operations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/v1/signature` | Generate an HMAC-SHA1 signature for a payload targeting a partner endpoint | `X-BRAND` header (required) |
| `POST` | `/v1/signature/validation` | Validate an inbound HMAC signature from a partner | `X-BRAND` header (required) |

## Request/Response Patterns

### Common headers

| Header | Required | Description |
|--------|----------|-------------|
| `client-id` | Required (mapping + secret endpoints) | Client identifier provided for API access; enforced by `HeadersValidationFilter` |
| `X-Brand` | Optional/Required depending on endpoint | Partner namespace identifier (e.g., `banking_partner`, `gemini`); scopes mapping operations to the partner |
| `X-BRAND` | Required (signature endpoints) | Partner brand ID for signature operations |
| `Content-Type` | `application/json` | Required for `POST`/`PUT` with body |

### Request body — Mapping operations

Mapping endpoints accept a body keyed by entity type. Entity types are dynamic strings such as `users` or `billingRecords`.

```json
{
  "users": [
    { "grouponId": "<uuid>", "partnerId": "<partner-string>" }
  ]
}
```

Search endpoints accept entity-type-keyed arrays of IDs:
```json
{ "users": ["<uuid1>", "<uuid2>"] }
```

### Request body — Signature creation (`POST /v1/signature`)

```json
{
  "baseUrl": "https://partner-endpoint.example.com/api",
  "bodySha": "<sha256-hex-of-payload>",
  "digest": "HMAC-SHA1",
  "httpMethod": "POST",
  "version": "1.1",
  "nonce": "random-1",
  "scheme": "groupon-third-party",
  "urlParams": "key=value&other=val"
}
```

### Response body — Signature creation

```json
{
  "body": "<base64-signature>",
  "digest": "HMAC-SHA1",
  "digestVersion": "1.1",
  "formattedSignatureHeader": "groupon-third-party version=\"1.1\",digest=\"HMAC-SHA1\",nonce=\"random-1\",signature=\"%2F...%3D\"",
  "nonce": "random-1",
  "scheme": "groupon-third-party"
}
```

### Error format

All error responses share a standard structure:

```json
{
  "code": 400,
  "message": "Empty/duplicate IDs found",
  "details": "<optional additional context>",
  "payload": { "<entityType>": [ ... ] }
}
```

The `payload` field is included when the error relates to specific mapping entries (e.g., duplicate mapping conflicts).

### Pagination

> No evidence found in codebase. Bulk operations accept lists in a single request; no cursor or page-based pagination is implemented.

## Rate Limits

> No rate limiting configured. No rate limiting configuration was found in the codebase or deployment manifests.

## Versioning

All endpoints are grouped under `/v1`. The API version is encoded in the URL path. The Swagger spec declares version `1.0.local-SNAPSHOT` as the service artifact version.

## OpenAPI / Schema References

- Swagger YAML: `doc/swagger/swagger.yaml`
- Swagger JSON: `doc/swagger/swagger.json`
- Service discovery manifest: `doc/service_discovery/resources.json`
- Swagger UI config: `doc/swagger/config.yml`
