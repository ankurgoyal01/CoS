---
service: "coffee-to-go"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

Coffee To Go integrates with 4 external systems and 1 internal system (EDW). The frontend depends on Google Maps for map rendering and Google OAuth for user authentication. The backend validates OAuth tokens with Google. The n8n workflow layer pulls data from Salesforce CRM, the Enterprise Data Warehouse, and competitor feeds from DeepScout via AWS S3.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Maps API | HTTPS | Interactive map rendering and marker display | yes | `googleMaps` |
| Google OAuth 2.0 | OAuth 2.0 | User authentication for Groupon employees | yes | `googleOAuth` |
| Salesforce | REST API | Pull merchant accounts and opportunity data | yes | `salesForce` |
| DeepScout S3 | AWS S3 | Read daily competitor export mapped to Groupon taxonomy | no | `deepScoutS3` |

### Google Maps API Detail

- **Protocol**: HTTPS (Google Maps JavaScript API)
- **Base URL / SDK**: `@googlemaps/react-wrapper` npm package
- **Auth**: API key (injected at build/runtime via `GOOGLE_MAPS_API_KEY`)
- **Purpose**: Renders interactive maps with deal and account markers; supports geospatial visualization of the deals landscape
- **Failure mode**: Map rendering fails; deal data is still accessible via list view
- **Circuit breaker**: No (client-side SDK)

### Google OAuth 2.0 Detail

- **Protocol**: OAuth 2.0 (OpenID Connect)
- **Base URL / SDK**: Better Auth library with Google social provider
- **Auth**: OAuth client ID and secret (`GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`)
- **Purpose**: Authenticates users; only Groupon email domains are allowed. Token validation happens server-side via Better Auth.
- **Failure mode**: Users cannot sign in; existing sessions remain valid until expiry
- **Circuit breaker**: No

### Salesforce Detail

- **Protocol**: REST API
- **Base URL / SDK**: Accessed via n8n workflow connectors
- **Auth**: Configured within n8n workflow credentials
- **Purpose**: Pulls merchant account data and sales opportunity records for ingestion into Coffee DB
- **Failure mode**: Data staleness; existing data remains queryable but will not be updated until the next successful sync
- **Circuit breaker**: No (batch/scheduled)

### DeepScout S3 Detail

- **Protocol**: AWS S3
- **Base URL / SDK**: Accessed via n8n workflow S3 connector with credentials
- **Auth**: AWS S3 credentials configured in n8n
- **Purpose**: Reads daily competitor data export that has been mapped to Groupon's taxonomy structure
- **Failure mode**: Competitor data becomes stale; Groupon-sourced data remains unaffected
- **Circuit breaker**: No (batch/scheduled)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Enterprise Data Warehouse (EDW) | Batch | Pulls reviews and historical deal data for enrichment | `edw` |

### EDW Detail

- **Protocol**: Batch (accessed via n8n workflow connectors)
- **Purpose**: Provides historical deal performance data and review aggregations that are ingested into Coffee DB
- **Failure mode**: Historical and review data becomes stale; core deal data from Salesforce remains unaffected

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known direct consumers:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Sales representatives | HTTPS (browser) | Explore deals and opportunities on maps and lists |
| Administrators | HTTPS (browser) | Manage application settings and content |
| External services | HTTPS (API key) | Programmatic access to deal data |

## Dependency Health

- **Database**: The health service (`/api/health`) performs a `SELECT 1` query and reports response time. Status is `healthy` (<1s), `degraded` (>=1s), or `unhealthy` (error).
- **External data sources** (Salesforce, EDW, DeepScout S3): Health is not monitored directly. The `job_metadata` table tracks n8n workflow execution status and can surface ingestion failures.
- **Google services**: No health check; failures are observable via client-side errors (map not loading, auth failures).
