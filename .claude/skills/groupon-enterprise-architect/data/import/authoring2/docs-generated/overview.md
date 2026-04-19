---
service: "authoring2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Taxonomy"
platform: "Continuum"
team: "taxonomy"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Jersey/JAX-RS"
  framework_version: "2.35"
  runtime: "Apache Tomcat"
  runtime_version: "7.0.109"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Authoring2 Overview

## Purpose

Authoring2 is the system of record for Groupon's product and deal category taxonomy. It provides a REST API and an Ember.js-backed UI that allows taxonomy content authors to create, modify, and organize the hierarchical category tree (taxonomies, categories, relationships, attributes, and locale translations) that underpins deal and merchant categorization across Groupon. Approximately every three weeks, content authors deploy the staged taxonomy changes to the live `TaxonomyV2` serving tier via a snapshot mechanism.

## Scope

### In scope

- CRUD management of taxonomies, categories, relationships, and category attributes
- Locale-aware category editing (multi-language support)
- Bulk ingestion of category and translation data via CSV/XLS file upload
- Snapshot creation, staging deployment, certification, and live activation
- Partial snapshot creation targeting a subset of taxonomies
- Category tree export to CSV and XLS formats
- Audit history tracking for taxonomies and categories
- User and permission/role management for authoring access
- ActiveMQ-backed asynchronous queue processing for bulk and snapshot jobs

### Out of scope

- Serving taxonomy data to downstream consumers (handled by `continuumTaxonomyService`)
- Classification of deals, merchants, or places into categories
- Consumer-facing search or category browse experiences

## Domain Context

- **Business domain**: Taxonomy
- **Platform**: Continuum
- **Upstream consumers**: Taxonomy content authors (internal UI users via the Ember.js authoring tool at `https://taxonomy-authoringv2.groupondev.com`)
- **Downstream dependencies**: `continuumTaxonomyService` (receives snapshot activation calls via HTTP PUT)

## Stakeholders

| Role | Description |
|------|-------------|
| Taxonomy content authors | Internal users who manage the category hierarchy day-to-day via the UI |
| Taxonomy engineering team | Owners of the service (`taxonomy-dev@groupon.com`, Slack `#taxonomy`) |
| SRE / on-call | Alert recipient via PagerDuty `PVUUEHR` and email `taxonomy-alerts@groupon.com` |
| Downstream taxonomy consumers | Services such as GAPI and LPAPI that consume live taxonomy data from TaxonomyV2 |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `<project.build.targetJdk>11</project.build.targetJdk>` |
| Framework | Jersey / JAX-RS | 2.35 | `pom.xml` `jersey.version` |
| Runtime | Apache Tomcat | 7.0.109 | `pom.xml` `tomcat.version` |
| Build tool | Maven | — | `pom.xml` |
| ORM | EclipseLink JPA | 2.6.9 | `pom.xml` `eclipselink` dependency |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jersey-container-servlet` | 2.35 | http-framework | JAX-RS servlet container integration |
| `resteasy-jaxrs` | 3.5.1.Final | http-framework | Alternative JAX-RS implementation (legacy reference) |
| `eclipselink` | 2.6.9 | orm | JPA entity management and JPQL queries |
| `postgresql` | 42.7.3 | db-client | PostgreSQL JDBC driver |
| `activemq-core` | 5.7.0 | message-client | JMS producer/consumer for bulk and snapshot queues |
| `jackson-databind` | 2.12.2 | serialization | JSON serialization/deserialization |
| `jackson-dataformat-yaml` | 2.9.2 | serialization | YAML config parsing |
| `logback-steno` | 1.18.0 | logging | Structured JSON logging |
| `tracky-java-logger` | 0.0.1 | logging | Groupon Tracky 2.0 structured log integration |
| `micrometer-registry-influx` | 1.8.4 | metrics | InfluxDB metrics export |
| `micrometer-registry-jmx` | 1.8.4 | metrics | JMX metrics export |
| `app-config` | 1.4 | configuration | Groupon AppConfig environment-based property loading |
| `poi-ooxml` | 3.10-FINAL | serialization | XLS/XLSX file generation for category locale export |
| `opencsv` | 3.1 | serialization | CSV parsing and generation for bulk import/export |
| `lombok` | 1.18.24 | validation | Boilerplate reduction via code generation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
