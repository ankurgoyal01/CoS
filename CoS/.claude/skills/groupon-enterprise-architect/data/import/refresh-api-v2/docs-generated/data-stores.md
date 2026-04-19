---
service: "refresh-api-v2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumRefreshApiDatabase"
    type: "postgresql"
    purpose: "Primary application store — jobs, users, subscriptions, Quartz state"
  - id: "continuumRefreshApiWorkingDir"
    type: "filesystem"
    purpose: "Transient working directory for Tableau package artifacts"
---

# Data Stores

## Overview

Refresh API V2 owns one primary relational database (PostgreSQL, provisioned via Groupon DaaS) and uses a local filesystem working directory for transient artifact storage during publish workflows. There are no in-process caches or external cache services. The service also reads from the Tableau metadata databases (PostgreSQL) on both staging and production as an external read-only dependency — those are not owned by this service.

## Stores

### Refresh API Postgres (`continuumRefreshApiDatabase`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumRefreshApiDatabase` |
| Purpose | Primary application store for refresh jobs, publish jobs, users, subscriptions, webhooks, and Quartz scheduler state |
| Ownership | owned |
| Migrations path | Managed via `jtier-quartz-postgres-migrations` (Quartz tables) and JTier DaaS Postgres provisioning |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Refresh jobs | Tracks the lifecycle of extract refresh requests | job ID, datasource/workbook ID, status, log entries, Tableau job UUID |
| Publish jobs | Tracks staging-to-production promotion workflows | job ID, staging source ID, production source ID, status, publish request |
| Users | Local user records with roles for API authorization | username, email, role (`USER`, `SUPER_USER`, `ADMIN`) |
| Subscriptions | User subscriptions to refresh events and notifications | subscription ID, user, source, email/page settings |
| Project batch users | Per-project service account credentials for batch operations | project ID, credentials, connection config |
| Source configurations | Recommendation and connection configuration per datasource | datasource ID, config JSON |
| Quartz tables | Persistent Quartz scheduler state (jobs, triggers, fired jobs) | Managed by `jtier-quartz-bundle` |

#### Access Patterns

- **Read**: Job status polling by API Resources; Tableau background job lookups by `RemoteRefreshJob`; user lookup by auth layer; subscription queries for notification workflows
- **Write**: Job creation on API request; job status and log updates throughout workflow execution; Quartz trigger and job management
- **Indexes**: Not directly visible in source; Quartz tables use standard Quartz schema indexes; job ID primary keys for all job tables

### Refresh API Working Directory (`continuumRefreshApiWorkingDir`)

| Property | Value |
|----------|-------|
| Type | Filesystem |
| Architecture ref | `continuumRefreshApiWorkingDir` |
| Purpose | Transient local filesystem for downloaded Tableau source packages and intermediate artifacts during publish workflows |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Staging source packages | Downloaded `.twb` / `.tds` files from Tableau staging | Keyed by source ID and job ID |
| Modified source packages | Repackaged source files with updated connection info ready for production publish | Keyed by publish job ID |

#### Access Patterns

- **Read**: Publish workflow reads downloaded packages for XML parsing and connection updates
- **Write**: `ContentDownloader` writes downloaded staging packages; `PreparePackageService` writes modified packages
- **Indexes**: Not applicable (filesystem)

## Caches

> No evidence found in codebase. No in-process or distributed cache is configured.

## Data Flows

- Refresh job state flows: API Resource creates job record in Postgres → Quartz scheduler picks up job → `RemoteRefreshJob` / `PromoteWorkbookJob` updates status and appends log entries to Postgres → final terminal status written on completion or failure.
- Publish artifact flow: Tableau staging source downloaded to working directory → XML parsed and connections modified → repackaged file uploaded to Tableau production → local artifacts cleaned up after job completes.
- Tableau metadata read: `RemoteRefreshJob` reads Tableau background job completion status directly from the Tableau metadata database (external read-only access to `tableauProdMetadataDb`) on a 1-minute polling interval for up to 2 hours.
