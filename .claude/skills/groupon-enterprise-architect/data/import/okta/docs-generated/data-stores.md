---
service: "okta"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumOktaConfigStore"
    type: "postgresql"
    purpose: "Stores tenant mappings, provisioning configuration, and connector metadata"
---

# Data Stores

## Overview

The Okta service owns a single PostgreSQL data store (`continuumOktaConfigStore`) that holds all tenant mapping and provisioning configuration data. The service reads and writes this store to resolve Okta tenant context, connector configurations, and attribute mappings during SSO and provisioning operations. There are no caches or analytics stores defined in the architecture.

## Stores

### Okta Configuration Store (`continuumOktaConfigStore`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumOktaConfigStore` |
| Purpose | Stores tenant mappings, provisioning configuration, and connector metadata |
| Ownership | owned |
| Migrations path | No evidence found in codebase |

#### Key Entities

> No evidence found in codebase. Specific table names and schemas are not defined in the architecture DSL or service metadata snapshot. Based on the store's described purpose, the store is expected to contain tenant configuration records, provisioning connector settings, and attribute mapping definitions.

#### Access Patterns

- **Read**: `continuumOktaService` reads tenant mappings and connector metadata during SSO token exchange and SCIM provisioning flows.
- **Write**: `continuumOktaService` writes updated configuration and mapping data when tenant or provisioning settings change.
- **Indexes**: No evidence found in codebase.

## Caches

> No evidence found in codebase. No cache layer (Redis, Memcached, or in-memory) is defined in the architecture DSL.

## Data Flows

The `continuumOktaService` reads from `continuumOktaConfigStore` to resolve tenant and connector context at the start of each SSO and provisioning operation, then writes back any configuration updates. No CDC, ETL, or replication pipelines are defined in the available architecture artifacts.
