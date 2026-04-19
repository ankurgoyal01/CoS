---
service: "channel-manager-integrator-derbysoft"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

The service exposes a REST/JSON HTTP API consumed by Derbysoft partner systems (for inbound ARI push) and by internal Groupon tooling (for hotel sync status, resource mapping management, and reservation data lookup). All endpoints are served on port 8080. An authorization header filter (`AuthFilter`) validates requests against a configured `authorizationHeaderValue` before allowing access to protected endpoints.

## Endpoints

### ARI Push

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/ari/daily/push` | Receives a Daily ARI push payload from a Derbysoft partner for a hotel over a date range | Header auth (`derbysoftAuthenticationConfig.authorizationHeaderValue`) |

### Hotel Sync

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/ping` | Health check — verifies the service is reachable | None |
| `GET` | `/hotels/{supplierId}` | Retrieves status for all hotels associated with a Derbysoft supplier chain | Header auth |
| `GET` | `/hotel/{supplierId}/{hotelId}` | Retrieves status for all products (room types, rate plans) associated with a specific hotel | Header auth |

### Resource Mapping

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/getaways/v2/channel_manager_integrator/mapping` | Retrieves the connectivity extranet mapping for a given hotel UUID | Header auth |
| `PUT` | `/getaways/v2/channel_manager_integrator/mapping` | Creates or updates the extranet mapping (hotel, room-type, rate-plan) for a hotel | Header auth |

### Reservation Data

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/getaways/v2/channel_manager_integrator/reservation/data` | Retrieves persisted reservation request/response data for a given hotel UUID and inventory unit ID | Header auth |

## Request/Response Patterns

### Common headers
- `Authorization` — Required on protected endpoints. Value validated against `derbysoftAuthenticationConfig.authorizationHeaderValue` configured in the service YAML.
- `Content-Type: application/json` — Required for `POST`/`PUT` requests.
- `Accept: application/json` — Expected for all responses.

### Error format
Standard Dropwizard/JTier error responses are returned as JSON. ARI push validation errors are logged via `DailyAriPushRequestLogger` and `DailyAriPushResponseLogger` and persisted to the ARI request/response tables. Validation failures return HTTP 422 (Unprocessable Entity) with a JSON error body describing each invalid field.

### Pagination
> No evidence found in codebase.

## Rate Limits

> No rate limiting configured. Partners are subject to network-level controls only.

## Versioning

REST endpoints in the `/getaways/v2/` path namespace follow URL-path versioning (`v2`). The ARI and Hotel Sync endpoints do not use an explicit version prefix in their path.

## OpenAPI / Schema References

- OpenAPI spec declared at `src/main/resources/openapi.yaml` (referenced in `.service.yml` `open_api_schema_path`)
- Swagger UI available internally at: `http://getaways-channel-manager-integrator-ds-app-vip.snc1:8080/swagger`
- External base URL (production): `http://api.groupon.com/getaways/v2/partner/derbysoft/CMService`
