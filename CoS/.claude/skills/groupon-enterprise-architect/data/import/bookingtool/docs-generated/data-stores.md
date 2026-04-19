---
service: "bookingtool"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumBookingToolMySql"
    type: "mysql"
    purpose: "Primary relational store for reservations, availability, and merchant data"
  - id: "redis-cache"
    type: "redis"
    purpose: "Session store and application-level cache"
---

# Data Stores

## Overview

The Booking Tool uses two data stores: a MySQL 5.6 relational database as the primary system of record for all booking domain entities, and a Redis instance for HTTP session management and short-lived application caching. Persistence is managed through Doctrine DBAL repositories (`btRepositories`); there is no ORM layer — queries are written directly via DBAL.

## Stores

### Booking Tool MySQL (`continuumBookingToolMySql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumBookingToolMySql` |
| Purpose | Primary relational datastore for reservations, availability windows, blocked times, merchant configuration, and bank holidays |
| Ownership | owned |
| Migrations path | > No evidence found of a migrations directory path in the inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `bookings` / reservations | Records each customer reservation | booking_id, merchant_id, deal_id, voucher_code, slot_datetime, status, locale, created_at |
| `availability` | Defines merchant availability windows | availability_id, merchant_id, deal_id, start_datetime, end_datetime, capacity, recurrence_rule |
| `blocked_times` | Merchant-configured time blocks that exclude availability | blocked_time_id, merchant_id, start_datetime, end_datetime, reason |
| `bank_holidays` | Per-locale bank holiday calendar entries | holiday_id, locale, date, name |
| `merchants` | Local merchant configuration and metadata cache | merchant_id, locale, salesforce_id, status |

#### Access Patterns

- **Read**: Availability queries by merchant/deal/date range; booking lookups by booking_id and voucher_code; merchant config lookups per request
- **Write**: Reservation inserts on booking; status updates on cancel, reschedule, and check-in; availability window inserts/updates by merchants; blocked-time inserts/deletes
- **Indexes**: No explicit index evidence in inventory — expected indexes on merchant_id, deal_id, slot_datetime, and voucher_code for query performance

### Redis Cache

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | Referenced in service inventory; no dedicated Structurizr container ID |
| Purpose | HTTP session storage and short-lived application caching (availability cache, deal metadata cache) |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Session keys | Stores authenticated user session state | session token |
| Availability cache | Caches resolved availability responses | merchant_id + deal_id + date key |

#### Access Patterns

- **Read**: Session retrieval on every authenticated request; cache lookups for availability responses
- **Write**: Session creation on login; cache population after MySQL read; cache invalidation on availability change events
- **Indexes**: Redis key-based access — no secondary indexes

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Redis session store | redis | Stores authenticated browser session state | Session lifetime (no explicit TTL in inventory) |
| Redis availability cache | redis | Caches merchant availability query results to reduce MySQL load | Short-lived (TTL not evidenced) |

## Data Flows

Reservation data originates in MySQL on booking creation and is authoritative for all downstream reads. Redis holds derived/transient state only — session tokens and availability cache entries. No CDC, ETL, or replication pipeline evidence exists in the inventory. Deal and merchant metadata is sourced from Salesforce and Deal Catalog via integration clients and cached locally in MySQL.
