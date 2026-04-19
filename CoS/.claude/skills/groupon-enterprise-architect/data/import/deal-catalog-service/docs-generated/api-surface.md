---
service: "deal-catalog-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: ["rest"]
auth_mechanisms: ["internal-network"]
---

# API Surface

## Overview

The Deal Catalog Service exposes REST APIs for managing and retrieving deal merchandising metadata. The API is consumed by a wide range of internal services across the Continuum Platform, including the consumer-facing Lazlo API gateway, multiple inventory services, the Online Booking API, and Travel Affiliates. Inbound deal data is pushed from Salesforce via REST integrations. All endpoints are internal-only and communicate over Groupon's internal network.

## Endpoints

### Deal Metadata (Inferred from Architecture)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deals/{dealId}` | Retrieve deal metadata by ID (titles, categories, availability, merchandising attributes) | Internal network |
| GET | `/deals` | Query deals by filter criteria (category, availability, region) | Internal network |
| POST | `/deals` | Create or register deal metadata (called by Deal Management API / Salesforce integration) | Internal network |
| PUT | `/deals/{dealId}` | Update deal metadata (title, category, availability, merchandising attributes) | Internal network |
| GET | `/deals/{dealId}/catalog-attributes` | Retrieve deal catalog attributes for booster mappings (consumed by S2S Service) | Internal network |
| GET | `/deals/active` | Retrieve active deal UUIDs and distribution regions (consumed by Travel Affiliates) | Internal network |

> Exact endpoint paths are inferred from architecture relationships and consumer usage patterns. No OpenAPI spec was found in the codebase.

### Salesforce Integration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/integration/salesforce/deals` | Receive deal metadata push from Salesforce (title, category, availability) | REST / Integration |

> Salesforce pushes deal metadata into the Catalog API component (`dealCatalog_api`) via a REST integration channel.

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Standard JTier services typically use `Content-Type: application/json`, `Accept: application/json`, and internal service authentication headers.

### Error format

> No evidence found in codebase. JTier/Dropwizard services typically return JSON error responses with `code`, `message`, and `details` fields.

### Pagination

> No evidence found in codebase. List endpoints likely support offset/limit or cursor-based pagination consistent with JTier conventions.

## Rate Limits

> No evidence found in codebase. Rate limiting may be handled at the API gateway (Akamai / API Proxy) layer rather than within the service itself.

## Versioning

> No evidence found in codebase. JTier services at Groupon typically use URL path-based versioning (e.g., `/v1/deals`).

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or schema definitions were found in the architecture repository. The service is a DSL-only definition without source code access.
