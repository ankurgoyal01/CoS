---
service: "coffee-to-go"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Supply / Deal Alerts"
platform: "Continuum"
team: "Coffee To Go Team"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.9"
  framework: "Express 5 / React 19"
  framework_version: "5.1 / 19.2"
  runtime: "Node.js"
  runtime_version: "22"
  build_tool: "Vite / tsx"
  package_manager: "npm"
---

# Coffee To Go Overview

## Purpose

Coffee To Go is a full-stack web application designed for Groupon employees -- primarily sales representatives and administrators -- to track live deals, merchant accounts, opportunities, and competitor activity in specific geographic areas. It aggregates data from Salesforce CRM, the Enterprise Data Warehouse (EDW), and competitor feeds (DeepScout S3) into a single interface with interactive maps, list views, and spatial search. The service exists to give supply-side teams rapid visibility into the deals landscape so they can prioritize merchant outreach and identify coverage gaps.

## Scope

### In scope

- Interactive map-based and list-based exploration of Groupon deals and merchant accounts
- Location-based spatial search with configurable radius
- Filtering by category, vertical, stage, activity, priority, owner type, taxonomy group, and primary deal service
- Full-text search across merchant names, deal names, categories, tags, and boost summaries
- Usage tracking and analytics for internal adoption metrics
- Authentication and authorization restricted to Groupon employees via Google OAuth
- API key management for service-to-service access
- n8n workflow-driven data ingestion from Salesforce, EDW, and DeepScout S3

### Out of scope

- Deal creation or editing (managed in Salesforce and other Continuum systems)
- Consumer-facing deal browsing (handled by MBNXT and other consumer apps)
- Payment processing and order management
- Merchant onboarding workflows

## Domain Context

- **Business domain**: Supply / Deal Alerts
- **Platform**: Continuum
- **Upstream consumers**: Sales representatives (via browser), administrators (via browser), external systems (via API key)
- **Downstream dependencies**: Salesforce (accounts/opportunities), EDW (reviews/historical deals), DeepScout S3 (competitor data), Google Maps API (map rendering), Google OAuth (authentication)

## Stakeholders

| Role | Description |
|------|-------------|
| Sales Representative | Primary user; explores deals, accounts, and opportunities on maps and lists to guide outreach |
| Administrator | Manages settings, content, and user access for the application |
| Coffee To Go Team | Develops and operates the service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9 | `package.json` (root, api, react) |
| Framework (API) | Express | 5.1 | `apps/coffee-api/package.json` |
| Framework (Web) | React | 19.2 | `apps/coffee-react/package.json` |
| Runtime | Node.js | 22 | `Dockerfile` (node:22-alpine), `apps/coffee-react/package.json` (engines) |
| Build tool (Web) | Vite | 7.2 | `apps/coffee-react/package.json` |
| Build tool (API) | tsx | 4.20 | `apps/coffee-api/package.json` |
| Package manager | npm | | `package-lock.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Kysely | 0.28 | orm | Type-safe SQL query builder for PostgreSQL |
| pg | 8.16 | db-client | PostgreSQL client driver with connection pooling |
| Better Auth | 1.2+ | auth | Authentication framework with Google OAuth, session management, and API key plugins |
| Pino | 9.7 | logging | Structured JSON logging with HTTP request logging (pino-http) |
| pino-sentry-transport | 1.5 | logging | Forwards errors to Sentry for production error tracking |
| Zod | 4.0 | validation | Schema validation for API request parameters |
| express-rate-limit | 7.5 | http-framework | Request rate limiting and throttling |
| Helmet | 8.1 | http-framework | HTTP security headers |
| swagger-jsdoc / swagger-ui-express | 6.2 / 5.0 | http-framework | OpenAPI documentation generation and Swagger UI |
| @cacheable/node-cache | 1.7 | db-client | In-memory caching with TTL support |
| TanStack Router | 1.134 | ui-framework | Type-safe client-side routing |
| TanStack Query | 5.90 | ui-framework | Server state management, caching, and data fetching |
| Zustand | 5.0 | state-management | Lightweight client-side state management |
| Material-UI | 7.3 | ui-framework | React UI component library with theming |
| @googlemaps/react-wrapper | 1.2 | ui-framework | Google Maps integration for React |
| react-geolocated | 4.4 | ui-framework | Browser geolocation API wrapper |
| Vitest | 4.0 | testing | Test runner with coverage support |
| dbmate | 2.27 | db-client | Database migration tool |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
