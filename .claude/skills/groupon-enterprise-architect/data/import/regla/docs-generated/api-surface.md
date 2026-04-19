---
service: "regla"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

regla exposes a REST API via the Play Framework for rule lifecycle management, rule instance registration, and synchronous rule evaluation queries. Consumers use the rule management endpoints to author and approve rules; downstream services call the evaluation query endpoints to make real-time purchase-based decisions; the registration endpoint binds Kafka events to active rule instances.

## Endpoints

### Rule Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rule` | List rule definitions | API key |
| POST | `/rule` | Create a new rule definition | API key |
| PUT | `/rule` | Update a rule definition (includes approve/reject/deactivate actions) | API key |

### Rule Instance

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/ruleInstance/registerRuleEvents` | Register events against a rule instance | API key |

### Rule Evaluation Queries

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/userHasDealPurchaseSince` | Returns whether a user has purchased a specific deal since a given timestamp | API key |
| GET | `/userHasAnyPurchaseEver` | Returns whether a user has ever made any purchase | API key |

### Category / Taxonomy

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/categoryInCategoryTree` | Checks whether a category belongs to a given category tree | API key |

### Infrastructure

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Health check endpoint | None |
| GET | `/status` | Service status indicator | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all write requests
- `Accept: application/json` — expected on all requests

### Error format

> No evidence found in codebase for a standardised error response envelope. Follow Play Framework default JSON error conventions.

### Pagination

> No evidence found in codebase for pagination parameters on list endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No URL path versioning is used. All endpoints are at the root path level. Rule schema evolution is managed through the `PUT /rule` update flow.

## OpenAPI / Schema References

> No evidence found in codebase for an OpenAPI spec, proto file, or schema definition in the repository.
