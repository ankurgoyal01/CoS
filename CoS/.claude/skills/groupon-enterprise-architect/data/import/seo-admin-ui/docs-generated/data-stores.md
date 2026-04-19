---
service: "seo-admin-ui"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "neo4jSeo"
    type: "neo4j"
    purpose: "Page ranking and crosslinks graph"
  - id: "memcachedSeoAdminUi"
    type: "memcached"
    purpose: "Session and API response caching"
---

# Data Stores

## Overview

seo-admin-ui uses two data stores: a Neo4j graph database for page ranking and crosslinks analysis, and Memcached for session management and API response caching. The service does not own a relational database; its primary structured data is held in downstream services (LPAPI, SEO Deal API, etc.) which it accesses via API.

## Stores

### Neo4j SEO Graph (`neo4jSeo`)

| Property | Value |
|----------|-------|
| Type | neo4j |
| Architecture ref | `neo4jSeo` |
| Purpose | Stores page ranking data and crosslink relationships between Groupon pages for SEO analysis |
| Ownership | shared |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Page nodes | Represent individual Groupon pages in the crosslinks graph | URL, page type, rank score |
| Crosslink relationships | Directed edges between pages representing internal linking | source URL, target URL, link type |

#### Access Patterns

- **Read**: Queries page rank scores and traverses crosslink graph for a given starting page; used by the Crosslinks Analyzer component
- **Write**: > No evidence found in codebase. Write access pattern not confirmed from inventory.
- **Indexes**: > No evidence found in codebase.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `memcachedSeoAdminUi` | memcached | Session data storage and API response caching to reduce downstream latency | > No evidence found in codebase. |

## Data Flows

seo-admin-ui reads page and crosslink graph data from Neo4j to power the Crosslinks Analyzer UI component. API responses from downstream services (LPAPI, Deal Catalog, etc.) are transiently cached in Memcached to reduce repeat call overhead. Session tokens issued by itier-user-auth are stored in Memcached for fast lookup on subsequent requests.
