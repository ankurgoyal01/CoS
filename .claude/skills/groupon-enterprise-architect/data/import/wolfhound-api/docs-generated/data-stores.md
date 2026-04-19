---
service: "wolfhound-api"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumWolfhoundPostgres"
    type: "postgresql"
    purpose: "Primary relational datastore for pages, versions, schedules, templates, redirects, and metadata"
---

# Data Stores

## Overview

Wolfhound API uses a single owned PostgreSQL database as its primary data store. All content domain state — pages, versions, templates, schedules, traffic rules, redirects, bloggers, tags, and taxonomy entries — is persisted here. Additionally, the service maintains in-memory caches of published page state, subdirectories, and translations, which are loaded at startup and refreshed during publish workflows.

## Stores

### Wolfhound Postgres (`continuumWolfhoundPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumWolfhoundPostgres` |
| Purpose | Primary relational datastore for pages, versions, schedules, templates, redirects, and metadata |
| Ownership | owned |
| Migrations path | > No evidence found in architecture inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| pages | Stores SEO page definitions, content, and metadata | id, url, status, version, template_id |
| page_versions | Stores versioned snapshots of page content | id, page_id, version_number, content, created_at |
| schedules | Stores future publish and unpublish schedule entries | id, page_id, scheduled_at, action, status |
| templates | Stores Handlebars template definitions | id, name, content, created_at, updated_at |
| redirects | Stores URL redirect rules | id, source_url, destination_url, type |
| traffic | Stores traffic routing rules | id, rule_type, source_pattern, destination |
| bloggers | Stores blogger profile records | id, name, slug, metadata |
| tags | Stores content tags and tag-to-page associations | id, name, slug |

> Entity names are inferred from the `wolfhoundApi_persistenceDaos` component description ("CRUD and query operations on pages, versions, schedules, templates, redirects, bloggers, traffic, and tags"). Actual table names should be confirmed from the source repository migrations.

#### Access Patterns

- **Read**: Pages and templates queried by URL, ID, or filter criteria at serve time; taxonomy entries and redirects fetched during request enrichment; cache warm-up reads all published pages and subdirectories at startup
- **Write**: Page create/update/delete, version snapshots on each publish, schedule insertions, redirect and traffic rule mutations — all via the `wolfhoundApi_persistenceDaos` JDBI DAO layer
- **Indexes**: > No evidence found in architecture inventory. Indexes should be confirmed from schema migrations.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Published page cache | in-memory | Holds published page state loaded at startup; refreshed on publish workflow | > No evidence found |
| Subdirectory cache | in-memory | Holds subdirectory mappings for URL routing | > No evidence found |
| Translation cache | in-memory | Holds localization/translation entries for page rendering | > No evidence found |

## Data Flows

Page content originates from authoring tool API calls into `continuumWolfhoundApi`, is persisted to `continuumWolfhoundPostgres` via JDBI, and then promoted to the in-memory `cacheAndBootstraps` layer upon publish. The in-memory cache acts as the hot-read path for published page state. No CDC, ETL, or cross-database replication is modeled.
