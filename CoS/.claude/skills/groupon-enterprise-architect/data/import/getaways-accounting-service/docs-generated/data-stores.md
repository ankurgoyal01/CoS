---
service: "getaways-accounting-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "tisPostgres_bf2737"
    type: "postgresql"
    purpose: "Primary read-only source for reservation and transaction data"
  - id: "localCsvStorage"
    type: "local-filesystem"
    purpose: "Temporary staging area for generated CSV and MD5 files before SFTP upload"
---

# Data Stores

## Overview

The Getaways Accounting Service reads reservation data from a shared PostgreSQL database (the TIS Postgres managed by the Travel Itinerary Service). The service does not own its own database schema for reservations — it is a read-only consumer. Generated CSV files are written to a local filesystem staging directory before being uploaded to the SFTP accounting server. No caches or additional data stores are used.

## Stores

### TIS PostgreSQL (`tisPostgres_bf2737`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `tisPostgres_bf2737` |
| Purpose | Primary source of reservation and transaction data for accounting reports and API responses |
| Ownership | external (owned by Travel Itinerary Service) |
| Migrations path | `src/main/resources/db/migrations/` (via jtier-migrations; managed by TIS) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `reservations` | Core reservation records including booking, commit, and cancellation events | `iuid`, `bookingid`, `json`, `reservedat`, `commitsucceeded`, `commitupdatedat`, `cancelledat`, `updatedat` |
| `reservations_id_to_iuid_mapping` | Maps internal numeric IDs to IUID reservation identifiers | `id`, `iuid` |

#### Access Patterns

- **Read**: Queries by record locator (booking ID list) for the finance endpoint; paginated date-range queries for the reservations search endpoint; date-range union queries (committed + cancelled) for CSV generation.
- **Write**: None. The service is read-only against this database.
- **Indexes**: Not directly visible from this service's code; managed by the Travel Itinerary Service.

**Notable query patterns:**
- Finance endpoint: `SELECT ... WHERE bookingid IN (<bookingIds>)` — filters by commit success and non-null commit timestamp.
- Reservations search: Date-range filter across `cancelledat`, `commitupdatedat`, and `reservedat` columns with `LIMIT`/`OFFSET` pagination.
- CSV generation: UNION query selecting COMMITTED (by `commitupdatedat`) and CANCELLED (by `cancelledat`) transactions for a given day, optionally filtered by non-zero `customerPricing.total.amount`.

**Production host:** `getaways-accounting-service-rw-na-production-db.gds.prod.gcp.groupondev.com:5432`
**Staging host:** `getaways-accounting-service-ro-na-staging-db.gds.stable.gcp.groupondev.com:5432`

### Local CSV Filesystem Storage

| Property | Value |
|----------|-------|
| Type | local-filesystem |
| Architecture ref | N/A (ephemeral pod storage) |
| Purpose | Temporary staging for generated CSV and MD5 checksum files before SFTP upload |
| Ownership | owned (ephemeral per pod) |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `getaways_booking_summary_-{date}.csv` | Daily summary CSV report with hotel-level aggregation | Hotel name, address, booking counts, amounts |
| `getaways_booking_detail_-{date}.csv` | Daily detail CSV report with per-reservation lines including `Inventory_Product_UUID` | Booking number, guest info, pricing, custom data |
| `*.md5` | MD5 checksum files for each CSV | Checksum string |

#### Access Patterns

- **Read**: CSV Validator downloads files from SFTP remote and compares against local for integrity checking.
- **Write**: CSV Builder writes generated CSV files; Md5Builder generates corresponding MD5 files.

**Local path (production/staging):** `/var/groupon/jtier/csv`

## Caches

> No evidence found of any caching layer. No Redis, Memcached, or in-memory caches are used.

## Data Flows

1. The Reservation DAO reads from TIS PostgreSQL via JDBI connection pool.
2. The Reservation Repository maps raw `ReservationDBO` records to domain `Reservation` objects.
3. For CSV generation, the CSV Builder writes to the local filesystem pod storage.
4. The File Uploader pushes CSV and MD5 files over SFTP to the accounting server.
5. The CSV Validator re-downloads the uploaded file from SFTP and confirms integrity.
