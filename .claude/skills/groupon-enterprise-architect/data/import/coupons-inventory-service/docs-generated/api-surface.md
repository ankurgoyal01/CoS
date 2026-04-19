---
service: "coupons-inventory-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [client-id-auth]
---

# API Surface

## Overview

Coupons Inventory Service exposes a RESTful API via Jersey (JAX-RS) resources for managing coupon inventory products, units, reservations, clicks, and availability. All endpoints are authenticated via client-id-based authorization (CISAuthenticator/CISAuthorizer with ClientIdAuthFilter). The API follows standard REST patterns with JSON request/response bodies. There are five primary resource groups corresponding to the five API components in the architecture model.

## Endpoints

### Product API (`continuumCouponsInventoryService_productApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/products` | List or search inventory products | Client ID |
| GET | `/products/{id}` | Retrieve a specific inventory product by ID | Client ID |
| POST | `/products` | Create a new inventory product | Client ID |
| PUT | `/products/{id}` | Update an existing inventory product | Client ID |
| GET | `/products?dealId={dealId}` | Query products by deal-id (cached in Redis) | Client ID |

### Unit API (`continuumCouponsInventoryService_unitApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/units` | List or search coupon units | Client ID |
| GET | `/units/{id}` | Retrieve a specific coupon unit | Client ID |
| POST | `/units` | Create coupon units for a product | Client ID |
| PUT | `/units/{id}` | Update a coupon unit | Client ID |

### Reservation API (`continuumCouponsInventoryService_reservationApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/reservations` | List or search reservations | Client ID |
| GET | `/reservations/{id}` | Retrieve a specific reservation | Client ID |
| POST | `/reservations` | Create a new reservation against inventory | Client ID |

### Click API (`continuumCouponsInventoryService_clickApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/clicks` | Query click events for offers | Client ID |
| POST | `/clicks` | Record a click event for an offer | Client ID |

### Availability API (`continuumCouponsInventoryService_availabilityApi`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/availability` | Check product and unit availability | Client ID |

> **Note**: The Availability API currently returns `NOT_IMPLEMENTED` but is still part of the public API surface and is registered at bootstrap.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` -- required on all POST and PUT requests
- `Accept: application/json` -- standard response format
- Client identity headers as required by the ClientIdAuthFilter for authentication and authorization

### Error format

> No evidence found in codebase for a specific documented error response schema. Standard Dropwizard/Jersey JSON error responses are expected (HTTP status code with a JSON body). Custom exception mappers are registered at bootstrap to provide consistent error formatting.

### Pagination

> No evidence found in codebase for a specific pagination strategy. List endpoints likely support query parameter-based pagination -- confirm with service owner.

## Rate Limits

> No rate limiting configured. This is an internal Continuum platform service not exposed to public traffic. Access is controlled via client-id-based authentication and authorization.

## Versioning

> No evidence found in codebase for explicit API versioning strategy. The endpoints appear to be unversioned REST resources. Versioning strategy should be confirmed with service owner.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec, proto files, or GraphQL schema committed to this repository. Request/response serialization is handled via Jackson (Dropwizard default) with DTO factories in the Validation & DTO Factories component.
