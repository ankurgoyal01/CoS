---
service: "minos"
title: Overview
generated: "2026-03-03"
type: overview
domain: "3PIP Ingestion / Deal Deduplication"
platform: "Continuum"
team: "Minos (3pip-ingestion@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Minos Overview

## Purpose

Minos is the 3PIP (Third-Party Ingestion Pipeline) duplicate-deal detection service for Groupon's Continuum platform. It determines whether an incoming third-party deal is a duplicate of an existing deal in the Groupon deal catalog by querying a local Elasticsearch index seeded from Relevance snapshots, enriching candidates with metadata from upstream services, and scoring them via the Flux ML model. The service also manages duplicate score overrides, recall lookup lists, and orchestrates periodic scoring refresh jobs.

## Scope

### In scope

- Accepting ingestion deal payloads and returning a ranked list of duplicate deal catalog IDs
- Persisting ingestion deals, duplicate matches, and duplicate score values to PostgreSQL
- Managing manual duplicate score overrides (create, read, delete)
- Maintaining a recall lookup list (PDS-id-to-deal mapping) sourced from Cerebro and backed by PostgreSQL
- Querying the Relevance Elasticsearch index to retrieve candidate duplicate deals
- Enriching candidate deals with data from Deal Catalog, Lazlo, Universal Merchant API, and Taxonomy service
- Submitting scoring jobs to the Flux ML platform and uploading/downloading scoring artifacts via HDFS/S3
- Exposing a `/v1/flux/report` endpoint that prepares deal-pair payloads in Flux-compatible format
- Scheduling periodic scoring refresh via an embedded Quartz job
- Maintaining a dedicated Elasticsearch sub-cluster that restores Relevance deal-index snapshots from HDFS

### Out of scope

- Ingesting raw third-party deal data (handled by the upstream ingestion pipeline)
- Publishing deals to the Groupon deal catalog (handled by Deal Catalog service)
- Running ML model training (handled by the Data Science / Flux platform)
- Customer-facing deal serving or search

## Domain Context

- **Business domain**: 3PIP Ingestion / Deal Deduplication
- **Platform**: Continuum
- **Upstream consumers**: 3PIP ingestion pipeline (submits deals for duplicate checking); internal tools that manage score overrides
- **Downstream dependencies**: Relevance API (candidate search), Deal Catalog (deal details), Lazlo API (deal metadata), Universal Merchant API (merchant details), Taxonomy Service (categories), Flux/DS platform (ML scoring), Cerebro (recall lookup source), HDFS (scoring artifacts and ES snapshots), AWS S3 (scoring payload files)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Minos | Owns and operates the service; contact 3pip-ingestion@groupon.com |
| Ingestion team | Primary on-call for PagerDuty alerts (ingestion@groupon.pagerduty.com) |
| Data Science / Flux team | Owns the ML scoring platform that Minos submits jobs to |
| Deal Catalog team | Owns the canonical deal store that Minos queries for candidate enrichment |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` maven-compiler-plugin source/target |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | Java 11 | `.java-version` |
| Build tool | Maven | mvnvm managed | `mvnvm.properties`, `pom.xml` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | JTier managed | db-client | JTier DaaS PostgreSQL integration (connection pool, migrations) |
| jtier-jdbi | JTier managed | orm | JDBI-based DAO layer over PostgreSQL |
| jtier-migrations | JTier managed | db-client | Flyway-backed schema migrations |
| jtier-okhttp | JTier managed | http-framework | Managed OkHttp client for upstream REST calls |
| jtier-quartz-bundle | JTier managed | scheduling | Dropwizard-integrated Quartz scheduler |
| jtier-quartz-postgres-migrations | JTier managed | scheduling | Quartz job store schema migrations on PostgreSQL |
| dropwizard-redis | JTier managed | db-client | Redis integration for Dropwizard (Jedis-backed) |
| hadoop-client | 2.8.1 | integrations | HDFS client for reading/writing scoring artifacts and Relevance snapshots |
| amazon-sqs-java-messaging-lib | 1.0.4 | message-client | AWS SQS JMS integration |
| aws-java-sdk-s3 | 1.12.205 | integrations | AWS S3 SDK for uploading/downloading DS scoring payload files |
| software.amazon.awssdk:s3 | 2.7.20 | integrations | AWS S3 SDK v2 |
| jackson-dataformat-csv | 2.9.5 | serialization | CSV serialization for deal-pair export payloads |
| org.immutables:value | JTier managed | validation | Immutable value objects for domain model |
| jtier-swagger-dropwizard | JTier managed | http-framework | Swagger/OpenAPI spec generation for Dropwizard resources |
