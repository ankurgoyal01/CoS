---
service: "HotzoneGenerator"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "proximityHotzonePostgres"
    type: "postgresql"
    purpose: "Read weekly consumer IDs for email dispatch (weekly_email run mode only)"
---

# Data Stores

## Overview

HotzoneGenerator does not own any data stores. It reads from one shared PostgreSQL database (the Proximity/ProximityIndexer database) in `weekly_email` run mode only, and all hotzone and campaign state is written to and owned by the Proximity Notifications service via its API. The job itself is stateless between runs.

## Stores

### Proximity Hotzone PostgreSQL (`proximityHotzonePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `proximityHotzonePostgres` (stub — not in federated model) |
| Purpose | Read-only: queries weekly consumer IDs to trigger proximity emails |
| Ownership | shared (owned by Proximity Notifications service) |
| Migrations path | Not applicable — this service does not manage schema migrations |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `proximityindexer.hot_zone_deals` | Stores hotzone deal records indexed for proximity matching | `cat_name`, `audience_id`, `time_window` (referenced in monitoring SQL at `scripts/hotzoneDB.sql`) |
| Weekly consumers table | Stores consumer IDs eligible for weekly email notifications | Consumer UUID (queried via `AppDataConnection.getWeeeklyConsumerIds()`) |

#### Access Patterns

- **Read**: `weekly_email` run mode queries consumer UUIDs via JDBC using `AppDataConnection`. Connection string: `jdbc:postgresql://{postgres.host}/{postgres.database}`.
- **Write**: This service does not write directly to the database. Hotzone records are written by the Proximity Notifications service after receiving the POST from this job.
- **Indexes**: Not visible from this repository.

## Caches

> No evidence found in codebase. This service uses no caching layer.

## Data Flows

- Hotzone records flow: HotzoneGenerator generates in-memory `HotZone` objects, serialises them to JSON, and POSTs to the Proximity Notifications API (`POST hotzone`). The Proximity service writes them to the PostgreSQL store.
- Division coefficients: Loaded from a classpath JSON resource (`gconfig/production.txt` or `gconfig/production-emea.txt`) on each run — no external store read at runtime for this data.
- Hotzone campaign configs: Read from the Proximity Notifications API (`GET hotzone/campaign`) on each run — no local copy persisted.
