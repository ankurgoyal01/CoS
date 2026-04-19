---
service: "authoring2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumAuthoring2Postgres"
    type: "postgresql"
    purpose: "Primary relational datastore for taxonomies, snapshots, roles, and audit history"
  - id: "continuumAuthoring2Queue"
    type: "activemq"
    purpose: "JMS queue for bulk and snapshot job dispatch"
---

# Data Stores

## Overview

Authoring2 owns a single primary relational data store: a PostgreSQL database provisioned via Groupon's DaaS (Database as a Service). All taxonomy content (taxonomies, categories, relationships, attributes, locale translations), audit records, user accounts, role and permission data, bulk job tracking, and snapshot XML content are persisted here. There is no separate cache layer — an in-process `Cache` singleton (populated at startup) holds attribute name lookups for performance. An ActiveMQ sidecar queue serves as a transient job store for asynchronous bulk and snapshot processing.

## Stores

### Authoring2 PostgreSQL (`continuumAuthoring2Postgres`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumAuthoring2Postgres` |
| Purpose | Primary relational datastore for all taxonomy authoring data |
| Ownership | owned |
| Migrations path | No evidence found in codebase |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `Taxonomies` | Top-level taxonomy definitions | `id`, `guid`, `name`, `description`, `createdAt`, `updatedAt`, `localesId` |
| `Categories` | Category nodes within a taxonomy | `id`, `guid`, `name`, `description`, `taxonomyGuid`, `root`, `localesId`, `createdAt`, `updatedAt` |
| `Relationships` | Directed edges between categories (parent-child and cross-taxonomy) | `id`, `guid`, `sourceCategoryGuid`, `targetCategoryGuid`, `relationshipTypeGuid`, `createdAt`, `updatedAt` |
| `RelationshipTypes` | Lookup table for relationship type definitions | `id`, `guid`, `name` |
| `Attributes` | Key-value metadata attached to categories | `id`, `guid`, `value`, `attributesNamesId`, `localesId`, `createdAt`, `updatedAt` |
| `AttributesNames` | Attribute name/type definitions | `id`, `name` |
| `Locales` | Supported locale definitions | `id`, `name` |
| `Snapshots` | Full XML snapshot records and deploy status | `id`, `guid`, `comment`, `status`, `content`, `createdAt`, `updatedAt` |
| `TaxonomySnapshotMap` | Mapping of taxonomy GUIDs to snapshot GUIDs for partial deploys | `id`, `taxonomyGuid`, `snapshotGuid` |
| `Bulk` | Async bulk job tracking records | `id`, `guid`, `hashcode`, `json`, `operationType`, `percent`, `linesTotal`, `linesOk`, `linesError`, `result`, `isBeingProcessed`, `createdAt` |
| `Audit` | Audit trail of who last modified taxonomies and categories | `id`, `entityId`, `urlId`, `userName`, `updatedAt` |
| `User` | Authoring user accounts | `id`, `guid`, `name`, `email` |
| `Roles` | Role definitions for access control | `id`, `guid`, `name` |
| `Permission` | User-to-role assignments | `id`, `userId`, `roleId` |
| `Operations` | Permitted operations per role | `id`, `guid`, `name` |
| `Urls` | URL resource identifiers used by authorization filter | `id`, `guid`, `name` |

#### Access Patterns

- **Read**: JPA named queries and JPQL executed by JPA controller classes for single-entity lookup, list fetching, breadcrumb traversal, search by GUID or name, and export generation. Breadcrumb traversal also uses a stored procedure (`breadcrumb(guid)`).
- **Write**: JPA `create`, `edit`, and `destroy` operations in controller classes; bulk writes dispatched from queue consumer via iterative inserts.
- **Indexes**: No evidence found in codebase (index definitions not included in the repository; managed externally by DaaS).

### Authoring2 Bulk Queue (`continuumAuthoring2Queue`)

| Property | Value |
|----------|-------|
| Type | ActiveMQ (JMS queue) |
| Architecture ref | `continuumAuthoring2Queue` |
| Purpose | Asynchronous dispatch of bulk taxonomy mutations and snapshot generation jobs |
| Ownership | owned |

The ActiveMQ broker runs as a Docker sidecar container (`docker.groupondev.com/hawk/authoring2-activemq-20220721-120753:5.10.0`) on `localhost:61616`. Queue name: `Authoring2`. Configured via `queue.*.properties` files. In-memory queue; not replicated. Jobs are acknowledged via `CLIENT_ACKNOWLEDGE`.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `Cache.INSTANCE` (in-process) | In-memory (Java singleton) | Caches `AttributesNames` by name key to avoid repeated DB lookups during bulk operations | Application lifetime (populated at startup) |

## Data Flows

- Taxonomy content authors submit changes via REST API → JPA controllers write to `continuumAuthoring2Postgres`.
- Bulk/snapshot REST endpoints write a job record to `Bulk` or `Snapshots` tables, then publish a JMS message to `continuumAuthoring2Queue`.
- `BulkQueueListener` consumes messages, applies mutations to `continuumAuthoring2Postgres`, and updates job progress fields.
- On snapshot deploy-live, Authoring2 reads snapshot content from `continuumAuthoring2Postgres` and calls the `continuumTaxonomyService` activation endpoint via HTTP — no direct cross-database replication.
