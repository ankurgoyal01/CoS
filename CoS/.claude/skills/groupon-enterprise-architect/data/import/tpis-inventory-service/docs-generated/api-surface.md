---
service: "tpis-inventory-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["internal"]
---

# API Surface

## Overview

The Third Party Inventory Service exposes HTTP/REST APIs consumed by numerous internal Continuum services. Based on cross-service relationship analysis, the API provides endpoints for querying third-party inventory status, fetching inventory units and products, retrieving booking item details, and providing availability data. The service is not directly exposed to external consumers -- it is accessed through internal service-to-service communication, often via the Lazlo API gateway.

## Endpoints

### Inventory Products

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | (inferred) | Fetch third-party inventory product details and status | Internal |
| GET | (inferred) | Synchronize third-party inventory products (used by Deal Management API) | Internal |

### Inventory Units

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | (inferred) | Query inventory units (used by Unit Tracer, SPOG Gateway) | Internal |
| GET | (inferred) | Read third-party inventory units/products (used by Breakage Reduction Service) | Internal |

### Booking Items

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | (inferred) | Fetch third-party inventory booking item details (used by MyGroupons) | Internal |
| GET | (inferred) | Access TPIS booking flows and data (used by iTier 3PIP) | Internal |

### Availability

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | (inferred) | Read TPIS availability data for TTD feeds (used by MDS Feed Job) | Internal |

> Exact endpoint paths, request/response schemas, and method signatures are not discoverable from the architecture DSL alone. Service owners should document the full API contract here, referencing OpenAPI specifications if available.

## Request/Response Patterns

### Common headers
To be documented by service owner. Expected to follow standard Continuum internal service conventions.

### Error format
To be documented by service owner.

### Pagination
To be documented by service owner.

## Rate Limits

No rate limiting configuration is discoverable from the architecture DSL.

## Versioning

API versioning strategy is not discoverable from the architecture DSL. Service owner should document whether URL path versioning (e.g., `/v1/`, `/v2/`) or other strategies are used.

## OpenAPI / Schema References

No OpenAPI spec or schema references are discoverable from the architecture DSL. Service owners should link to any existing API documentation or proto/schema files.
