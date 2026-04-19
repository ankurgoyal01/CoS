---
service: "taxonomyV2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Taxonomy / Catalog"
platform: "Continuum"
team: "taxonomy"
status: active
tech_stack:
  language: "Java"
  language_version: "11.0.7"
  framework: "Dropwizard"
  framework_version: "1.3.5 (views-freemarker)"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Taxonomy V2 Overview

## Purpose

Taxonomy V2 is Groupon's authoritative source of truth for all taxonomic data — it stores and serves the hierarchical category structures used to classify businesses, deals, and merchant offerings across all Groupon platforms. The service manages category trees, inter-category relationships, locale-specific translations, content snapshots, and deployment workflows that push versioned taxonomy content to live environments. It does not store deal-to-category or merchant-to-category mappings — only the structural taxonomy itself.

## Scope

### In scope

- Managing the full taxonomy tree: taxonomies, categories, parent-child relationships, and relationship types
- Serving category data with locale-specific names and attributes in real time
- Authoring and deploying versioned taxonomy content snapshots (full and partial)
- Maintaining a Redis-backed denormalized cache for low-latency reads (~77K rpm throughput)
- Invalidating Varnish edge cache nodes when content is activated
- Sending deployment notifications via Slack and email
- Providing an internal HTML management UI for taxonomy operations

### Out of scope

- Storing which deals, places, or merchants belong to a category (handled by downstream deal/merchant services)
- Taxonomy content authoring (handled by the upstream `continuumTaxonomyV2AuthoringService`)
- Consumer-facing category display logic (handled by frontend/MBNXT)

## Domain Context

- **Business domain**: Taxonomy / Catalog
- **Platform**: Continuum
- **Upstream consumers**: Deal platform services, merchant platform services, search/browse services, and any internal service needing category lookups
- **Downstream dependencies**: PostgreSQL (DaaS), Redis (RaaS), JMS Message Bus (mbus), Slack HTTP API, SMTP Email Gateway, Varnish Edge Cache Cluster, Taxonomy Authoring Service

## Stakeholders

| Role | Description |
|------|-------------|
| Team | taxonomy — taxonomy-dev@groupon.com |
| Mailing list | taxonomy-users@groupon.com |
| On-call / PagerDuty | taxonomy-dev@groupon.pagerduty.com, PD service PVUUEHR |
| Slack | #taxonomy (channel CF7MW8SJV) |
| Criticality tier | Tier 1 |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11.0.7 | `.java-version` |
| Framework | Dropwizard (JTier) | 1.3.x | `pom.xml` |
| Runtime | JVM | 11 | `pom.xml` (`project.build.targetJdk`) |
| Build tool | Maven | jtier-service-pom 5.14.0 | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-daas-postgres` | (BOM) | db-client | Managed PostgreSQL connectivity via DaaS |
| `jtier-jdbi` | (BOM) | orm | JDBI-based SQL access layer |
| `jtier-migrations` | (BOM) | db-client | Database schema migration support |
| `jtier-auth-bundle` | (BOM) | auth | JTier authentication and authorization bundle |
| `jtier-messagebus-client` | (BOM) | message-client | JMS message bus integration (publish/consume) |
| `jtier-okhttp` | (BOM) | http-framework | OkHttp client for outbound HTTP calls |
| `redisson` | 3.2.4 | state-management | Redis client for distributed caching (cache-aside) |
| `dropwizard-views-freemarker` | 1.3.5 | ui-framework | Server-side HTML view rendering for internal UI |
| `dropwizard-assets` | 1.0.4 | ui-framework | Static asset serving for internal UI |
| `RosettaJdbi` | 3.11.2 | orm | HubSpot Rosetta JDBI mapper for JSON-friendly row mapping |
| `lombok` | 1.18.22 | serialization | Boilerplate reduction (builders, getters/setters) |
| `poi` / `poi-ooxml` | 3.14 | serialization | Apache POI for Excel/CSV taxonomy data import |
| `javax.mail` | 1.4.7 | messaging | SMTP email notifications for deployment events |
| `junit` + `assertj-core` | (BOM) | testing | Unit and assertion testing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
