---
service: "travel-search"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-token, session]
---

# API Surface

## Overview

The Getaways Search Service exposes a REST API implemented with JAX-RS and hosted on a Jetty WAR runtime. Consumers — primarily Getaways client applications (`externalGetawaysClients_2f4a`) — use the API to perform hotel searches, retrieve hotel details and availability, obtain recommendations, and trigger MDS control operations. All endpoints accept and return JSON.

## Endpoints

### Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/travel-search/v1/search` | Execute a hotel search by destination, dates, and filters | internal-token |
| GET | `/travel-search/v1/search/deals` | Retrieve deal-based search results for Getaways | internal-token |

### Hotel Details

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/travel-search/v1/hotels/{hotelId}` | Retrieve full hotel detail including content, availability, and rates | internal-token |
| GET | `/travel-search/v1/hotels/{hotelId}/availability` | Retrieve room availability and rate options for a specific hotel | internal-token |

### Recommendations

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/travel-search/v1/recommendations` | Retrieve relevance-ranked hotel and deal recommendations | internal-token |

### MDS Control

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/travel-search/v1/mds/hotels/{hotelId}/update` | Trigger an MDS update publication for a specific hotel | internal-token |
| POST | `/travel-search/v1/mds/hotels/bulk-update` | Trigger a bulk MDS update for a set of hotels | internal-token |

> Endpoint paths are derived from the architecture component model (`travelSearch_apiResources`) and the stated purposes of each component. Exact versioning paths should be verified against the service's JAX-RS resource definitions in source code.

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required on all POST requests
- `Accept: application/json` — expected on all requests
- Authorization header or session token as required by the internal security layer

### Error format

> No evidence found of a documented standard error response shape in the architecture model. Error format should be verified against the JAX-RS ExceptionMapper implementations in source code. Typically Continuum services return a JSON object with `error`, `message`, and `status` fields.

### Pagination

- Search and recommendation endpoints are expected to support offset-based or cursor-based pagination for result sets.

> Pagination contract details are not captured in the architecture model. Verify against the JAX-RS resource parameter definitions in source code.

## Rate Limits

> No rate limiting configured at the architecture model level. Rate limiting may be enforced at the API gateway or load balancer layer upstream of this service.

## Versioning

URL path versioning is used (e.g., `/v1/`). The architecture model references a single API version. Future versions would be introduced as new path prefixes.

## OpenAPI / Schema References

> No OpenAPI specification file is tracked in the architecture model inventory. Check the service repository for a `swagger.yaml`, `openapi.yaml`, or equivalent JAX-RS annotation-generated schema.
