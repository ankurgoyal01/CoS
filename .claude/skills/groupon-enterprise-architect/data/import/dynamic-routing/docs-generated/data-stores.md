---
service: "dynamic-routing"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumDynamicRoutingMongoDb"
    type: "mongodb"
    purpose: "Persists dynamic route definitions and running state"
---

# Data Stores

## Overview

The dynamic-routing service owns a single MongoDB database that stores all dynamic route definitions, including source and destination endpoint configurations, filter chains, transformers, tracing settings, and each route's current running state. This is the system of record for the operator-defined routing topology. There are no caches or secondary stores.

## Stores

### Dynamic Routing MongoDB (`continuumDynamicRoutingMongoDb`)

| Property | Value |
|----------|-------|
| Type | MongoDB |
| Architecture ref | `continuumDynamicRoutingMongoDb` |
| Purpose | Stores all dynamic route definitions and their running state |
| Ownership | Owned |
| Migrations path | No automated migration tooling found in repository |

#### Key Entities

| Entity / Collection | Purpose | Key Fields |
|---------------------|---------|-----------|
| `routes` | Each document represents one dynamic Camel route definition | `name` (ID/route name), `sourceEndpoint` (polymorphic: queue/topic/rest/file/null), `destinationEndpoint`, `filterChain`, `transformer`, `tracing.chunkSize`, `running` (boolean) |

The `routes` collection stores polymorphic endpoint documents using Spring Data MongoDB's `@TypeAlias` discriminator. Endpoint types persisted:

| TypeAlias | Description |
|-----------|-------------|
| `queueEndpoint` | JMS queue endpoint (HornetQ or Artemis) |
| `topicEndpoint` | JMS topic endpoint, optionally durable with `clientId` and `durableSubscriptionName` |
| `restEndpoint` | HTTP REST ingestion endpoint with a `basePath` |
| `fileEndpoint` | File-based sink endpoint |
| `nullEndpoint` | Discard/null sink endpoint |

#### Access Patterns

- **Read**: On application startup, `DynamicRoutesManager` loads all routes from MongoDB using a paginated `findAll()` scan. At runtime, individual routes are fetched by name (`findOne(routeName)`) during start, stop, and status operations.
- **Write**: Route documents are created on `addRoute()`, updated on `startRoute()` / `stopRoute()` (to flip `running` flag), and deleted on `removeRoute()`. After initial load, each route's `running` state is re-persisted to reflect startup success or failure.
- **Indexes**: No explicit index definitions found in repository code; the `_id` field (mapped from `name`) is the primary access key.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| In-memory idempotent repository | In-memory (per Camel context) | Deduplicates messages on source endpoint using message `id`; capacity 500,000 entries | No TTL (evicted only when capacity is exceeded, using LRU semantics) |

## Data Flows

On startup, route definitions flow from MongoDB → `DynamicRoutesManager` → individual `SpringCamelContext` instances. Route state updates flow from the admin UI or REST API → `DynamicRoutesManager` → MongoDB (persistence of `running` flag). Message payloads themselves are not stored in MongoDB; they pass in-memory through Camel's processor pipeline from source broker to destination broker.
