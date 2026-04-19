---
service: "seo-admin-ui"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 7
---

# Integrations

## Overview

seo-admin-ui integrates with one external system (Google Search Console API) and seven internal Continuum services. All integrations are synchronous HTTP/GraphQL calls initiated by the admin UI in response to operator actions. The service uses dedicated client libraries for LPAPI and Deal Catalog GraphQL; other integrations use standard HTTP clients provided by the I-Tier framework.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Search Console API | rest | Retrieve indexing status and coverage data for Groupon pages | yes | > No Structurizr ID in inventory. |

### Google Search Console API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Google Search Console REST API v1 (OAuth 2.0 authenticated)
- **Auth**: OAuth 2.0 service account credentials managed via keldor-config / secrets
- **Purpose**: Provides indexing coverage, crawl error data, and search performance signals used in the auto-index worker and page route auditing flows
- **Failure mode**: Degraded — auto-index worker and auditing features become unavailable; manual SEO admin operations continue unaffected
- **Circuit breaker**: > No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| LPAPI | rest | CRUD operations on landing page routes | > No Structurizr ID in inventory. |
| Deal Catalog (GAPI) | graphql | Query deal data for SEO deal attribute management | > No Structurizr ID in inventory. |
| SEO Deal API | rest | Manage SEO-specific deal page attributes | > No Structurizr ID in inventory. |
| MECS (content service) | rest | Read content metadata for SEO task creation | > No Structurizr ID in inventory. |
| SEO Checkoff Service | rest | Submit and track SEO task checkoffs | > No Structurizr ID in inventory. |
| Keyword KB API | rest | Query keyword knowledge base for SEO recommendations | > No Structurizr ID in inventory. |
| Neo4j (SEO) | bolt | Read page ranking and crosslinks graph | `neo4jSeo` |

### LPAPI Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: `@grpn/lpapi-client` 1.9.18
- **Auth**: I-Tier service-to-service auth
- **Purpose**: Primary data source for landing page route management; all landing page CRUD operations route through LPAPI
- **Failure mode**: Landing page management features unavailable
- **Circuit breaker**: > No evidence found in codebase.

### Deal Catalog (GAPI) Detail

- **Protocol**: GraphQL / HTTP
- **Base URL / SDK**: `@grpn/graphql-gapi` 5.2.9
- **Auth**: I-Tier service-to-service auth
- **Purpose**: Supplies deal data (titles, categories, pricing) for populating SEO deal pages
- **Failure mode**: SEO deal management features unavailable
- **Circuit breaker**: > No evidence found in codebase.

## Consumed By

> Upstream consumers are tracked in the central architecture model. seo-admin-ui is an internal admin UI accessed directly by SEO engineers and content operators via browser.

## Dependency Health

> No evidence found in codebase. Health check and retry patterns for dependencies are managed by the I-Tier framework defaults and keldor-config timeout settings. Refer to the [Runbook](runbook.md) for dependency failure guidance.
