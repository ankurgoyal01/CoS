---
service: "refresh-api-v2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Business Intelligence / Tableau Automation"
platform: "Continuum"
team: "dnd-tools"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.13.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Refresh API V2 Overview

## Purpose

Refresh API V2 is a Dropwizard-based service that automates the Tableau BI lifecycle for Groupon's data and analytics teams. It orchestrates two primary operations: (1) refreshing extract data behind Tableau workbooks and datasources from upstream warehouses (Hive, BigQuery, Teradata, Postgres), and (2) promoting workbooks and datasources from the Tableau staging environment to production. The service exposes a REST API consumed by the Optimus Prime UI and supports scheduled and webhook-triggered execution via a Quartz scheduler backed by Postgres.

## Scope

### In scope
- Triggering and monitoring Tableau extract refresh jobs (local and remote modes)
- Promoting Tableau workbooks and datasources from staging to production
- Managing Tableau user accounts, roles, and license cleanup
- Receiving and processing Tableau webhook events to trigger automated refreshes
- Managing project batch users and per-datasource source configurations
- Publishing metrics about Tableau server process health
- Integrating with Google Drive for extract file access
- Sending Opsgenie alerts on job failures

### Out of scope
- Tableau Server itself — the service calls the Tableau REST API but does not host Tableau
- The Optimus Prime UI — a separate frontend service that calls this API
- Data warehouse management — warehouses (Hive, BigQuery, Teradata) are external dependencies
- LDAP directory management — LDAP is queried read-only for user lookup

## Domain Context

- **Business domain**: Business Intelligence / Tableau Automation
- **Platform**: Continuum (DnD Tools group)
- **Upstream consumers**: Optimus Prime UI (web frontend), Tableau Server (webhooks), DeployBot (scheduled deploys)
- **Downstream dependencies**: Tableau REST API (staging and production), Tableau metadata databases (staging and production), Apache Hive (JDBC), Google BigQuery (API + JDBC), Teradata (JDBC), Postgres (own DB via JDBI), LDAP Directory, Google Drive API, Opsgenie API

## Stakeholders

| Role | Description |
|------|-------------|
| DnD Tools Team | Primary owners and developers (`dnd-tools@groupon.com`, Google Chat `#optimus-prime`) |
| Tableau Administrators | Consumers of the publish and user-management APIs |
| Data Analysts / Engineers | Benefit from automated extract refreshes keeping dashboards current |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk = 17` |
| Framework | Dropwizard | via jtier-service-pom | `pom.xml` parent `jtier-service-pom:5.13.1` |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` `prod-java17-jtier:3` |
| Build tool | Maven | inherited from jtier | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-service-pom | 5.13.1 | http-framework | Groupon JTier parent BOM providing Dropwizard and platform libraries |
| dropwizard-guicey | 5.5.0 | http-framework | Guice dependency injection integration for Dropwizard |
| jtier-quartz-bundle | inherited | scheduling | Quartz-based job scheduling backed by Postgres |
| jtier-jdbi3 | inherited | db-client | JDBI 3 data access layer for Postgres |
| jtier-daas-postgres | inherited | db-client | JTier DaaS Postgres configuration and factory |
| jdbi3-jackson2 | inherited | db-client | Jackson-based POJO serialization into DB columns |
| jtier-retrofit | inherited | http-framework | Retrofit HTTP client for Tableau REST API calls |
| tableauhyperapi | 0.0.17971 | db-client | Tableau Hyper API for in-process extract operations |
| google-cloud-bigquery | 2.19.1 | db-client | BigQuery read/query via Google Cloud SDK |
| google-cloud-bigquerystorage | 2.26.0 | db-client | BigQuery Storage API for high-throughput reads |
| GoogleBigQueryJDBC42 | 1.3.2.1003 | db-client | Simba BigQuery JDBC driver |
| terajdbc4 | 17.20.00.12 | db-client | Teradata JDBC driver |
| jtier-hive | 0.1.5 | db-client | JTier Hive connectivity library |
| google-auth-library-oauth2-http | 1.23.0 | auth | Google OAuth2 token management for GCP service accounts |
| dropwizard-auth | inherited | auth | Dropwizard authentication and authorization framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
