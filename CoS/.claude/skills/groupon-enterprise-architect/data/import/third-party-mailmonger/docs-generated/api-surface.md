---
service: "third-party-mailmonger"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

Third Party Mailmonger exposes a REST API (Swagger 2.0 / OpenAPI) served by Dropwizard/JAX-RS on port 8080. The API is divided into five functional groups: webhook receivers (SparkPost relay), masked-email provisioning, partner email registration, email inspection (customer support), and email domain management. All responses are JSON. The service is internal-only (no public internet exposure); authentication relies on network-level controls rather than per-request tokens.

The OpenAPI schema is available at `doc/swagger/swagger.yaml` and `doc/swagger/swagger.json` in the repository.

## Endpoints

### Webhooks (SparkPost relay receivers)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/mailmonger/v1/sparkpost-callback` | Receives inbound relay emails from SparkPost; triggers logging, filtering, and re-delivery | Internal network |
| POST | `/mailmonger/v1/sparkpost-event` | Debug endpoint — inspects SparkPost event payloads; logs and returns event data | Internal network |

### Masked Email

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/masked/consumer/{consumerId}/{partnerId}` | Returns (or creates) a masked email address unique to the consumer/partner pair; called by TPIS during reservation | Internal network |

### Partner Email

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/partner` | Registers or retrieves a partner email object; associates a real partner email address with a partner ID | Internal network |

### Email Inspection (Customer Support)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/emails` | Lists emails with optional filters (status, consumerId, transactionId); paginated | Internal network |
| GET | `/v1/emails/{email}` | Retrieves a single email by UUID | Internal network |

### Email Retry

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/v1/email/{emailContentId}/retry` | Manually triggers a retry for a specific email content ID | Internal network |

### Email Domain Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/email_domains` | Lists registered partner email domains (paginated) | Internal network |
| POST | `/v1/email_domains` | Registers a new partner email domain by name/regex and partner ID | Internal network |
| DELETE | `/v1/email_domains/{partnerEmailDomainID}` | Removes a registered partner email domain by UUID | Internal network |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` for all POST request bodies
- SparkPost relay webhook payload body is a raw string containing the relay message JSON (`msys.relay_message` structure)

### Error format

Standard Dropwizard/JTier error responses. HTTP 400 for malformed or missing required parameters, HTTP 404 when a requested resource (email, transactionId) is not found.

### Pagination

The `/v1/emails` and `/v1/email_domains` endpoints support offset-based pagination via `limit` (default 10) and `offset` (default 0) query parameters. Responses include a `pagination` object containing `total`, `limit`, and `offset` fields.

## SLA Targets

| Endpoint Group | Requests/sec | TP99 Latency | Uptime | Timeout |
|----------------|-------------|-------------|--------|---------|
| `/mailmonger/v1/sparkpost-callback` | 1 | 5000 ms | 99.6% | 10000 ms |
| `/mailmonger/v1/sparkpost-event` | 1 | 5000 ms | 99.6% | 10000 ms |
| `/v1/masked/consumer/{consumerId}/{partnerId}` | 10 | 100 ms | 99.6% | 200 ms |
| `/v1/emails`, `/v1/emails/{id}` | 1 | 100 ms | 99.6% | 200 ms |

## Versioning

All endpoints use URL path versioning with the prefix `/v1/`. The SparkPost webhook endpoints use the path prefix `/mailmonger/v1/`.

## OpenAPI / Schema References

- OpenAPI (Swagger 2.0) spec: `doc/swagger/swagger.yaml`
- JSON form: `doc/swagger/swagger.json`
- Service discovery descriptor: `doc/service_discovery/resources.json`
- Published schema: `http://mailmonger-vip.snc1/swagger`
