---
service: "general-ledger-gateway"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumGeneralLedgerGatewayPostgres"
    type: "postgresql"
    purpose: "Stores invoices, ledger entry mappings, and Quartz scheduler job state"
  - id: "continuumGeneralLedgerGatewayRedis"
    type: "redis"
    purpose: "Caches NetSuite lookup results"
---

# Data Stores

## Overview

GLG owns two data stores: a PostgreSQL database for durable persistence of invoices, ledger entry maps, and Quartz job state; and a Redis cache for short-lived NetSuite lookup results (principally currency records). Both read/write and read-only connection pools are configured against PostgreSQL to allow query isolation.

## Stores

### General Ledger Gateway DB (`continuumGeneralLedgerGatewayPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL 13 |
| Architecture ref | `continuumGeneralLedgerGatewayPostgres` |
| Purpose | Persists invoice records, ledger entry mappings, and Quartz job/trigger state |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migration/` (managed by Flyway 8.0.4) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `invoices` | Stores invoice records forwarded to/from NetSuite | UUID, merchant ID, amount, ledger, status |
| `ledger_entry_maps` | Maps internal invoice UUIDs to NetSuite ledger IDs and tracks payment status | invoice UUID, ledger ID, ledger status (PAID/UNPAID/VOIDED) |
| Quartz tables | Persists Quartz CronScheduler job definitions, triggers, and execution history | job name, trigger data, next fire time |

#### Access Patterns

- **Read**: Invoice lookup by UUID; ledger entry lookup by UUID or `{ledger}/{ledgerID}`; Quartz job store reads on scheduler tick
- **Write**: Invoice records created on `PUT /v1/invoices/{ledger}/send`; ledger entry maps written by Applied Invoice Service during job execution; Quartz state updated on job schedule/completion
- **Indexes**: Not visible from source; migration scripts managed by Flyway

#### Connection Pool Configuration (Production)

| Parameter | Read/Write Pool | Read-Only Pool |
|-----------|----------------|----------------|
| Min connections | 8 | 8 |
| Max connections | 32 | 32 |
| Max wait | 1s | 1s |
| Validation query | `SELECT 1` | `SELECT 1` |
| Eviction interval | 10s | 10s |

Production RW endpoint: `gds-general-ledger-gway-rw.prod.us-west-1.aws.groupondev.com/general_ledger_gateway_prod`
Production RO endpoint: `gds-general-ledger-gway-ro.prod.us-west-1.aws.groupondev.com/general_ledger_gateway_prod`

---

### General Ledger Gateway Redis Cache (`continuumGeneralLedgerGatewayRedis`)

| Property | Value |
|----------|-------|
| Type | Redis 6.2.6 |
| Architecture ref | `continuumGeneralLedgerGatewayRedis` |
| Purpose | Caches NetSuite currency records to reduce repeated RESTlet calls |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `NetSuiteCurrency` | Cached currency data returned by NetSuite | Internal ID, currency code, symbol, numeric code |

#### Access Patterns

- **Read**: Cache lookup before each NetSuite currency fetch; returns cached value if present
- **Write**: Successful NetSuite currency responses are stored in cache after retrieval

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumGeneralLedgerGatewayRedis` | Redis | NetSuite currency lookup cache | Not explicitly configured (default Lettuce behavior) |

## Data Flows

Invoice data originates from Accounting Service calls into GLG, is persisted in PostgreSQL, and simultaneously forwarded to NetSuite. Applied invoice data flows in reverse: the Import Applied Invoices Job downloads applied credit records from NetSuite saved searches, processes them through Applied Invoice Service, and calls Accounting Service to record the application, with ledger entry map records updated in PostgreSQL throughout.
