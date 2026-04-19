---
service: "lpapi"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "SEO / Landing Pages"
platform: "Continuum"
team: "SEO Landing Pages API (lpapi@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Dropwizard / JTier"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# LPAPI Overview

## Purpose

LPAPI (Landing Page API) is the authoritative data service for Groupon's SEO-driven URL surfaces: `/local`, `/goods`, and `/travel`. It manages the full lifecycle of landing page records — their creation, taxonomy categorization, URL routing, crosslinks, and attribute metadata. The service also coordinates two background workers that enrich pages with indexability signals and user-generated content (UGC) review data.

## Scope

### In scope

- CRUD operations for landing page records, routes, crosslinks, and attribute types
- URL-to-route resolution and site/locale-aware page lookup
- Taxonomy category import and synchronization from the Taxonomy Service
- Division and location hierarchy management
- Automated indexability analysis of landing pages (via Auto Indexer worker)
- Merchant UGC review ingestion and normalization (via UGC Worker)
- Autocomplete and batch edit operations for attribute types

### Out of scope

- Serving the rendered HTML of landing pages (handled by a downstream routing/rendering service)
- Consumer-facing search or deal ranking (handled by Relevance API)
- Order processing, payments, or merchant onboarding
- Crawling or indexing management at the search-engine level (Google Search Console is a read-only signal source)

## Domain Context

- **Business domain**: SEO / Landing Pages
- **Platform**: Continuum
- **Upstream consumers**: SEO tooling, internal CMS operators, automated indexing pipelines
- **Downstream dependencies**: `continuumTaxonomyService` (taxonomy data), `continuumRelevanceApi` (deal/merchant signals), `continuumUgcService` (review data), Google Search Console (optional GSC metrics, stub only)

## Stakeholders

| Role | Description |
|------|-------------|
| SEO Landing Pages API Team | Service owners; contact lpapi@groupon.com |
| SEO Engineers | Primary operators and feature developers |
| Content/CMS Operators | Use API to create and manage landing page records |
| Platform Architecture | Consumers of the C4 model and federation data |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | — | Inventory |
| Framework | Dropwizard / JTier | — | Inventory |
| Runtime | JVM | — | Inventory |
| Build tool | Maven | — | Inventory |
| Deployment tool | Capistrano | — | Inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| JDBI | — | db-client | SQL data access layer for PostgreSQL (DAOs and adapters) |
| Dropwizard Configurable Assets | 1.0.5 | http-framework | Static asset serving with configurable paths |
| JSoup | — | serialization | HTML parsing used during page content analysis |
| LPURL | — | validation | Landing page URL parsing and normalization |
| JSONB Expressions | — | db-client | PostgreSQL JSONB query expression support |
| JTier Taxonomy Client | — | http-framework | Typed client for the Taxonomy Service integration |
| StringTemplate | 3.2 | serialization | Template engine for page/content generation |
| OkHttp | — | http-framework | HTTP client for downstream REST calls (RAPI, UGC, GSC) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
