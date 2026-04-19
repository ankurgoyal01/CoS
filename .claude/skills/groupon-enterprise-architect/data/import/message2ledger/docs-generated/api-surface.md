---
service: "message2ledger"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

message2ledger exposes a set of internal admin and stats endpoints served by the `m2l_replayAndRetryApi` component (`continuumMessage2LedgerService`). These endpoints are used by Finance Engineering operators to inspect message and attempt history, trigger manual replays and retries, investigate unit lifecycle activity, and monitor pipeline health. There are no public-facing or customer-facing endpoints.

## Endpoints

### Admin — Unit Lifecycle

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/units/{id}/activity` | Retrieve activity history for a specific inventory unit | Internal |

### Admin — Message Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/admin/messages` | List messages with filtering by status, date, or subject | Internal |
| POST | `/admin/messages` | Create or inject a message record for manual processing | Internal |
| PUT | `/admin/messages` | Update an existing message record | Internal |
| POST | `/admin/messages/retry/{id}` | Trigger a manual retry for a specific message by ID | Internal |

### Contract Replay

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/messages` | Replay messages via contract; used during migration window | Internal |

### Stats

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/stats/dailyMessages` | Returns count of messages processed per day | Internal |
| GET | `/stats/errors` | Returns current error counts by category | Internal |
| GET | `/stats/attempts` | Returns attempt statistics across processing attempts | Internal |

## Request/Response Patterns

### Common headers

> No evidence found for standard required headers beyond internal service identity headers typical of JTier services.

### Error format

> Operational procedures to be defined by service owner. JTier/Dropwizard services typically return standard HTTP error codes with a JSON body containing `code` and `message` fields.

### Pagination

> No evidence found for pagination on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL versioning strategy is in use. Endpoints are not versioned; they are internal-only admin surfaces consumed by Finance Engineering tooling.

## OpenAPI / Schema References

> No evidence found for an OpenAPI spec or schema file in the architecture sources. Schema definitions to be located in the service repository.
