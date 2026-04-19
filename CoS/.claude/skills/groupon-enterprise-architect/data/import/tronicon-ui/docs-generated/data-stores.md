---
service: "tronicon-ui"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumTroniconUiDatabase"
    type: "mysql"
    purpose: "Primary relational store for all campaign card, CMS, theme, and geo data"
---

# Data Stores

## Overview

Tronicon UI relies on a single owned MySQL database as its primary and only data store. All application entities — cards, decks, campaigns, CMS content, templates, themes, geo polygons, and permalinks — are persisted in this database. Schema changes are managed through Alembic migrations. There is no caching layer or secondary store identified in the service inventory.

## Stores

### Tronicon UI Database (`continuumTroniconUiDatabase`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumTroniconUiDatabase` |
| Purpose | Primary relational store for cards, decks, campaigns, CMS content, themes, templates, geo_polygons, and permalinks |
| Ownership | owned |
| Migrations path | `alembic/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `cards` | Stores individual campaign card definitions including content and display configuration | id, deck_id, template_id, content, status |
| `decks` | Groups of cards assembled into a campaign deck | id, campaign_id, name, status |
| `campaigns` | Top-level campaign records associated with campaign groups | id, campaign_group_id, name, status |
| `cms` | CMS content entries with versioning and archiving support | id, content, version, status, audit_trail |
| `themes` | UI theme configurations including scheduling metadata | id, name, config, scheduled_at, status |
| `templates` | Card template definitions used to standardize card creation | id, name, template_config |
| `geo_polygons` | Geographic boundary definitions used for geo-targeted campaign delivery | id, name, polygon_data, region |
| `permalinks` | Stable URL references linking to campaign or content entities | id, target_type, target_id, slug |

#### Access Patterns

- **Read**: Controllers query entities by ID, by campaign/deck association, or as full lists for display in management UIs. Card preview and CMS audit views drive targeted lookups by ID and version.
- **Write**: Operators create and update cards, decks, campaigns, CMS entries, themes, and templates via form submissions through web.py controllers. Alembic handles DDL changes.
- **Indexes**: No index definitions visible in the inventory. Standard primary key indexes assumed. Alembic migrations directory (`alembic/`) contains migration history.

## Caches

> No evidence found in codebase. No caching layer (Redis, Memcached, or in-memory) was identified in the service inventory.

## Data Flows

All reads and writes flow directly between `troniconUiWeb` and `continuumTroniconUiDatabase` via SQLAlchemy ORM. There is no evidence of CDC, ETL pipelines, materialized views, or replication to secondary stores.
