---
service: "gpapi"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2, session, recaptcha]
---

# API Surface

## Overview

gpapi exposes a versioned REST API organized into four version namespaces (V0–V3) plus an external webhook endpoint. All API versions serve the Goods Vendor Portal UI and handle vendor-centric operations: product management, contract workflows, session authentication, and compliance. The V0 namespace covers legacy goods stores; V1 is the primary stable surface; V2 extends to promotions, co-op agreements, and Avalara tax; V3 covers deal and inventory instances. The NetSuite webhook is the sole inbound external integration.

## Endpoints

### V0 — Legacy Goods Stores

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v0/goods_stores` | List legacy goods stores | Session |
| GET | `/api/v0/goods_stores/:id` | Retrieve a specific goods store | Session |

### V1 — Core Vendor Portal

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/api/v1/sessions` | Create session (login with reCAPTCHA 2FA) | reCAPTCHA + credentials |
| DELETE | `/api/v1/sessions/:id` | Destroy session (logout) | Session |
| GET | `/api/v1/users` | List users | Session |
| GET | `/api/v1/users/:id` | Retrieve user | Session |
| POST | `/api/v1/users` | Create user | Session |
| PATCH | `/api/v1/users/:id` | Update user | Session |
| GET | `/api/v1/vendors` | List vendors | Session |
| GET | `/api/v1/vendors/:id` | Retrieve vendor | Session |
| POST | `/api/v1/vendors` | Create vendor | Session |
| PATCH | `/api/v1/vendors/:id` | Update vendor | Session |
| GET | `/api/v1/products` | List products | Session |
| GET | `/api/v1/products/:id` | Retrieve product | Session |
| POST | `/api/v1/products` | Create product | Session |
| PATCH | `/api/v1/products/:id` | Update product | Session |
| DELETE | `/api/v1/products/:id` | Deactivate product | Session |
| GET | `/api/v1/items` | List items | Session |
| GET | `/api/v1/items/:id` | Retrieve item | Session |
| POST | `/api/v1/items` | Create item | Session |
| PATCH | `/api/v1/items/:id` | Update item | Session |
| GET | `/api/v1/contracts` | List contracts | Session |
| GET | `/api/v1/contracts/:id` | Retrieve contract | Session |
| POST | `/api/v1/contracts` | Create contract | Session |
| PATCH | `/api/v1/contracts/:id` | Update contract | Session |
| GET | `/api/v1/vendor_compliance` | Retrieve vendor compliance status | Session |
| POST | `/api/v1/vendor_compliance` | Submit vendor compliance data | Session |
| GET | `/api/v1/tickets` | List tickets | Session |
| POST | `/api/v1/tickets` | Create ticket | Session |
| GET | `/api/v1/bank_info` | Retrieve bank information | Session |
| POST | `/api/v1/bank_info` | Submit bank information | Session |
| GET | `/api/v1/categories` | List categories | Session |

### V2 — Promotions, Co-op, Files, Pricing, Tax

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v2/promotions` | List promotions | Session |
| POST | `/api/v2/promotions` | Create promotion | Session |
| PATCH | `/api/v2/promotions/:id` | Update promotion | Session |
| GET | `/api/v2/co_op_agreements` | List co-op agreements | Session |
| POST | `/api/v2/co_op_agreements` | Create co-op agreement | Session |
| PATCH | `/api/v2/co_op_agreements/:id` | Update co-op agreement | Session |
| GET | `/api/v2/external_files` | List external files | Session |
| POST | `/api/v2/external_files` | Upload external file (via S3) | Session |
| GET | `/api/v2/vendor_items` | List vendor items with pricing | Session |
| PATCH | `/api/v2/vendor_items/:id` | Update vendor item pricing | Session |
| POST | `/api/v2/avalara` | Proxy Avalara tax lookup | Session |

### V3 — Deal and Inventory Instances

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v3/deal_instances` | List deal instances | Session |
| GET | `/api/v3/deal_instances/:id` | Retrieve deal instance | Session |
| GET | `/api/v3/inventory_item_instances` | List inventory item instances | Session |
| PATCH | `/api/v3/inventory_item_instances/:id` | Update inventory item instance | Session |

### External — NetSuite Webhook

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/webhooks/netsuite` | Receive NetSuite accounting event | HMAC/token |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all write requests
- `Accept: application/json` — expected on all requests
- `Authorization` or session cookie — required for authenticated endpoints

### Error format

Errors follow a standard Rails JSON API error envelope. HTTP status codes are used semantically (400 for validation errors, 401 for unauthenticated, 403 for forbidden, 404 for not found, 422 for unprocessable entity, 500 for server errors).

### Pagination

> No evidence found in codebase. Assumed standard Rails pagination patterns (page/per_page query parameters) for list endpoints based on Rails 5.2 conventions.

## Rate Limits

> No rate limiting configured based on available inventory evidence.

## Versioning

URL path versioning is used: `/api/v0/`, `/api/v1/`, `/api/v2/`, `/api/v3/`. V0 is the legacy namespace; V1 is the primary stable surface; V2 and V3 extend with newer capabilities. Versions are maintained in parallel to support ongoing Vendor Portal UI upgrades without breaking existing consumers.

## OpenAPI / Schema References

> No evidence found in codebase. Schema-driven client contracts are managed via the `schema_driven_client` gem (version 0.5.0) for internal service calls; no OpenAPI spec file has been identified in the inventory.
