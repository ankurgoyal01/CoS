---
service: "channel-manager-integrator-travelclick"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumChannelManagerIntegratorTravelclickMySql"
    type: "mysql"
    purpose: "Persistence for reservation, cancellation, request, and response records"
---

# Data Stores

## Overview

The service owns a single MySQL database accessed via the JTier DaaS (Database-as-a-Service) layer using JDBI DAOs. The database persists reservation and cancellation records, TravelClick OTA request/response logs, and ARI-related data received from TravelClick push endpoints. Schema migrations are managed through `jtier-migrations`.

## Stores

### Channel Manager Integrator TravelClick MySQL (`continuumChannelManagerIntegratorTravelclickMySql`)

| Property | Value |
|----------|-------|
| Type | MySQL 5.6 |
| Architecture ref | `continuumChannelManagerIntegratorTravelclickMySql` |
| Purpose | Persistence for reservation, cancellation, TravelClick request/response records, and ARI data |
| Ownership | owned |
| Migrations path | `jtier-migrations` (managed via JTier migration tooling) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Reservation records | Stores Groupon reservation payloads submitted to TravelClick | Reservation ID, hotel code, status, timestamps |
| Cancellation records | Stores cancellation requests and outcomes | Cancellation ID, reservation reference, status, timestamps |
| TravelClick request log | Audit log of all OTA XML requests sent to TravelClick | Request ID, endpoint, payload, timestamp |
| TravelClick response log | Audit log of TravelClick OTA XML responses | Request ID, response code, payload, timestamp |

> Specific table names are not present in the committed codebase (source files are not in the import-repos snapshot). Schema details are managed via migration scripts in the JTier migrations module.

#### Access Patterns

- **Read**: The MBus consumer reads existing reservation records before issuing TravelClick requests to avoid duplicates; the API controllers read reservation data for response construction
- **Write**: The MBus consumer writes new reservation and cancellation records; the TravelClick client writes request/response audit records after each outbound OTA call
- **Indexes**: Not visible from available inventory; managed by migration scripts

## Caches

> No evidence found in codebase of any cache layer (Redis, Memcached, or in-memory cache).

## Data Flows

MySQL is the single store for this service. Data flows are:

1. MBus consumer receives reservation/cancellation event -> writes reservation record to MySQL -> calls TravelClick -> writes request/response log to MySQL
2. API controller receives ARI push from TravelClick -> validates payload -> writes ARI data to MySQL -> publishes to Kafka

There is no CDC, ETL, or replication visible in the available inventory. The database is initialized via `script/db/db-init.sql` which creates the `cmi_travelclick_development` and `cmi_travelclick_test` schemas for local/CI use.
