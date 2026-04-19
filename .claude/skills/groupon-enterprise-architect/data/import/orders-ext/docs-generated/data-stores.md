---
service: "orders-ext"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumOrdersExtRedis"
    type: "redis"
    purpose: "Resque background job queue for async order resolution"
---

# Data Stores

## Overview

Orders Ext owns one data store: a Redis instance used exclusively as a Resque job queue for asynchronous order resolution. The service is otherwise stateless — it holds no persistent application database, no relational schema, and no object storage. All business data lives in downstream services (orders-worker, Fraud Arbiter, Billing Records).

## Stores

### Orders Ext Redis (`continuumOrdersExtRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumOrdersExtRedis` |
| Purpose | Resque background job queue for async Accertify order resolution |
| Ownership | owned |
| Migrations path | Not applicable (no schema) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `accertify_order_resolution` queue | Holds serialized job payloads enqueued by `OrderResolver` | `order_id` or `order_line_item_id`, `action` (ACCEPT/REJECT), `data` (score, remarks, admin_id), `enqueued_at` |

#### Access Patterns

- **Read**: Consumed by orders-worker (external service) that polls the `accertify_order_resolution` Resque queue
- **Write**: `OrderResolver` pushes one job per Accertify resolution callback via `Resque.enqueue(AccertifyOrderResolutionWorker, ...)`
- **Indexes**: No explicit indexes; Redis list semantics via Resque key `resque:queue:accertify_order_resolution`

## Caches

> No application-level caches are used. The Redis instance serves only as a job queue, not a cache.

## Data Flows

Inbound Accertify XML callback → `OrderResolver` parses and transforms → job payload pushed to Redis queue → orders-worker (external) dequeues and executes order state transition.

The Redis connection is configured from `config/redis.yml` (per-environment overrides in `config/cloud/<env>/redis.yml`):

- **Dev/Staging**: Shared Redis instance at `redis-17538.snc1.raas-shared1-uat.grpn:17538`
- **Production (US)**: Google Cloud Memorystore at `orders-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`
