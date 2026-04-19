---
service: "accounting-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAccountingMysql"
    type: "mysql"
    purpose: "Primary relational datastore for all accounting domain entities"
  - id: "continuumAccountingRedis"
    type: "redis"
    purpose: "Resque job queue, distributed locks, and application cache"
---

# Data Stores

## Overview

Accounting Service owns two data stores: a MySQL database as its primary relational store for all accounting domain data, and a Redis instance used for Resque background job queuing, distributed locking, and application-level caching. The MySQL database is accessed via ActiveRecord with the `ar-octopus` gem providing database sharding and read/write splitting capabilities.

## Stores

### Accounting MySQL (`continuumAccountingMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumAccountingMysql` |
| Purpose | Primary relational datastore for accounting entities and workflows |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `contracts` | Merchant contracts imported from Salesforce | contract_id, vendor_id, deal_ids, payment_terms, effective_date, status |
| `invoices` | Generated invoices for merchant payment cycles | invoice_id, vendor_id, contract_id, amount, currency, status, period |
| `transactions` | Individual financial transaction records | transaction_id, vendor_id, invoice_id, amount, currency, type, created_at |
| `payments` | Merchant payment run records | payment_id, vendor_id, amount, currency, status, payment_date |
| `vendors` | Vendor/merchant master records | vendor_id, merchant_id, name, payment_method, status |
| `statements` | Periodic financial statements for vendors | statement_id, vendor_id, period, amount, generated_at |

#### Access Patterns

- **Read**: Vendor and merchant APIs query by vendor_id and merchant_id; statement and transaction list endpoints use date-range and status filters; contract import reads existing contracts to detect updates
- **Write**: Contract import pipeline writes new and updated contract records; ingestion workers write transaction entries; payment engine writes payment and invoice records; papertrail gem appends version records for all audited models
- **Indexes**: No index details discoverable from the architecture inventory; confirm with service owner via ActiveRecord schema files

### Accounting Redis (`continuumAccountingRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumAccountingRedis` |
| Purpose | Resque job queue, distributed locks, and application cache |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Background job queuing for ingestion, payment, and reporting workers | queue name, job class, arguments, enqueued_at |
| Resque failed queue | Accumulates failed jobs for investigation and re-enqueue | job class, error, failed_at, backtrace |
| Distributed locks | Prevent concurrent execution of critical payment and import jobs | lock key, TTL |
| Application cache | Caches frequently read reference data (deal metadata, vendor records) | cache key, value, TTL |

#### Access Patterns

- **Read**: Workers pop jobs from Resque queues; application reads cached values via `dalli` client
- **Write**: Service enqueues jobs via Resque API; cache writes on cache miss; lock acquisition before critical job execution
- **Indexes**: Not applicable (Redis key-value store)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Resque job queue | redis | Background job queue for `continuumAccountingRedis` | Until consumed |
| Application cache (dalli) | redis | Reference data caching (deal metadata, vendor records) | Per-key TTL configured in application |

## Data Flows

- Salesforce contract data flows into `continuumAccountingMysql` via the contract import pipeline (`acctSvc_contractImport`)
- Message Bus events are deserialized and enqueued as Resque jobs in `continuumAccountingRedis`, then dequeued by workers that write normalized records to `continuumAccountingMysql`
- Payment runs read transaction and invoice records from `continuumAccountingMysql`, produce payment records, and publish completion events to `messageBus`
- Reporting and reconciliation jobs read from `continuumAccountingMysql` and produce exports; no evidence of CDC or replication to external analytics stores from the service itself
