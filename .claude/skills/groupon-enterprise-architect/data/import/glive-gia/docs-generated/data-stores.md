---
service: "glive-gia"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumGliveGiaMysqlDatabase"
    type: "mysql"
    purpose: "Primary relational store for deals, events, invoices, payments, and ticketing provider settings"
  - id: "continuumGliveGiaRedisCache"
    type: "redis"
    purpose: "Session/fragment cache and Resque job queue backend"
---

# Data Stores

## Overview

GIA uses two data stores: a MySQL database as the primary relational store for all persistent business data, and a Redis instance serving dual purpose as an application cache (via redis-rails) and the Resque background job queue backend.

## Stores

### GIA MySQL Database (`continuumGliveGiaMysqlDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumGliveGiaMysqlDatabase` |
| Purpose | Primary relational data store for deals, users, options, invoices, payments, and third-party ticketing provider settings |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deals` | Core deal record with lifecycle state machine | id, state, title, salesforce_id, created_at, updated_at |
| `events` | Live event instances attached to a deal | id, deal_id, name, date, capacity, state |
| `options` | Deal option/tier records | id, deal_id, name, price, quantity |
| `invoices` | Invoice records for merchant payment settlement | id, deal_id, amount, state, issued_at, paid_at |
| `payments` | Payment transactions against invoices | id, invoice_id, amount, status, provider_reference |
| `users` | GIA admin user accounts with role assignments | id, email, role, active |
| `redemption_codes` | Ticket/voucher codes associated with a deal | id, deal_id, code, status |
| `ticketmaster_settings` | Per-deal Ticketmaster API configuration | id, deal_id, event_id, api_key_reference |
| `provenue_settings` | Per-deal Provenue API configuration | id, deal_id, event_id |
| `axs_settings` | Per-deal AXS API configuration | id, deal_id, event_id |

#### Access Patterns

- **Read**: Controllers and services query deals by state, user, and date filters; events queried by deal_id; invoices queried by deal and payment status
- **Write**: State machine transitions update deal/invoice state; bulk_update writes multiple event records in a single operation; invoice creation writes invoice + payment records
- **Indexes**: Indexed on foreign keys (deal_id, invoice_id) and state columns for filtered list queries; paper_trail audit tables write on every model change

### GIA Redis (`continuumGliveGiaRedisCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumGliveGiaRedisCache` |
| Purpose | Application cache (session store, fragment caching) and Resque job queue backend |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Named job queues (e.g., `glive_gia_default`, `invoicing`) holding serialized job payloads | queue name, job class, args |
| Rails session store | Encrypted browser session data for authenticated admin users | session key, user identity |
| Fragment cache | Cached view fragments to reduce repeated computation | cache key (model + timestamp) |

#### Access Patterns

- **Read**: Resque workers poll queues for pending jobs; Rails reads session keys on every authenticated request; cache reads before expensive computations
- **Write**: Web app enqueues jobs when deal/invoice actions trigger async processing; session written on login; cache written after computation

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumGliveGiaRedisCache` | redis | Rails session store and fragment cache via redis-rails | Session: browser-lifetime; Fragment cache: varies by key |

## Data Flows

- The web app (`continuumGliveGiaWebApp`) reads and writes directly to MySQL for all synchronous request handling.
- When async processing is needed, the web app enqueues a job to Redis; the worker (`continuumGliveGiaWorker`) pulls the job and writes results back to MySQL.
- Paper Trail writes an audit version row to MySQL on every tracked model change, providing a full history of deal, invoice, and payment modifications.
- No CDC, ETL pipelines, or read replicas are evidenced in the inventory.
