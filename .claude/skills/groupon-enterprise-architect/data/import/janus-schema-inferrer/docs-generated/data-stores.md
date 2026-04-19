---
service: "janus-schema-inferrer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "inMemorySchemaStore"
    type: "in-memory"
    purpose: "Transient schema accumulation during a single CronJob run"
---

# Data Stores

## Overview

Janus Schema Inferrer is effectively stateless across runs. It owns no persistent database or external cache. The only data store used is a transient in-memory schema cache (`InMemorySchemaStore`) that accumulates inferred schemas within the lifecycle of a single CronJob execution. All durable persistence is delegated to the Janus Metadata service via its REST API.

## Stores

### In-Memory Schema Store (`inMemorySchemaStore`)

| Property | Value |
|----------|-------|
| Type | in-memory (Scala `TrieMap`) |
| Architecture ref | `continuumJanusSchemaInferrer` (internal component) |
| Purpose | Accumulates per-topic schemas during a single hourly run; enables diff and union operations before publishing to Janus |
| Ownership | owned (ephemeral, per-run) |
| Migrations path | Not applicable — no persistent schema |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `Schema` (in-memory) | Holds the current inferred schema for a topic as a normalized `Map[String, AnyRef]` | `topic` (key), `content` (schema map), `parentDiff` (fields added vs prior schema) |

#### Access Patterns

- **Read**: `schemaStore.get(topic)` — looks up the previously seen schema for a topic to compare against the newly inferred schema
- **Write**: `schemaStore.put(mergedSchema)` — stores the merged (unioned) schema after a diff detects new fields
- **Indexes**: Backed by `scala.collection.concurrent.TrieMap`; keyed by topic name string

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `InMemorySchemaStore` | in-memory (TrieMap) | Per-run schema accumulation; enables incremental schema merging within a single CronJob execution | Process lifetime (one CronJob run, ~minutes) |
| `RulesProvider` (memoized HTTP) | in-memory | Caches Janus mapping rules fetched from `continuumJanusWebCloudService` to avoid redundant HTTP calls per message | Process lifetime |

## Data Flows

All durable data flows out of this service via HTTP to `continuumJanusWebCloudService`:

- Inferred schemas flow: `InMemorySchemaStore` -> `JanusSchemaPublisher` -> `POST /janus/api/v1/persist/{rawEventName}` on `continuumJanusWebCloudService`
- Raw sample messages flow: sampled message bytes -> `JanusSampleRawMessagePublisher` -> `POST /janus/api/v1/source/{source}/raw_event/{event}/record/raw` on `continuumJanusWebCloudService`

There is no CDC, ETL, or replication within this service. The service reads from `messageBus` (Kafka/MBus) and writes to `continuumJanusWebCloudService`.
