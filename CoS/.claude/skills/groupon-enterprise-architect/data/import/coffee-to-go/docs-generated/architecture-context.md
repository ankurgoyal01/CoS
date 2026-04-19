---
service: "coffee-to-go"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["coffeeApi", "coffeeWeb", "coffeeWorkflows", "coffeeDb"]
---

# Architecture Context

## System Context

Coffee To Go is part of the Continuum Platform -- Groupon's core commerce engine. It serves as a supply-side intelligence tool that sits at the intersection of CRM data (Salesforce), historical deal analytics (EDW), and competitor intelligence (DeepScout S3). Sales representatives and administrators interact with the application through a React web frontend, which communicates with an Express API backend. Data is ingested and enriched by n8n ETL workflows that run on a schedule, writing pre-aggregated data into a PostgreSQL database. The API reads from this pre-aggregated data (materialized views with spatial indexing) to serve fast, location-based queries.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| React Web Application | `coffeeWeb` | WebApp | React 19, TypeScript, Material-UI | Single Page Application for viewing deals on maps and lists |
| Express API | `coffeeApi` | Backend | Node.js, Express 5, TypeScript | RESTful API server providing deals, health, and tracking endpoints |
| n8n Workflows | `coffeeWorkflows` | Backend | n8n | ETL/ELT workflows aggregating from CRM, competitor feeds, and internal systems; writes to Coffee DB |
| Coffee DB | `coffeeDb` | Database | PostgreSQL 15+ | Stores accounts, opportunities, deals, and usage events |

## Components by Container

### React Web Application (`coffeeWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Router | Handles client-side routing and navigation | TanStack Router |
| Query Client | Manages server state, caching, and data fetching | TanStack Query |
| Auth Client | Handles user authentication and session management | Better Auth Client |
| State Store | Manages local application state (filters, UI state, feature flags) | Zustand |
| Deals Map | Interactive map component displaying deals and opportunities | Google Maps React Wrapper |
| Deals List | List view component for displaying deals with filtering | React Components |
| Deals Sidebar | Sidebar component for filters and controls | React Components |
| Deals Modal | Modal component for displaying deal details | React Components |
| API Client | HTTP client for making API requests | Fetch API |
| Geolocation Provider | Provides user location services | React Geolocated |
| Device Provider | Detects and provides device information | React Components |
| Layout | Main application layout with navigation | Material-UI |
| Auth Components | Login and authentication UI components | React Components |
| Stats Components | Usage statistics and analytics components | React Components |
| Tracking Components | User interaction tracking components | React Components |

### Express API (`coffeeApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Express Application | Main Express application setup and configuration | Express 5 |
| Routes | Route definitions and endpoint handlers | Express Router |
| Deals Routes | Deals endpoint routes (/api/deals) | Express Router |
| Tracking Routes | Usage tracking endpoint routes (/api/usage) | Express Router |
| Health Routes | Health check endpoints (/api/health, /api/livez) | Express Router |
| Deals Controller | Handles deals API requests and responses | Express Controllers |
| Tracking Controller | Handles usage tracking requests | Express Controllers |
| Health Controller | Handles health check requests | Express Controllers |
| Deals Service | Business logic for deals queries and filtering | TypeScript Services |
| Tracking Service | Business logic for usage event processing | TypeScript Services |
| Health Service | Health check and system status logic | TypeScript Services |
| Config Service | Application configuration management | TypeScript Services |
| Auth Middleware | Authentication and authorization middleware | Better Auth, Express |
| CORS Middleware | Cross-origin resource sharing configuration | CORS |
| Rate Limiting Middleware | Request rate limiting and throttling | express-rate-limit |
| Error Handler Middleware | Global error handling and logging | Express |
| Logging Middleware | HTTP request/response logging | Pino |
| Feature Flag Middleware | Feature flag injection and management | Express |
| Database Access | Database connection and query builder | Kysely ORM |
| Swagger Documentation | API documentation and OpenAPI spec | swagger-jsdoc, swagger-ui-express |
| Cache | In-memory caching for frequently accessed data | node-cache |
| Logger | Structured logging service | Pino |

### n8n Workflows (`coffeeWorkflows`)

> No internal components documented yet. Workflows aggregate data from Salesforce, EDW, and DeepScout S3, writing enriched datasets into Coffee DB.

### Coffee DB (`coffeeDb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| accounts | Stores account/merchant information with location data | PostgreSQL Table |
| opportunities | Stores opportunity data linked to accounts | PostgreSQL Table |
| deal_details | Stores deal information and status | PostgreSQL Table |
| redemption_locations | Stores geographic locations for deal redemption | PostgreSQL Table |
| prospects | Stores competitor/prospect data | PostgreSQL Table |
| reviews | Stores review data from external sources | PostgreSQL Table |
| account_reviews | Aggregated review data per account | PostgreSQL Table |
| usage_events | Stores user interaction and usage tracking events | PostgreSQL Table |
| job_metadata | Tracks n8n workflow job status and progress | PostgreSQL Table |
| pds_tg_map | Maps Primary Deal Services to Taxonomy Groups | PostgreSQL Table |
| auth_user | User authentication and profile data | PostgreSQL Table |
| auth_session | User session management | PostgreSQL Table |
| auth_api_key | API key management for service-to-service access | PostgreSQL Table |
| mv_deals_cache_v6 | Materialized view for optimized deal queries with spatial indexing | PostgreSQL Materialized View |
| v_deals_cache_dev | Development version of deals cache view | PostgreSQL View |
| refresh_deals_cache() | Function to refresh materialized view | PostgreSQL Function |
| get_deals_cache_stats() | Function to get cache statistics | PostgreSQL Function |
| update_location_geography() | Trigger function to update geography columns | PostgreSQL Function |
| update_billing_location_geography() | Trigger function for account billing locations | PostgreSQL Function |
| update_last_updated_at() | Trigger function to update timestamp columns | PostgreSQL Function |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `salesRep` | `coffeeWeb` | Explores opportunities map (accounts, deals, competitors, history) | HTTPS |
| `administrator` | `coffeeWeb` | Manages the settings and content | HTTPS |
| `coffeeWeb` | `coffeeApi` | Makes API calls for deals, tracking, and health data | HTTPS, JSON |
| `coffeeWeb` | `googleMaps` | Displays maps and markers | HTTPS |
| `coffeeWeb` | `googleOAuth` | Authenticates users | OAuth 2.0 |
| `coffeeApi` | `coffeeDb` | Reads and writes data | PostgreSQL |
| `coffeeApi` | `googleOAuth` | Validates OAuth tokens | HTTPS |
| `coffeeWorkflows` | `coffeeDb` | Writes enriched datasets | SQL/Bulk |
| `coffeeWorkflows` | `salesForce` | Pulls accounts and opportunities | REST API |
| `coffeeWorkflows` | `edw` | Pulls reviews and historical deal data | Batch |
| `coffeeWorkflows` | `deepScoutS3` | Reads daily competitor export (mapped to Groupon taxonomy) | AWS S3 |

## Architecture Diagram References

- Component (API): `coffeeApiComponents-continuum-coffee-api`
- Component (Web): `coffeeAuthComponents-continuum-coffee-web`
