---
service: "deal-service"
title: Overview
generated: "2026-03-02"
type: overview
domain: "Deal Management & Inventory"
platform: "Continuum"
team: "Marketing Information Systems (MIS)"
status: active
tech_stack:
  language: "CoffeeScript"
  language_version: "1.10.0+"
  framework: "Node.js native (event-driven, no HTTP framework)"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: "16.20.2"
  build_tool: "npm + gulp 4.0.0"
  package_manager: "npm (>=8.5.5)"
---

# Deal Service Overview

## Purpose

Deal Service is a background worker process within the Continuum Commerce Platform that manages the full lifecycle of deal state updates. It continuously polls a Redis job queue, enriches deal records by aggregating data from multiple internal and external APIs, persists the results to PostgreSQL and MongoDB, and publishes inventory status changes to the message bus. The service exists to keep deal inventory state accurate and propagated across downstream consumers in near-real-time.

## Scope

### In scope

- Polling the `processing_cloud` Redis sorted set for deal processing jobs
- Fetching and aggregating deal metadata from DMAPI, Deal Catalog API, Goods Stores API, Geo Services, Forex API, Salesforce, M3 Place/Merchant/Google Place APIs
- Persisting processed deal state to PostgreSQL (`deals`, `product_to_deal_mapping`, `deal_mbus_updates` tables)
- Writing enriched deal metadata to MongoDB
- Publishing `INVENTORY_STATUS_UPDATE` events to the message bus when deal option inventory status changes
- Publishing deal change notifications to Redis lists for downstream notification consumers
- Scheduling and executing retry processing for failed deals via the `nodejs_deal_scheduler` Redis sorted set
- Caching deal metadata to the BTS Redis instance
- Dynamically reloading runtime feature flags via keldor-config
- Auto-restarting the worker process on crash via a master/worker fork model

### Out of scope

- Serving HTTP API requests (deal-service exposes no HTTP endpoints)
- Accepting inbound deal creation or update commands from external callers
- Serving deal data directly to frontend or consumer-facing services (read path handled by other services)
- Deal content authoring or merchandising workflows

## Domain Context

- **Business domain**: Deal Management & Inventory (Continuum Commerce Platform)
- **Platform**: Continuum
- **Upstream consumers**: No direct inbound callers; deal-service is triggered by entries placed in the Redis `processing_cloud` queue by upstream systems
- **Downstream dependencies**: Deal Management API (DMAPI), Deal Catalog API, Goods Stores API, Geo Services / Bhuvan, Forex API, Salesforce, M3 Place Read Service, M3 Merchant Service, M3 Google Place API, Message Bus, Keldor Config Service, PostgreSQL, MongoDB, Redis (Local + BTS)

## Stakeholders

| Role | Description |
|------|-------------|
| Marketing Information Systems (MIS) | Owning team; responsible for development, deployment, and on-call |
| Commerce Platform consumers | Downstream services that consume `INVENTORY_STATUS_UPDATE` events from the message bus |
| Merchandising / Deal Operations | Business stakeholders relying on accurate deal inventory state |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | CoffeeScript | 1.10.0+ | package.json / `.coffee` source files |
| Framework | Node.js native (event-driven) | — | app.coffee entry point; no HTTP framework dependency |
| Runtime | Node.js | 16.20.2 | Volta pin; Dockerfile `alpine-node16.15.0` |
| Build tool | gulp | 4.0.0 | package.json devDependencies |
| Package manager | npm | >=8.5.5 | package.json engines |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| keldor-config | 4.18.3 | other | Dynamic configuration loader for runtime feature flags |
| redis | 0.12.1 | message-client | Redis client for job queue and scheduling |
| mongodb | 2.2 | db-client | MongoDB client for deal metadata storage |
| sequelize | 5.22.5 | orm | ORM for PostgreSQL deal state and mappings |
| pg | 8.7.3 | db-client | PostgreSQL driver |
| nbus-client | ^0.1.0 | message-client | Message bus client for publishing inventory updates |
| request | 2.47.0 | http-client | HTTP client for external API calls |
| cassandra-driver | 2.1.0 | db-client | Cassandra driver (potential legacy) |
| jsforce | 1.11.0 | http-client | Salesforce REST API client |
| async | 0.2.9 | other | Async flow control for parallel operations |
| json2csv | 3.6.2 | serialization | JSON to CSV conversion for reporting |
| underscore | ~1.5.2 | other | Functional programming utility library |
| uuid | ^9.0.1 | other | UUID generation for event messages |
| gulp-jasmine | ^2.4.2 | testing | BDD testing framework (via gulp task runner) |

Categories: `http-framework`, `orm`, `db-client`, `message-client`, `auth`, `logging`, `metrics`, `serialization`, `testing`, `ui-framework`, `state-management`, `validation`, `scheduling`

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
