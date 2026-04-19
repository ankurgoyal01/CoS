---
service: "deal-alerts"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rpc"]
auth_mechanisms: ["google-sso", "session"]
---

# API Surface

## Overview

Deal Alerts exposes a type-safe RPC API via oRPC, mounted at `/rpc`. The API is consumed by the Next.js frontend using TanStack Query with generated type-safe clients. All endpoints use the oRPC protocol (JSON over HTTP). Public endpoints require no authentication; authenticated endpoints require a valid BetterAuth session; admin endpoints additionally require the `admin` role.

## Endpoints

### Alerts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/alerts.list` | List alerts with optional filters by deal ID, type, status, and action presence. Supports pagination (limit/offset). | Public |
| GET | `/rpc/alerts.get` | Get alert detail including notification, action data, actions, and replies for a specific alert ID. | Public |
| GET | `/rpc/alerts.ruleTypes` | List all configured alert types. | Public |
| GET | `/rpc/alerts.statuses` | List all configured alert statuses. | Public |

### Snapshots

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/snapshot.get` | Fetch a single deal snapshot by deal ID. | Public |
| GET | `/rpc/snapshot.list` | List deal snapshots with search (full-text, UUID, merchant UUID). Supports pagination. | Public |

### Deltas

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/delta.field` | Get field deltas time series for a specific deal, field name, and optional option ID. | Public |
| GET | `/rpc/delta.fieldsAtTime` | Reconstruct field values at a specific point in time for a given deal. | Public |

### Monitored Fields

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/monitored_fields.list` | List all configured monitored fields with scope (field/option). | Public |
| POST | `/rpc/monitored_fields.create` | Add a new monitored field with scope. | Admin |
| DELETE | `/rpc/monitored_fields.delete` | Remove a monitored field by name and scope. | Admin |

### Templates

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/templates.list` | List all message templates (optionally include deleted). | Public |
| GET | `/rpc/templates.get` | Get a specific template by ID. | Public |
| POST | `/rpc/templates.create` | Create a new message template. | Admin |
| PUT | `/rpc/templates.update` | Update an existing template's name, subject, and body. | Admin |
| DELETE | `/rpc/templates.delete` | Soft-delete a template (blocked if referenced by action mappings). | Admin |

### Action Maps

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/actionMaps.list` | List all alert-to-action mappings with severity and template associations. | Public |
| POST | `/rpc/actionMaps.create` | Create a new alert-action mapping with severity levels. Validates severity overlap. | Admin |
| PUT | `/rpc/actionMaps.update` | Update an existing mapping's action type, severity, template, and active state. | Admin |
| PUT | `/rpc/actionMaps.reorder` | Reorder action map priorities within an alert type (transactional). | Admin |
| DELETE | `/rpc/actionMaps.delete` | Delete an alert-action mapping. | Admin |

### Action Types

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/actionTypes.list` | List all available action types. | Public |

### Severity Matrix

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/severityMatrix.list` | List all severity matrices with entry counts. | Public |
| GET | `/rpc/severityMatrix.get` | Get a severity matrix by name with all entries (auto-creates if missing). | Public |
| POST | `/rpc/severityMatrix.create` | Create a new named severity matrix. | Admin |
| POST | `/rpc/severityMatrix.upsert` | Upsert a severity matrix entry (alert type, severity level, GP30 threshold). | Admin |
| POST | `/rpc/severityMatrix.copyTo` | Copy severity entries from one alert type to others (transactional). | Admin |
| DELETE | `/rpc/severityMatrix.delete` | Delete a severity matrix entry. | Admin |
| DELETE | `/rpc/severityMatrix.deleteMatrix` | Soft-delete a severity matrix (default matrix protected). | Admin |

### SMS

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/sms.stats` | Get SMS notification statistics: delivery, reply, subscription, and user counts. | Public |
| GET | `/rpc/sms.list` | List SMS notifications with filters by status and reply type. Supports pagination. | Public |
| GET | `/rpc/sms.getByPhoneNumber` | Get full conversation history for a phone number including notifications and replies. | Public |

### Muted Alerts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/mutedAlerts.list` | List muted alerts filtered by entity ID and expiration. Supports pagination. | Admin |
| POST | `/rpc/mutedAlerts.create` | Create muted alert entries for Salesforce account/opportunity IDs with configurable duration. Idempotent upsert. | Admin |
| DELETE | `/rpc/mutedAlerts.delete` | Delete muted alert by ID or entity ID. | Admin |

### Logs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/logs.list` | Aggregate error logs from actions, summary emails, and notification replies. Supports source filter and pagination. | Public |

### Health

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rpc/health.check` | Health check returning database connectivity status. | Public |
| GET | `/rpc/health.live` | Lightweight liveness probe returning "OK". | Public |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` for all requests and responses
- BetterAuth session cookie (`deal-alerts_session_token`) for authenticated endpoints

### Error format
oRPC standard error format with `code`, `message`, and optional `data`:
- `NOT_FOUND` (404): Resource does not exist
- `UNAUTHORIZED` (401): Missing or invalid session
- `BAD_REQUEST` (400): Invalid input
- `CONFLICT` (409): Duplicate or overlap detected
- `INPUT_VALIDATION_FAILED` (422): Zod validation failure with flattened error details
- `OUTPUT_VALIDATION_FAILED` (500): Server-side output schema mismatch
- `SERVICE_UNAVAILABLE` (503): Database connectivity failure

### Pagination
Offset-based pagination using `limit` and `offset` parameters. The `snapshot.list` endpoint additionally returns `total`, `hasNextPage`, and `hasPreviousPage`. The `logs.list` endpoint uses page-based pagination with `hasMore` indicator.

## Rate Limits

> No rate limiting configured.

## Versioning

No explicit API versioning. The oRPC router structure acts as the implicit contract. Schema changes are managed through Zod input/output type evolution.

## OpenAPI / Schema References

oRPC can generate OpenAPI schemas via the `@orpc/openapi` package (dependency present in `apps/web/package.json`). Zod schemas in each router file serve as the authoritative contract definitions.
