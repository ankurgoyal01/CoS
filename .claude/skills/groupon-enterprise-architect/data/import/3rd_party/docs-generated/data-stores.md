---
service: "online_booking_3rd_party"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumOnlineBooking3rdPartyMysql"
    type: "mysql"
    purpose: "Primary relational store for providers, merchant places, service mappings, reservations, and access tokens"
  - id: "continuumOnlineBooking3rdPartyRedis"
    type: "redis"
    purpose: "Resque queue backend and transient cache"
---

# Data Stores

## Overview

`online_booking_3rd_party` uses MySQL as its primary relational store for all domain entities, Redis for job queuing (Resque) and worker coordination, and Memcached for application-level caching via Dalli. The API and Workers containers both share access to MySQL and Redis; Memcached is used by the API layer for read-through caching of frequently accessed data.

## Stores

### Online Booking 3rd Party MySQL (`continuumOnlineBooking3rdPartyMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumOnlineBooking3rdPartyMysql` |
| Purpose | Primary relational datastore for providers, merchant places, service mappings, reservations, and API tokens |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `providers` | Third-party provider system registrations | id, name, type, config |
| `merchant_places` | Groupon merchant places linked to provider accounts | id, merchant_id, provider_id, provider_place_ref, status |
| `service_mappings` | Maps Groupon deal options/services to provider service offerings | id, merchant_place_id, groupon_option_id, provider_service_ref, status |
| `reservations` | Synchronized reservation records from provider systems | id, merchant_place_id, provider_reservation_ref, status, start_at, end_at |
| `access_tokens` | OAuth/API tokens for provider authorization | id, merchant_place_id, token, expires_at, scopes |

#### Access Patterns

- **Read**: API reads mappings, places, and reservations on every inbound request; Workers query pollable places for scheduled sync cycles
- **Write**: API writes on mapping create/update/delete and on booking webhook receipt; Workers write sync progress, reservation state, and retry metadata
- **Indexes**: Indexed on merchant_place_id, provider_id, status for efficient polling queries

### Online Booking 3rd Party Redis (`continuumOnlineBooking3rdPartyRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumOnlineBooking3rdPartyRedis` |
| Purpose | Resque queue backend and worker coordination |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `resque:queue:*` | Resque job queues for async processing | job class, args, enqueued_at |
| `resque:schedule` | Scheduled job definitions (resque-scheduler) | job name, cron expression, class |

#### Access Patterns

- **Read**: Workers pop jobs from queues; API checks Redis health as a dependency probe
- **Write**: API enqueues follow-up sync jobs; Workers update Resque schedule state

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Application cache | memcached | Caches frequently read API responses and lookup data to reduce DB load | Not confirmed from inventory |

## Data Flows

MySQL is the system of record. Redis acts as the job queue transport layer — the API writes job payloads to Redis when async processing is required, and Workers consume those payloads, then write back their results to MySQL. Memcached serves as a read-aside cache for the API layer with no write-back semantics.
