---
service: "momo-config"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "ecelerity-spool"
    type: "disk-queue"
    purpose: "On-disk message spool for queued outbound mail pending delivery"
  - id: "leveldb-adaptive"
    type: "leveldb"
    purpose: "Adaptive delivery backstore for per-binding/domain throttle state"
  - id: "ecdb"
    type: "ecelerity-db"
    purpose: "Ecelerity cluster database for node coordination"
---

# Data Stores

## Overview

The MTA clusters configured by `momo-config` use three categories of storage: an on-disk message spool for queued outbound messages, a LevelDB adaptive delivery backstore for per-domain/binding throttle state, and the Ecelerity cluster database (`ecdb`) for node coordination. No external relational database or cloud storage is owned by this service. Log output files are written to local disk and consumed downstream by the `loggingStack`.

## Stores

### Ecelerity On-Disk Message Spool (`ecelerity-spool`)

| Property | Value |
|----------|-------|
| Type | disk-queue |
| Architecture ref | `continuumMtaEmailService`, `continuumMtaTransService` |
| Purpose | Durable store for queued outbound messages awaiting delivery; survives process restarts |
| Ownership | owned |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Message spool file | Stores each queued message body and headers on disk | Message ID, recipient, binding, expiry |

#### Access Patterns

- **Read**: Ecelerity swaps messages from spool into memory (`SwapIn` thread pool, concurrency 20) for delivery attempts
- **Write**: Messages are spooled to disk (`SwapOut` thread pool, concurrency 20) upon receipt; `SpoolBase = "/var/spool/ecelerity"`, `Spool_Mode = 0644`
- **Indexes**: N/A — file-system based with `Disk_Queue_Drain_Rate = 100`

### Adaptive Delivery Backstore (`leveldb-adaptive`)

| Property | Value |
|----------|-------|
| Type | leveldb |
| Architecture ref | `continuumMtaEmailService`, `continuumMtaTransService`, `continuumMtaSmtpService` |
| Purpose | Persists adaptive delivery state — per-binding/domain throttle levels, suspension windows, rejection rate counters — across process restarts |
| Ownership | owned |
| Migrations path | N/A |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Adaptive binding/domain record | Stores current throttle, suspension state, and rejection rate per binding+domain pair | binding, domain, suspension_start, throttle_level |

#### Access Patterns

- **Read**: Adaptive module reads throttle state on each delivery attempt
- **Write**: Updated on delivery events, rejections, and suspension transitions
- **Indexes**: LevelDB key-value; path `"/opt/msys/leveldb/adaptive.leveldb"` (email/trans clusters), `"/opt/msys/leveldb/adaptive.leveldb"` (smtp cluster)

### Ecelerity Cluster Database (`ecdb`)

| Property | Value |
|----------|-------|
| Type | ecelerity-db |
| Architecture ref | `continuumMtaEmailService`, `continuumMtaTransService` |
| Purpose | Cluster-internal coordination database; included read-only (`readonly_include "ecdb.conf"`) in email and trans clusters |
| Ownership | shared |
| Migrations path | N/A |

#### Key Entities

> Not applicable. `ecdb` is a Momentum-internal coordination store; schema is managed by the Ecelerity runtime.

#### Access Patterns

- **Read**: Configuration loaded at startup via `readonly_include "ecdb.conf"`
- **Write**: Managed by Ecelerity cluster runtime; not written by policy scripts

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Match cache | in-memory | PCRE/pattern match result cache | Per session; `Match_Cache_Size = 512000` |
| Adaptive binding/domain cache | in-memory | In-process cache for adaptive binding domain state | Per session; `Binding_Domain_Cache_Size = 5000000` |
| Bounce classifier refresh | in-memory | Bounce classification override table | 900 seconds (`refresh = 900`) |
| DNS lookup | in-process | MX and A record lookups during recipient validation | Per Ecelerity DNS resolver TTL |

## Data Flows

Outbound messages enter the on-disk spool upon receipt by the email or SMTP cluster and are progressively delivered to remote MX servers by the trans cluster. The adaptive LevelDB store is continuously updated with per-domain delivery outcomes to drive throttle adjustments. Inbound response messages (bounces, FBLs, unsubscribes) are processed in-memory by the inbound cluster's Lua policy engine and written as structured log records to local disk files, which are then consumed by the `loggingStack` pipeline. No CDC, ETL, or materialized view patterns are present in this configuration.
