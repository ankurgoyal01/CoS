---
service: "coupons-revproc"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCouponsRevprocDatabase"
    type: "mysql"
    purpose: "Primary durable store for processed and unprocessed transactions, merchant slug mappings, Quartz scheduler state, and auth client IDs"
  - id: "continuumCouponsRevprocRedis"
    type: "redis"
    purpose: "Redirect URL cache and message buffer for downstream processing"
---

# Data Stores

## Overview

coupons-revproc owns two data stores. MySQL is the primary durable store, holding the full transaction lifecycle state (unprocessed and processed records), merchant slug mapping tables, VoucherCloud domain mappings, Quartz job persistence tables, and client-ID auth records. Redis is used as a cache for redirect URL mappings (prefilled every 15 minutes from VoucherCloud) and as an intermediate buffer for messages before they are forwarded downstream. Schema migrations are managed by Flyway via `jtier-migrations` and the JTier Quartz migration package.

## Stores

### Revproc MySQL (`continuumCouponsRevprocDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumCouponsRevprocDatabase` |
| Purpose | Primary durable store for transaction lifecycle, merchant mapping, Quartz state, and auth |
| Ownership | owned |
| Migrations path | `src/main/resources/db/migrations/` (Flyway; JTier Quartz migrations also applied) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `unprocessed_transactions` | Staging table for inbound affiliate transactions before processing | clickId, transactionId, transactionTime, totalSale, amount, countryCode, network, source |
| `processed_transactions` | Final record of validated and enriched transactions | transactionId, clickId, userId, attributionId, bcookie, clickMessageUuid, couponUUID, dealUUID, primaryDealServiceId, merchantSlug, network, source, amount, roundedAmount, totalSale, currencyCode, countryCode, transactionTime, processTime, coreCouponTransaction, voucherCloudDomainId |
| `merchant_slug_mappings` | Maps affiliate merchant identifiers to canonical Groupon merchant slugs | affiliateMerchantId, merchantSlug |
| `merchant_slug_migration` | Lookup table for standardizing legacy CAPI merchant slugs to VoucherCloud API slugs | capiSlug, vcapiSlug |
| `voucher_cloud_domain` | Domain classification for VoucherCloud network identifiers | domainId, domainName |
| `client_ids` | Auth table of permitted client IDs | id, name |
| `client_id_roles` | Role assignments for each client ID | clientId, role |
| Quartz tables | Quartz scheduler job persistence (QRTZ_* tables, managed by jtier-quartz-mysql-migrations) | triggerName, jobName, nextFireTime |

#### Access Patterns

- **Read**: `ProcessedTransactionDAO` queries processed transactions by `click_ids`, `user_ids`, `since`, `country_code` with limit/offset pagination. `MerchantSlugMappingDAO` looks up slug by affiliate merchant ID. `MerchantSlugMigrationDAO` resolves CAPI to VoucherCloud slugs. `VoucherCloudDomainDAO` maps domain IDs.
- **Write**: `ProcessedTransactionFinalizer` inserts one processed transaction per qualifying inbound record. Unprocessed transactions are written during AffJet ingestion and cleared after processing.
- **Indexes**: Not directly visible from source; key lookup columns include `click_id`, `user_id`, `country_code`, `transaction_time`, and `merchant_slug`.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCouponsRevprocRedis` (redirect cache) | redis | Stores redirect URL mappings prefilled from VoucherCloud; accessed by redirect sanitizer and cache prefill jobs | Not configured in source — managed by Jedis bundle |
| `continuumCouponsRevprocRedis` (message buffer) | redis | Buffers intermediate messages before downstream forwarding; referenced in `TransactionProcessor` | Not configured in source |

## Data Flows

1. AffJet ingestion jobs poll AffJet API pages and write raw affiliate transactions to `unprocessed_transactions` in MySQL.
2. `TransactionProcessor` reads each unprocessed transaction, enriches it with click data from VoucherCloud API, deduplicates against existing revenue records, and produces a `ProcessedTransaction`.
3. `ProcessedTransactionFinalizer` inserts the processed transaction into the `processed_transactions` table and publishes paired click/redemption messages to Mbus.
4. `RedirectCachePrefillService` (scheduled every 15 minutes) fetches redirect mappings from VoucherCloud and writes them to Redis.
5. `CouponsFeedService` reads from `processed_transactions` to build feed export content; `CouponsFeedExporter` uploads the result to Dotidot SFTP.
6. `SalesforceService` reads bonus payment transactions from MySQL and submits them to the Salesforce REST API.
