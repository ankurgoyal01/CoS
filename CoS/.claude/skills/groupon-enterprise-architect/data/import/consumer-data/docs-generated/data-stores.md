---
service: "consumer-data"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumConsumerDataMysql"
    type: "mysql"
    purpose: "Primary relational store for consumer profiles, locations, preferences, and audit data"
---

# Data Stores

## Overview

Consumer Data Service owns a single MySQL 5.6 instance (`continuumConsumerDataMysql`) as its primary data store. All consumer profile, location, preference, and API client data is persisted here. There are no caches or secondary stores. Both the HTTP API container (`continuumConsumerDataService`) and the async worker (`continuumConsumerDataMessagebusConsumer`) share access to this database via ActiveRecord.

## Stores

### Consumer Data MySQL (`continuumConsumerDataMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumConsumerDataMysql` |
| Purpose | Primary relational data store for all consumer entity data |
| Ownership | owned |
| Migrations path | `db/migrate/` (ActiveRecord migrations convention) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `consumers` | Core consumer profile records | id, account_id, email, first_name, last_name, created_at, updated_at |
| `locations` | Physical addresses associated with a consumer | id, consumer_id, address fields, is_default, created_at, updated_at |
| `preferences` | Consumer preference key-value pairs | id, consumer_id, key, value, created_at, updated_at |
| `api_clients` | Registered API clients with access credentials | id, name, token, created_at, updated_at |
| `deleted_consumers` | Audit/tombstone records for GDPR-erased consumers | id, original_consumer_id, deleted_at |
| `settings` | Service-level configuration key-value pairs | id, key, value |

#### Access Patterns

- **Read**: Point lookups by consumer ID for profile, location list, and preference list; reads performed on every API GET request
- **Write**: Single-row upserts on profile updates; multi-row inserts/deletes for locations and preferences; batch soft-deletes during GDPR erasure
- **Indexes**: No evidence found in codebase for specific index definitions — standard primary key and foreign key indexes assumed

## Caches

> No evidence found in codebase for a caching layer in this service.

## Data Flows

Data enters MySQL through two paths: synchronous HTTP API writes (profile, location, preference mutations) and asynchronous event-driven writes (account creation provisioning, GDPR erasure). After a successful write, the HTTP API container publishes a corresponding MessageBus event to propagate the change downstream. The `deleted_consumers` table records tombstones created during GDPR erasure to support compliance audit trails.
