---
service: "seo-deal-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumSeoDealPostgres"
    type: "postgresql"
    purpose: "Stores SEO deal data, redirects, queues, and history"
---

# Data Stores

## Overview

SEO Deal API owns a single PostgreSQL database (`continuumSeoDealPostgres`) as its primary data store. All SEO deal attributes, redirect mappings, redirect history, and URL removal request state are persisted here. The service has no caches or secondary stores identified in the architecture model. Reads and writes are handled by the `seoDataDao` component using JDBI.

## Stores

### SEO Deal Database (`continuumSeoDealPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumSeoDealPostgres` |
| Purpose | Stores SEO deal data, redirects, queues, and history |
| Ownership | owned |
| Migrations path | Not specified in available source evidence |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| SEO deal attributes | Per-deal SEO metadata including canonical URL, redirect URL, noindex flag, brand, title overrides | `deal_id` (UUID), `redirect_url`, `canonical_url`, `noindex`, `attributes` (JSON) |
| Redirect mappings | Maps expired deal UUIDs to live deal URLs for HTTP redirect resolution | `expired_uuid`, `expired_deal_permalink`, `live_deal_url`, `changed_by`, `changed_at` |
| Processed redirect history | Historical record of redirect changes for audit and query | `redirect_from`, `redirect_to`, `changed_by`, `changed_at` |
| URL removal requests | Tracks URL removal workflow state: pending, approved, rejected | `request_id`, `requested_by`, `status`, `observation`, `urls` |
| Redirect queue | Queue of pending redirect operations to be processed | Not fully specified in available evidence |

#### Access Patterns

- **Read**: Fetch SEO attributes by deal UUID (`/seodeals/deals/{dealId}`); paginated redirect history queries filtered by date range, changed-by user, and redirect source URL (`/seodeals/redirects/processed`); URL removal request searches by status and requestor
- **Write**: Insert or update deal SEO attributes on canonical edits, attribute updates, and noindex changes; bulk-insert redirect mappings from the seo-deal-redirect pipeline (up to 1250 PUT calls per minute); insert URL removal requests; update URL removal request status
- **Indexes**: Not specified in available source evidence; pagination and date-range queries on redirect history suggest indexes on `changed_at` and `expired_uuid`

## Caches

> No evidence found in codebase.

No caching layer (Redis, Memcached, or in-memory) was identified in the architecture model for seo-deal-api.

## Data Flows

All data flows through the `SEO Data DAO` component which intermediates between the `Orchestrator` / `API Resources` components and the PostgreSQL database. The `seo-deal-redirect` Airflow pipeline writes redirect mappings via direct HTTP PUT to the API, which persists them to the database. The `seo-admin-ui` reads and writes deal attributes via the REST API layer. The `ingestion-jtier` pipeline writes noindex flags via PUT to `/seodeals/deals/{dealId}/edits/noindex`.
