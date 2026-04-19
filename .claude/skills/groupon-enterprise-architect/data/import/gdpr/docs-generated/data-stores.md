---
service: "gdpr"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "os-temp-filesystem"
    type: "local-filesystem"
    purpose: "Ephemeral staging area for CSV files and ZIP archives during export"
---

# Data Stores

## Overview

The GDPR service is effectively stateless with respect to persistent data ownership. It does not own a database, cache, or external object store. The only storage it uses is the operating system temporary directory (`os.TempDir()`), which serves as a transient staging area during the export assembly process. All staged files are deleted immediately after the ZIP archive has been delivered to the requesting agent.

## Stores

### OS Temp Directory (`os-temp-filesystem`)

| Property | Value |
|----------|-------|
| Type | local-filesystem (ephemeral) |
| Architecture ref | `continuumGdprService` (internal to container) |
| Purpose | Staging area for per-consumer CSV files and the assembled ZIP archive during a single export request |
| Ownership | owned (ephemeral, per-request) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `{consumerUuid}/` directory | Per-request staging directory under `os.TempDir()` | `consumer_uuid` |
| `{consumerUuid}-Orders.csv` | Consumer order history | Purchase date, Groupon ID, expiration, redemption status, order status, amounts, deal title, shipping details |
| `{consumerUuid}-Preference_Center.csv` | Consumer interest category preferences (liked items only) | Selected interest category |
| `{consumerUuid}-Subscriptions.csv` | Consumer email/notification subscriptions | Subscribed category or city, subscription type, status |
| `{consumerUuid}-Reviews.csv` | User-generated reviews enriched with place/merchant data | Date, rating, review text, question type, survey type, merchant name, city |
| `{consumerUuid}-Addresses.csv` | Consumer profile address locations | Name, street, city, state, district, post code, country |
| `{consumerUuid}.zip` | ZIP archive of all CSV files, staged in `os.TempDir()` before delivery | All CSV files above |

#### Access Patterns

- **Read**: Files are read once during ZIP packaging via the `zipExporter` component
- **Write**: Each data collector writes one CSV file to the staging directory after fetching data from its upstream service
- **Indexes**: Not applicable (flat file system)

## Caches

> No evidence found in codebase. No caching layer is used. Each export request results in fresh API calls to all downstream services.

## Data Flows

All data flows are ephemeral and bounded to the lifetime of a single export request:

1. Each collector fetches data from its upstream service API and writes one CSV file to `os.TempDir()/{consumerUuid}/`
2. The ZIP exporter reads all CSV files in the staging directory and assembles a single ZIP archive in `os.TempDir()/`
3. The ZIP archive is streamed to the agent's browser via HTTP and emailed via SMTP
4. The staging directory (`cleanUp`) and ZIP file (`cleanupZip`) are deleted immediately after delivery

No data persists beyond the lifetime of a single request.
