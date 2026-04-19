---
service: "mds-feed-api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Marketing / Affiliate Feeds"
platform: "Continuum"
team: "Marketing Services"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Marketing Feed Service (mds-feed-api) Overview

## Purpose

The Marketing Deal Feed Service (mds-feed-api) consolidates all paid marketing channel deal feed requirements into a single self-service REST API. It allows operations teams and affiliate managers to define, schedule, monitor, and upload deal feed files without engineering intervention. Feed generation itself is delegated to a companion Apache Spark job (`mds-feed-job`), which this service orchestrates via Apache Livy.

## Scope

### In scope

- Creating, updating, and managing feed configurations (datasources, filters, transformers, fields, file formats)
- Organizing feed configurations into feed groups
- Scheduling feed generation using cron expressions via Quartz
- Submitting and monitoring Apache Spark feed generation jobs via Apache Livy
- Tracking Spark batch state (running, success, dead)
- Dispatching download URLs for generated feed files stored in GCS
- Uploading generated feed files to external destinations (S3, SFTP/FTP, GCP)
- Recording feed generation metrics and computing statistics
- Managing upload profiles and SSH key pairs for SFTP destinations
- Publishing feed completion events to the Groupon Message Bus (Mbus) on the `mds-feed-publishing` destination
- Audit logging of feed configuration changes

### Out of scope

- Actual feed file generation (handled by `mds-feed-job` Spark job)
- Deal data sourcing and ETL (handled by upstream GCS / BigQuery pipelines)
- Consumer-facing marketing execution (handled by downstream marketing platforms)
- Denylisting logic beyond what is exposed as a datasource type

## Domain Context

- **Business domain**: Marketing / Affiliate Feeds
- **Platform**: Continuum
- **Upstream consumers**: Operations teams, affiliate managers, marketing platforms that poll generated feed files; `mds-feed-job` Spark job posts metrics back via `/metrics`
- **Downstream dependencies**: Apache Livy (Spark job submission), PostgreSQL (transactional store), Google Cloud Storage / BigQuery (feed artifact storage), Groupon Message Bus (event publishing), S3 (upload destination), SFTP/FTP partners (upload destinations)

## Stakeholders

| Role | Description |
|------|-------------|
| Marketing Services Engineering | Owns and maintains the service (`mis-engineering@groupon.com`) |
| SRE / Alerts | `feed-service-alerts@groupon.com`, PagerDuty `PB2L7F5` |
| Affiliate Managers / Ops Teams | Primary consumers of the self-service feed configuration API |
| mds-feed-job | Companion Spark job that generates actual feed files and posts metrics back |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `pom.xml` `project.build.targetJdk` |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `.java-version` |
| Build tool | Maven | - | `pom.xml`, `.mvn/` directory |
| Package manager | Maven | - | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | (BOM) | db-client | PostgreSQL connection pooling and datasource |
| jtier-jdbi | (BOM) | orm | JDBI DAO layer for SQL access |
| jtier-migrations | (BOM) | db-client | PostgreSQL schema migrations |
| jtier-quartz-bundle | (BOM) | scheduling | Quartz scheduler integration for cron jobs |
| jtier-messagebus-client | (BOM) | message-client | Groupon Message Bus (Mbus/JMS) publisher |
| jtier-retrofit | (BOM) | http-framework | Retrofit HTTP client for Livy GCP API calls |
| jtier-auth-bundle | (BOM) | auth | Client ID authentication bundle |
| aws-java-sdk-s3 | 1.12.248 | storage | S3 upload destination |
| aws-java-sdk-sts | 1.12.276 | auth | AWS STS credential management for S3 |
| google-cloud-storage | 1.111.2 | storage | GCP Cloud Storage (GCS) access for feed files |
| json-patch | 1.9 | serialization | JSON Patch (RFC 6902) support for PATCH endpoint |
| json-path | 2.4.0 | serialization | JSONPath expression evaluation |
| jsch | 0.1.55 | integration | SFTP/SSH upload to marketing partners |
| commons-net | 3.9.0 | integration | FTP upload to marketing partners |
| resilience4j-retry | 1.0.0 | validation | Retry logic for resilient operations |
| vavr | 0.10.0 | validation | Functional programming utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
