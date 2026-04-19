---
service: "api-lazlo-sox"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["session", "oauth2", "api-key"]
---

# API Surface

## Overview

API Lazlo exposes a REST/JSON API under the base path `/api/mobile/{countryCode}` for Groupon's first-party mobile apps (iOS, Android) and web clients. The API aggregates data from numerous downstream domain services into mobile-optimized JSON responses. Endpoints are organized by domain: users, deals, orders, geo, UGC, and operational.

API Lazlo SOX exposes a restricted subset of the same API surface for SOX-regulated partner and user flows, using the same base path convention but deployed as a separate service with stricter routing controls.

## Endpoints

### Users and Accounts (`continuumApiLazloService_usersApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/users/{userId}` | Retrieve user profile and account details | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/users` | Register a new user account | API key |
| PUT | `/api/mobile/{countryCode}/users/{userId}` | Update user profile information | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/users/otp` | Request one-time password for authentication | API key |
| POST | `/api/mobile/{countryCode}/users/email-verification` | Trigger or verify email verification flow | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/users/{userId}/wallets` | Retrieve user wallet and payment methods | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/users/{userId}/billing-records` | Retrieve user billing history | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/users/{userId}/gifts` | Retrieve user gift cards and gifted deals | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/users/{userId}/places` | Retrieve user saved places | Session/OAuth2 |

### Deals and Listings (`continuumApiLazloService_dealsAndListingsApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/deals` | Browse and discover deals (with filters) | API key |
| GET | `/api/mobile/{countryCode}/deals/{dealId}` | Get deal details (deal show page) | API key |
| GET | `/api/mobile/{countryCode}/listings` | Get listings for a deal or category | API key |
| GET | `/api/mobile/{countryCode}/cardsearch` | Card-based search for deals and offers | API key |
| GET | `/api/mobile/{countryCode}/deals/buy-it-again` | Deals the user has previously purchased | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/deals/recommendations` | Personalized deal recommendations | Session/OAuth2 |

### Orders, Cart and Redemptions (`continuumApiLazloService_ordersAndCartApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/cart` | Retrieve the current shopping cart | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/cart/items` | Add an item to the shopping cart | Session/OAuth2 |
| DELETE | `/api/mobile/{countryCode}/cart/items/{itemId}` | Remove an item from the shopping cart | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/orders` | Place an order (checkout) | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/orders/{orderId}` | Retrieve order details | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/orders` | List user orders | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/reservations` | Create a booking reservation | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/redemptions` | Redeem a voucher | Session/OAuth2 |

### Geo, Divisions and Taxonomy (`continuumApiLazloService_geoAndTaxonomyApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/divisions` | List available divisions (markets) | API key |
| GET | `/api/mobile/{countryCode}/countries` | List supported countries | API key |
| GET | `/api/mobile/{countryCode}/taxonomies` | Retrieve taxonomy categories | API key |
| GET | `/api/mobile/{countryCode}/localities` | Retrieve locality data for geo-aware experiences | API key |
| GET | `/api/mobile/{countryCode}/locations` | Resolve location data | API key |

### UGC and Social (`continuumApiLazloService_ugcAndSocialApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/ugc` | Retrieve user-generated content feeds | API key |
| POST | `/api/mobile/{countryCode}/ugc/reviews` | Submit a review | Session/OAuth2 |
| POST | `/api/mobile/{countryCode}/share-experience` | Share a deal experience | Session/OAuth2 |

### Status and Operations (`continuumApiLazloService_statusAndOperationsApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthcheck` | Service health check for load balancer and orchestration | None |
| GET | `/readiness` | Readiness probe for orchestration | None |
| GET | `/warmup` | Warmup endpoint to pre-populate caches and connections | None |
| GET | `/static/{resource}` | Static content serving | None |

### SOX Users and Accounts (`continuumApiLazloSoxService_usersApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/users/{userId}` | SOX-regulated user profile retrieval | Session/OAuth2 |
| PUT | `/api/mobile/{countryCode}/users/{userId}` | SOX-regulated user profile updates | Session/OAuth2 |

### SOX Partners and Bookings (`continuumApiLazloSoxService_partnersApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/mobile/{countryCode}/partners` | SOX partner listings and inventory views | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/partners/{partnerId}/bookings` | SOX partner booking details | Session/OAuth2 |
| GET | `/api/mobile/{countryCode}/partners/{partnerId}/listings` | SOX partner listing inventory | Session/OAuth2 |

### SOX Readiness and Operations (`continuumApiLazloSoxService_readinessAndOpsApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/healthcheck` | SOX service health check | None |
| GET | `/readiness` | SOX service readiness probe | None |

## Request/Response Patterns

### Common headers

- `X-Country-Code`: ISO country code matching the `{countryCode}` path parameter
- `X-Locale`: Locale string for localization (e.g., `en_US`, `de_DE`)
- `X-Device-Type`: Client device type (`ios`, `android`, `web`)
- `X-App-Version`: Mobile app version for feature gating
- `Authorization`: Bearer token or session cookie for authenticated endpoints
- `X-Request-Id`: Correlation ID for distributed tracing

### Error format

Errors follow a standard JSON envelope:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description",
    "details": {}
  }
}
```

HTTP status codes follow REST conventions: 400 for client errors, 401/403 for auth, 404 for not found, 500 for server errors.

### Pagination

List endpoints use offset-based pagination:

- `offset` (query param): Starting index (default 0)
- `limit` (query param): Page size (default varies by endpoint)
- Response includes `pagination.total`, `pagination.offset`, `pagination.limit`

## Rate Limits

Rate limiting is handled at the infrastructure layer (load balancer / API gateway) upstream of API Lazlo. Per-endpoint rate limits are not configured within the service itself.

## Versioning

API versioning is implicit in the URL path structure (`/api/mobile/`). Major version changes are coordinated through the mobile app release cycle. The country code path parameter provides per-market behavior differentiation.

## OpenAPI / Schema References

OpenAPI specifications are not generated from the Lazlo controller annotations at this time. The endpoint inventory above is derived from the Lazlo controller routing definitions (`@Path`, `@Endpoint` annotations) in the source code.
