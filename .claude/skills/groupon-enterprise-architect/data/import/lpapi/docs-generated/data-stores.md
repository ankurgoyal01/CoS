---
service: "lpapi"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumLpapiPrimaryPostgres"
    type: "postgresql"
    purpose: "Primary read/write datastore for all LPAPI entities"
  - id: "continuumLpapiReadOnlyPostgres"
    type: "postgresql"
    purpose: "Read replica for read-heavy query paths"
---

# Data Stores

## Overview

LPAPI owns a PostgreSQL primary/replica pair within the Continuum Platform. The primary database (`continuumLpapiPrimaryPostgres`) handles all writes from the API process and both background workers. The read-only replica (`continuumLpapiReadOnlyPostgres`) serves read-heavy query paths from the API process and the Auto Indexer worker. There are no caches or secondary data stores.

## Stores

### LPAPI Primary Postgres (`continuumLpapiPrimaryPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumLpapiPrimaryPostgres` |
| Purpose | Primary read/write datastore for landing page entities, routes, crosslinks, attribute types, locations, divisions, auto-index jobs/results, and UGC review records |
| Ownership | owned |
| Migrations path | > No evidence found — managed within service repository |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Landing pages | Core SEO landing page records | page ID, URL path, locale, division, taxonomy category |
| Routes | URL-to-page route mappings | route path, page ID, site/locale context |
| Crosslinks | Related-page link relationships | source page ID, target page ID, link text |
| Attribute types | Typed metadata attributes for pages | attribute ID, name, type, autocomplete index |
| Locations | Geographic location hierarchy | location ID, name, parent location ID |
| Divisions | Groupon division/site hierarchy | division ID, name, locale, parent division ID |
| Auto-index jobs | Scheduled analysis job records | job ID, status, created/updated timestamps, config snapshot |
| Auto-index results | Indexability analysis outcomes per page | result ID, job ID, page ID, index recommendation, signals |
| UGC reviews | Normalized merchant review payloads | review ID, merchant ID, page ID, rating, text, source metadata |

#### Access Patterns

- **Read**: API process reads page, route, crosslink, and attribute records on every API request; Auto Indexer reads page/route metadata before each analysis run
- **Write**: API process writes on all create/update/delete operations; Auto Indexer writes job state and analysis results; UGC Worker upserts normalized review records after each sync cycle
- **Indexes**: JSONB expression support (via JSONB Expressions library) suggests indexed JSONB columns on page attribute storage; specific index definitions are in the service repository migrations

---

### LPAPI Read-Only Postgres (`continuumLpapiReadOnlyPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumLpapiReadOnlyPostgres` |
| Purpose | Read replica for routing/search state lookups and analysis inputs |
| Ownership | owned |
| Migrations path | > Not applicable — replica of primary |

#### Key Entities

Mirrors `continuumLpapiPrimaryPostgres` via PostgreSQL streaming replication.

#### Access Patterns

- **Read**: `continuumLpapiApp` reads routing and search state (route lookups, page resolution); `continuumLpapiAutoIndexer` reads pages and routes as analysis inputs
- **Write**: Read-only — no writes permitted
- **Indexes**: Inherits all indexes from primary

## Caches

> No evidence found. No in-memory or distributed cache layer is modeled.

## Data Flows

1. All write operations from `continuumLpapiApp`, `continuumLpapiAutoIndexer`, and `continuumLpapiUgcWorker` target `continuumLpapiPrimaryPostgres` via JDBC.
2. PostgreSQL streaming replication propagates writes to `continuumLpapiReadOnlyPostgres`.
3. Read-heavy paths in `continuumLpapiApp` (routing resolution) and `continuumLpapiAutoIndexer` (page analysis inputs) are directed to the read replica to reduce load on the primary.
