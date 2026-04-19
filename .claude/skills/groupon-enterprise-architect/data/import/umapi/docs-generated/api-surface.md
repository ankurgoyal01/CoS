---
service: "umapi"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [oauth2]
---

# API Surface

## Overview

UMAPI exposes a RESTful JSON API over HTTPS, serving as the single integration point for merchant lifecycle operations. Consumers include the Merchant Center Web UI, mobile merchant apps, and numerous backend services. The API Proxy (edge gateway) routes external traffic to UMAPI. The service also provides internal OAuth redirect and token endpoints used for merchant-facing application authentication (e.g., Bookability Dashboard login).

Based on the cross-service relationship evidence, the API surface covers the following functional domains:

- **Merchant auth and account**: OAuth redirect/token endpoints, user authentication, account management
- **Merchant profiles and places**: CRUD for merchant profiles, place/location lookup (e.g., by slug), contact data
- **Deals and vouchers**: Deal management, voucher operations for merchant tools
- **Reporting and inbox**: Merchant reporting, data aggregation, inbox APIs
- **Booking service**: Booking data read/write via proxy endpoints
- **Campaign and billing**: Sponsored campaign, billing, and performance operations
- **3PIP onboarding**: Third-party integration partner mapping and onboarding state
- **Search**: Merchant search capabilities

## Endpoints

> No evidence found in codebase. The architecture DSL defines the container and its relationships but does not enumerate individual endpoints. The following is inferred from consumer relationship descriptions.

### Merchant Authentication

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/oauth/authorize` (inferred) | OAuth redirect for merchant login | OAuth2 |
| POST | `/oauth/token` (inferred) | Exchange OAuth authorization code for token | OAuth2 |

### Merchant Profiles & Places

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/merchants/{id}` (inferred) | Retrieve merchant profile | OAuth2 |
| GET | `/places/{slug}` (inferred) | Get place by slug | OAuth2 |
| PUT | `/merchants/{id}` (inferred) | Update merchant profile | OAuth2 |
| GET | `/merchants/search` (inferred) | Search merchants | OAuth2 |

### Deals, Vouchers & Reporting

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| -- | `/deals/**` (inferred) | Deal management operations | OAuth2 |
| -- | `/vouchers/**` (inferred) | Voucher operations | OAuth2 |
| -- | `/reporting/**` (inferred) | Merchant reporting and aggregation | OAuth2 |

### Booking & Campaigns

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| -- | `/booking/**` (inferred) | Booking-service data read/write | OAuth2 |
| -- | `/campaigns/**` (inferred) | Campaign, billing, performance operations | OAuth2 |

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Typical patterns for Continuum JSON/HTTPS APIs apply.

### Error format

> No evidence found in codebase.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No evidence found in codebase. Rate limiting may be handled at the API Proxy (edge gateway) layer.

## Versioning

> No evidence found in codebase. Versioning strategy is not documented in the architecture DSL.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or schema references are present in the architecture model.
