---
service: "voucher-archive-backend"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumVoucherArchiveDealsDb"
    type: "mysql"
    purpose: "Legacy LivingSocial deal and option data"
  - id: "continuumVoucherArchiveUsersDb"
    type: "mysql"
    purpose: "Legacy LivingSocial user and account data"
  - id: "continuumVoucherArchiveOrdersDb"
    type: "mysql"
    purpose: "Legacy LivingSocial order, coupon, and voucher records"
  - id: "continuumVoucherArchiveTravelDb"
    type: "mysql"
    purpose: "Legacy LivingSocial travel-specific voucher data"
  - id: "continuumVoucherArchiveRedis"
    type: "redis"
    purpose: "Resque job queue and action event store"
---

# Data Stores

## Overview

The voucher-archive-backend owns four separate MySQL 5.6 databases that mirror the original LivingSocial data segmentation: deals, users, orders, and travel. These are read-mostly stores for archived data, with writes limited to voucher state transitions (redemptions, refunds) and GDPR erasure. Redis is used as a Resque job queue for background processing of async tasks and GDPR workers.

## Stores

### Deals Database (`continuumVoucherArchiveDealsDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumVoucherArchiveDealsDb` |
| Purpose | Stores legacy LivingSocial deal records, deal options, redemption instructions, and associated images |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Legacy LivingSocial deal records | deal_id, title, merchant_id, status |
| `deal_options` | Purchase options for a deal | option_id, deal_id, price, value |
| `redemption_instructions` | How and where to redeem a deal | deal_id, instructions |

#### Access Patterns

- **Read**: Lookup by deal_id for voucher display and checkout flows; joins with deal_options and images
- **Write**: No evidence of writes to the deals database; treated as read-only archive
- **Indexes**: No evidence found in codebase.

---

### Users Database (`continuumVoucherArchiveUsersDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumVoucherArchiveUsersDb` |
| Purpose | Stores legacy LivingSocial user account records used for consumer voucher ownership resolution |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `users` | Legacy LivingSocial consumer accounts | user_id, email, name, created_at |

#### Access Patterns

- **Read**: Lookup by user_id to resolve consumer identity for voucher retrieval
- **Write**: GDPR erasure — personal data fields overwritten or deleted via Retcon Service integration
- **Indexes**: No evidence found in codebase.

---

### Orders Database (`continuumVoucherArchiveOrdersDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumVoucherArchiveOrdersDb` |
| Purpose | Core transactional store for legacy orders, coupons, and vouchers including state tracking |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `orders` | Legacy LivingSocial purchase orders | order_id, user_id, deal_id, total, created_at |
| `coupons` | Individual voucher/coupon records with lifecycle state | coupon_id, order_id, state, redeemed_at, refunded_at |
| `refunds` | Refund records created by CSR operations | refund_id, coupon_id, amount, created_at |

#### Access Patterns

- **Read**: Lookup coupons by user_id or merchant_id; lookup order by order_id for checkout retrieval
- **Write**: State transitions on coupons (redeem, refund via AASM); refund record creation by CSR operations
- **Indexes**: No evidence found in codebase.

---

### Travel Database (`continuumVoucherArchiveTravelDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumVoucherArchiveTravelDb` |
| Purpose | Stores legacy LivingSocial travel-specific voucher and booking data |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `travel_vouchers` | Travel deal voucher records with booking details | voucher_id, order_id, destination, check_in, check_out |

#### Access Patterns

- **Read**: Lookup by voucher_id or order_id for travel voucher display
- **Write**: No evidence of regular writes; GDPR erasure may apply
- **Indexes**: No evidence found in codebase.

---

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumVoucherArchiveRedis` | redis | Resque background job queue; action event buffering | No evidence found in codebase. |

## Data Flows

Data flows are primarily inbound (reads from archive databases) with limited writes for state transitions. The four MySQL databases represent a static archive of LivingSocial data — there is no ETL, CDC, or replication pipeline feeding new data into these stores post-migration. Redis holds transient job payloads for async processing, including GDPR erasure tasks queued by the message bus worker.
