---
service: "billing-record-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumBillingRecordPostgres"
    type: "postgresql"
    purpose: "Primary transactional store for billing records, purchasers, and payment metadata"
  - id: "continuumBillingRecordRedis"
    type: "redis"
    purpose: "Cache for billing-record query results with selective invalidation"
---

# Data Stores

## Overview

Billing Record Service owns two data stores: a PostgreSQL database as its primary transactional store, and a Redis cache for accelerating billing-record retrieval. The PostgreSQL database uses a dedicated `billingrecord` schema (plus a `liquibase` schema for migration tracking) within the `billing_record_master` database. Schema migrations are managed via Liquibase. Replication and backup are handled by the Groupon DaaS (Database-as-a-Service) team.

## Stores

### Billing Record PostgreSQL (`continuumBillingRecordPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumBillingRecordPostgres` |
| Purpose | Primary transactional store for billing records, purchaser records, payment data, token data, and billing addresses |
| Ownership | owned |
| Migrations path | Managed by Liquibase; local bootstrap via `docker/db/brs/50_liquibase.sh`; production migration via Capistrano (`Capfile.liquibase`) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `billingrecord.billing_record` | Stores each payment instrument record per purchaser | `id` (UUID), `br_p_id` (purchaser UUID), `br_status` (enum), `created_at`, `type`, `variant` |
| Purchaser | Stores purchaser-level state and PSP references (e.g., Adyen shopper reference) | `id` (UUID), `pspPurchaserData` (Adyen reference, country code) |
| BillingAddress | Billing address associated with a payment instrument | `id` (UUID), `postalCode`, `country`, `city`, `addressLine1/2`, `firstName`, `lastName`, `phoneNumber`, `taxIdNumber` |
| PaymentData | Payment instrument metadata | `name`, `bin`, `accountNumber`, `mobilePayType` (ANDROIDPAY/APPLEPAY), `cryptogram`, `eci` |
| TokenData | Payment gateway token references per billing record | `tokenId`, `tokenStore` (ADYEN/PCI_TOKENIZER/CYBERSOURCE), `tokenType` (ONECLICK/RECURRING/COMBINED), `status` (UPTODATE/STALE) |

#### Access Patterns

- **Read**: Queries by `purchaserId` (UUID) and optional `countryCode`; point lookups by `billingRecordId`; lookup by `ordersLegacyId` for migration; token-presence checks for GDPR flows
- **Write**: Inserts on billing record creation; updates on status transitions (authorize, deactivate, refuse, IRR erasure); batch updates during GDPR erasure (PII scrubbing across all records for a purchaser)
- **Indexes**: Not directly visible in source; primary keys are UUIDs; `br_p_id` is expected to be indexed for purchaser-scoped queries

### Billing Record Redis Cache (`continuumBillingRecordRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumBillingRecordRedis` |
| Purpose | Cache billing-record query results to reduce PostgreSQL read load |
| Ownership | owned |
| Migrations path | Not applicable — cache only |

#### Key Entities

> No evidence found in codebase for specific Redis key patterns or TTL values. The cache stores billing record query result sets keyed by purchaser and country.

#### Access Patterns

- **Read**: Cache-aside pattern — check Redis before querying PostgreSQL
- **Write**: On successful DB read, write result to Redis; on billing record create, update, or deactivate, evict stale cache entries

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumBillingRecordRedis` | redis | Billing-record query result cache; reduces DB read pressure on high-traffic checkout paths | Not documented in source |

## Data Flows

Billing records are written to PostgreSQL on creation and status transitions. Redis cache entries are populated on reads and invalidated on any write that changes the billing record state. During GDPR IRR processing, all billing records for a purchaser are read from PostgreSQL, PII fields are scrubbed in-place, and the updated records are written back; the corresponding Redis cache entries are evicted. Orders migration writes new billing records to PostgreSQL by reading from the legacy Orders MySQL database.
