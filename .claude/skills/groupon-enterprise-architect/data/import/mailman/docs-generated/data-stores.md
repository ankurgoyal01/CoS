---
service: "mailman"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "mailmanPostgres"
    type: "postgresql"
    purpose: "Deduplication, retry payloads, Quartz scheduling metadata, and operational request state"
  - id: "ehcache"
    type: "in-memory"
    purpose: "In-memory caching for frequently accessed reference data"
---

# Data Stores

## Overview

Mailman uses two stores: a PostgreSQL 13.1 database (`mailmanPostgres`) as its primary persistent store for all operational state, and EhCache 2.9.0 as an in-process in-memory cache. The PostgreSQL database is owned exclusively by Mailman and holds deduplication records, retry payloads, Quartz job/trigger scheduling tables, and transactional request state. EhCache reduces repeated calls to downstream services for reference data within a JVM process lifecycle.

## Stores

### Mailman PostgreSQL (`mailmanPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `mailmanPostgres` |
| Purpose | Persistent store for deduplication, retry payloads, Quartz scheduling metadata, and operational request state |
| Ownership | owned |
| Migrations path | No evidence found |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Deduplication records | Tracks processed request identifiers to prevent duplicate email delivery | Request fingerprint / unique key, processed timestamp |
| Retry payloads | Stores serialized request payloads for failed messages awaiting retry | Request ID, payload blob, attempt count, next retry time |
| Quartz tables (`QRTZ_*`) | Quartz 2.2.1 scheduler persistence — job definitions, trigger state, and fire times | Job name, trigger name, next fire time, state |
| Request state | Operational state tracking for in-flight and completed transactional email requests | Request ID, status, created/updated timestamps |

#### Access Patterns

- **Read**: Deduplication lookups on inbound requests; Quartz reads trigger and job state during scheduler polling; retry processor reads pending retry payloads
- **Write**: New request state written on inbound submission; deduplication record written after first successful processing; retry payload written on DLQ consumption or processing failure; Quartz writes trigger state updates
- **Indexes**: No evidence found — indexes inferred from deduplication key lookups and retry scheduling queries

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| EhCache | in-memory | Caches reference data (e.g., client/context definitions) to reduce downstream API call volume within the JVM process | No evidence found |

## Data Flows

- Inbound requests (via API or MBus) are immediately persisted to `mailmanPostgres` as request state.
- Before processing, a deduplication check reads from `mailmanPostgres`; duplicate requests are rejected without further processing.
- On processing failure, the payload is written to `mailmanPostgres` as a retry record.
- The Quartz scheduler reads retry records from `mailmanPostgres` and re-submits them to the workflow engine on schedule.
- EhCache holds transient reference data in-process; no cross-instance cache sharing occurs.
