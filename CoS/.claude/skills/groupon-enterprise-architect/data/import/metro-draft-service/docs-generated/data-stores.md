---
service: "metro-draft-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumMetroDraftDb"
    type: "postgresql"
    purpose: "Primary deal drafting data store"
  - id: "continuumMetroDraftMcmPostgres"
    type: "postgresql"
    purpose: "Merchandising change management and audit"
  - id: "continuumCovidSafetyProgramPostgres"
    type: "postgresql"
    purpose: "Covid safety program deal data"
  - id: "continuumMetroDraftRedis"
    type: "redis"
    purpose: "Permissions, feature flags, and draft deal caching"
---

# Data Stores

## Overview

Metro Draft Service owns four data stores: three PostgreSQL databases covering deal drafting, merchandising change management, and the Covid Safety Program; plus a Redis cache for permissions and draft artifact caching. All PostgreSQL access is performed via JDBI (jtier-jdbi). Schema migrations are managed via jtier-migrations. The Redis cache is accessed via Jedis.

## Stores

### Metro Draft DB (`continuumMetroDraftDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumMetroDraftDb` |
| Purpose | Primary store for draft deals, merchants, audit logs, and uploaded documents |
| Ownership | owned |
| Migrations path | Managed via jtier-migrations |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| deals / drafts | Draft deal records including status, content, and pricing | deal ID, merchant ID, status, created/updated timestamps |
| merchants | Merchant profile and association data for deals | merchant ID, attributes, contact references |
| deal_status | Workflow status markers and transition history | deal ID, status, transition timestamp |
| document_data | Upload metadata and file references attached to deals | deal ID, document type, storage reference, upload timestamp |
| history / audit | Audit log of all deal lifecycle actions | deal ID, actor, action type, timestamp |
| pds_config | Pricing defaults and PDS configuration metadata | deal type, country, default pricing structure |
| metadata_store | System-level configuration and key-value metadata | key, value, scope |
| quartz_* | Quartz scheduler state tables for background jobs | job name, trigger details, next fire time |

#### Access Patterns

- **Read**: Deal Service and DAOs query by deal ID, merchant ID, and status for drafting and publishing flows; Quartz DAO reads job state on scheduler tick
- **Write**: Deal Service, Deal Status Service, and History Event Service write on every deal lifecycle action; Quartz DAO writes on job execution
- **Indexes**: Not directly visible from DSL; inferred indexes on deal ID, merchant ID, and status columns based on access patterns

### MCM Postgres (`continuumMetroDraftMcmPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumMetroDraftMcmPostgres` |
| Purpose | Merchandising change management schema and audit data |
| Ownership | owned |
| Migrations path | Managed via jtier-migrations |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| mcm_changes | Merchandising change sets submitted for approval | change ID, deal ID, submitted by, approval state, timestamp |

#### Access Patterns

- **Read**: MCM Service Helper and MCM Resource read change sets and approval states
- **Write**: MCM Change DAO writes change sets on MCM Resource submissions; MCM Service Helper updates approval states
- **Indexes**: Not directly visible from DSL

### Covid Safety Program Postgres (`continuumCovidSafetyProgramPostgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumCovidSafetyProgramPostgres` |
| Purpose | Covid safety program specific deal data and migrations |
| Ownership | owned |
| Migrations path | Managed via jtier-migrations |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| covid_safety_deals | Deal records and banners for the Covid Safety Program | deal ID, banner state, program eligibility flags |

#### Access Patterns

- **Read**: Covid19 Deal Banner Job reads PDS configuration and deal eligibility
- **Write**: Covid19 Deal Banner Job applies banner updates to eligible deals
- **Indexes**: Not directly visible from DSL

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumMetroDraftRedis` | Redis (Jedis) | Caching permissions resolved from RBAC, feature flags, and draft deal data to reduce downstream call latency | Not specified in architecture model |

## Data Flows

- Deal drafting writes flow: API request -> Deal Service -> Deal DAO -> `continuumMetroDraftDb`
- Status transitions: Deal Status Service -> Deal Status DAO -> `continuumMetroDraftDb`
- Audit events: History Event Service -> History DAO -> `continuumMetroDraftDb`; also publishes to `continuumMetroDraftMessageBus`
- MCM changes: MCM Resource -> MCM Change DAO -> `continuumMetroDraftMcmPostgres`
- Redis population: Permission Filter and Deal Service write resolved permissions and draft artifacts to `continuumMetroDraftRedis` for cache-first reads on subsequent requests
- Covid banners: Covid19 Deal Banner Job reads from `continuumMetroDraftDb` (PDS config) and writes to `continuumCovidSafetyProgramPostgres`
