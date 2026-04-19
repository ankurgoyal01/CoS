---
service: "tripadvisor-api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "gpnDataDb"
    type: "mysql"
    purpose: "GPN framework platform database (inherited; no service-owned entities documented)"
---

# Data Stores

## Overview

The Getaways Affiliate API does not own or manage any business data stores. All hotel availability and pricing data is fetched on demand from downstream Getaways APIs. A MySQL database reference is present in the Spring configuration (JNDI datasource `java:comp/env/jdbc/GpnDataDb`) inherited from the GPN (Groupon Platform Network) framework. The owner's manual explicitly states "No caching is currently done in the application."

## Stores

### GPN Data Database (`gpnDataDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | Not modelled as a container in `continuumTripadvisorApiV1Webapp` |
| Purpose | GPN platform framework integration (not used for service business entities) |
| Ownership | shared (GPN framework) |
| Migrations path | Not applicable — no service-owned schema |

#### Key Entities

> No evidence found in codebase. No service-owned tables are documented.

#### Access Patterns

- **Read**: Not documented; JNDI datasource configured via `jndi.datasource.path=java:comp/env/jdbc/GpnDataDb`
- **Write**: Not documented
- **Indexes**: Not applicable

Database hosts (from `ta-api-v1/doc/OWNERS_MANUAL.md`):
- Primary: `gpn-db1.snc1`, `gpn-db2.snc1`
- VIP: `gpn-db-vip.snc1`
- Replication: master/slave
- Backups: enabled

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| EHCache | in-memory | Configured in pom.xml (`ehcache-core 2.4.7`) but no caching is currently active per owner's manual | Not applicable |

## Data Flows

The service is effectively stateless from a business data perspective. All data flows are read-through from downstream Getaways APIs:

1. Receives availability request from external partner
2. Calls `getawaysSearchApi` at `http://getaways-search-app-vip/getaways/v2/search` for availability data
3. Calls `getawaysContentApi` at `http://getaways-content-app-vip/v2/getaways/content/product_sets` and `/hotelDetailBatch` for hotel content
4. Transforms and returns response to partner without persisting data
