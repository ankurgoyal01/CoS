---
service: "bookability-dashboard"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gcs-static-hosting"
    type: "google-cloud-storage"
    purpose: "Static SPA asset hosting"
  - id: "in-memory-cache"
    type: "in-memory"
    purpose: "Runtime data caching in browser"
---

# Data Stores

## Overview

The Bookability Dashboard owns no persistent database. It is a stateless SPA whose build artifacts are hosted in Google Cloud Storage buckets and delivered via Google Cloud CDN. All application state is held in-memory in the browser and discarded on page reload. Caching is implemented at the JavaScript service layer to reduce API call frequency during a session.

## Stores

### Google Cloud Storage — Static Hosting (`gcs-static-hosting`)

| Property | Value |
|----------|-------|
| Type | Google Cloud Storage |
| Architecture ref | `continuumBookabilityDashboardWeb` |
| Purpose | Hosts compiled SPA assets (HTML, JS, CSS, `env-config.js`) for each region and environment |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Bucket | Purpose | Key Files |
|--------|---------|-----------|
| `gs://bookability-dashboard-web-stable-us-central1/` | Staging (US) static file serving | `index.html`, `env-config.js`, `assets/` |
| `gs://bookability-dashboard-web-stable-europe-west1/` | Staging (EU) static file serving | `index.html`, `env-config.js`, `assets/` |
| `gs://bookability-dashboard-web-prod-us-central1/` | Production (US) static file serving | `index.html`, `env-config.js`, `assets/` |
| `gs://bookability-dashboard-web-prod-europe-west1/` | Production (EU) static file serving | `index.html`, `env-config.js`, `assets/` |
| `gs://bookability-web-builds/book-dash/` | Build artifact storage (zip archives per git SHA) | `book-dash-{version}.zip` |

#### Access Patterns

- **Read**: GCP Cloud CDN reads from buckets on cache miss; users receive static files via CDN
- **Write**: CI/CD pipeline (Jenkins deploy stage) uploads new build artifacts and invalidates CDN cache after each deployment
- **Indexes**: Not applicable (GCS object storage)

### In-Memory Cache (`in-memory-cache`)

| Property | Value |
|----------|-------|
| Type | In-memory (JavaScript class-level static variables in `DataService`) |
| Architecture ref | `bookDash_partnerServiceClient` |
| Purpose | Reduces redundant API calls during a browser session |
| Ownership | owned (runtime only, discarded on page reload) |
| Migrations path | Not applicable |

#### Key Entities

| Cache | Purpose | Key Fields |
|-------|---------|-----------|
| Partner data cache (per partner) | Caches merchant and deal data fetched per partner | Keyed by partner name |
| Health check data cache | Caches preloaded health-check logs for all deals | Keyed by deal ID |
| Enriched data cache | Caches the fully enriched merchants + deals result | Single global entry |
| Partner configurations cache | Caches the list of active partner configs from API | Single global list |
| Request deduplication cache (health logs) | Deduplicates in-flight page requests for health logs | Keyed by sorted acquisition method IDs + time range |

#### Access Patterns

- **Read**: `DataService` static methods check cache before making API calls
- **Write**: Populated after successful API responses; cleared on manual refresh or TTL expiry

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Partner data (per partner) | in-memory | Merchant and deal data per booking platform | 5 minutes (300,000 ms) |
| Health check data | in-memory | Deal health check log data for all active deals | 10 minutes (600,000 ms) |
| Enriched data | in-memory | Fully enriched merchant + deal relationships | 5 minutes (300,000 ms) |
| Partner configurations | in-memory | Active partner names and acquisition method IDs | 5 minutes (300,000 ms) |

## Data Flows

All persistent data originates in `continuumPartnerService` (its database and integrations). The dashboard reads data from Partner Service via REST, enriches it client-side, and caches it in memory for the duration of the session. No data flows from the dashboard back to a store other than investigation records written through `continuumPartnerService` via the investigation API endpoints.
