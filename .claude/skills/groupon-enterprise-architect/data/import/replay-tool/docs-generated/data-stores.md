---
service: "replay-tool"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "in-memory-replay-cache"
    type: "in-memory"
    purpose: "Holds active replay request batches and Boson load futures for the lifetime of the JVM process"
---

# Data Stores

## Overview

The MBus Replay Tool is effectively stateless with respect to external data stores. It owns no database, no persistent cache, and no file system state. All replay session data — request batches, load futures, and execution status — is held in JVM heap memory using Guava Cache and `ConcurrentHashMap`. Data is lost on service restart. External data is read transiently from Boson log files (via SSH) and the SigInt REST API.

## Stores

### In-Memory Replay Session Store (`in-memory-replay-cache`)

| Property | Value |
|----------|-------|
| Type | in-memory |
| Architecture ref | `continuumMbusReplayToolService` |
| Purpose | Holds the active set of replay request batches, their load futures, and execution state for the duration of the JVM session |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity | Purpose | Key Fields |
|--------|---------|-----------|
| `ReplayRequestBatch` | Top-level request group identified by UUID; tracks one or more Boson sub-requests and overall execution status | `uuid`, `replayRequest`, `submittedReplayRequests`, `executionStatus` |
| `SubmittedReplayRequest` | Individual Boson log-load sub-request with its own load status | `uuid`, `bosonHost`, `status` (COMPLETED/IN_PROGRESS/FAILED) |
| `ReplayExecution` | Active execution context for a batch; holds worker references and futures | `workers`, `futureResultList` |
| `CommandFrame` / `MessageFrame` | In-memory representation of a single intercepted message loaded from Boson | `messageId`, `payload`, `payloadType`, `stompHeaders`, `messageHeaders` |

#### Access Patterns

- **Read**: Status polling threads and API handlers read from `ConcurrentHashMap<String, ReplayRequestBatch>` keyed by UUID; Guava Cache `getIfPresent` for load futures
- **Write**: New batches inserted on `POST /replay/request`; load futures inserted on Boson task submission; execution status updated by `ExecutionStatusChecker` background thread
- **Indexes**: No indexes; direct UUID-keyed map lookups

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `resultCache` (Guava Cache) | in-memory | Stores `Future<List<CommandFrame>>` per replay UUID so load results can be retrieved asynchronously after Boson SSH tasks complete | No expiry configured (held until JVM restart) |
| `environmentCache` (Guava LoadingCache) | in-memory | Caches environment layout from SigInt per colo to avoid repeated REST calls | 30 minutes (`expireAfterWrite`) |
| `environmentConfigurationCache` (Guava LoadingCache) | in-memory | Caches cluster configuration (queues, topics, credentials) per `(colo, environment)` from SigInt | 30 minutes (`expireAfterWrite`) |

## Data Flows

- Boson log files are read transiently over SSH during a load operation; parsed line-by-line into `CommandFrame` objects held in memory.
- SigInt environment configuration is fetched on first access per colo/environment and cached for 30 minutes.
- No CDC, ETL, or replication patterns exist. All data is ephemeral.

> This service does not own any persistent data stores. All session data is in-memory and is lost on restart.
