---
service: "selfsetup-fd"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumEmeaBtSelfSetupFdDb"
    type: "mysql"
    purpose: "Queue and setup state persistence"
---

# Data Stores

## Overview

selfsetup-fd owns a single MySQL database (`continuumEmeaBtSelfSetupFdDb`) which serves as the primary and only persistent store. It holds the async job queue, session state, and opportunity cache. No external caching layer (Redis, Memcached) is evidenced in the inventory.

## Stores

### SSU FD Database (`continuumEmeaBtSelfSetupFdDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumEmeaBtSelfSetupFdDb` |
| Purpose | Stores async setup job queue, session state, and opportunity cache for BT self-setup workflows |
| Ownership | owned |
| Migrations path | > No evidence found of a dedicated migrations directory in the inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Queue table | Holds pending and in-progress BT setup jobs enqueued by `ssuWebControllers` and processed by `ssuCronJobs` | job ID, status, opportunity ID, merchant data, timestamps |
| Session state | Stores PHP session data for employee wizard interactions | session ID, user context, setup progress |
| Opportunity cache | Caches Salesforce opportunity lookups to reduce redundant API calls | opportunity ID, merchant details, cached timestamp |

#### Access Patterns

- **Read**: `ssuQueueRepository` reads pending jobs for cron processing; `ssuWebControllers` reads queue status and opportunity cache entries
- **Write**: `ssuWebControllers` enqueues new setup jobs and writes opportunity cache; `ssuCronJobs` updates job status after processing
- **Indexes**: No evidence found of specific index definitions in the inventory

## Caches

> No evidence found of a dedicated cache layer (Redis, Memcached, or in-memory). Opportunity data is cached directly in the MySQL database.

## Data Flows

Setup job data flows from `ssuWebControllers` into the MySQL queue via `ssuQueueRepository`, then is read and processed by `ssuCronJobs`. Job status is updated in place within the queue table upon completion or failure. No CDC, ETL, or replication patterns are evidenced.
