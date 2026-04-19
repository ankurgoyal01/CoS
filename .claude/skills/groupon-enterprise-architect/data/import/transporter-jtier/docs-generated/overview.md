---
service: "transporter-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Salesforce Integration"
platform: "Continuum"
team: "Salesforce Integration"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Transporter JTier Overview

## Purpose

Transporter JTier is the backend service that handles user requests originated from the Transporter ITier frontend. It manages Salesforce OAuth token lifecycle, orchestrates CSV-based bulk data uploads to Salesforce via background Quartz jobs, and stores all upload job state and user records in a MySQL database. The service bridges an internal upload UI with Salesforce's bulk data APIs, using AWS S3 and GCS for file staging.

## Scope

### In scope

- Authenticating Salesforce users via OAuth2 and caching their tokens in Redis
- Accepting CSV upload submissions from `transporter-itier` and persisting upload job records in MySQL
- Executing Salesforce bulk data operations (insert, update, delete) through the `sf-upload-worker` Quartz job
- Serving upload job status and history to the ITier frontend
- Reading input CSV files from AWS S3 and writing result files to GCS
- Exposing a list of available Salesforce objects for the read-only UI page

### Out of scope

- Frontend rendering and user-facing UI (handled by `transporter-itier`)
- Direct Salesforce CRM configuration or administration
- Groupon order or deal processing
- Marketing or reporting pipelines

## Domain Context

- **Business domain**: Salesforce Integration
- **Platform**: Continuum
- **Upstream consumers**: `transporter-itier` calls REST endpoints to submit uploads and check job status
- **Downstream dependencies**: Salesforce (OAuth2/REST), AWS S3 (input file storage), GCS (result file storage), MySQL (job and user persistence), Redis (token cache)

## Stakeholders

| Role | Description |
|------|-------------|
| Salesforce Integration Team | Service owner and primary developer team (`sfint-dev@groupon.com`) |
| Team Owner | dbertelkamp |
| SRE / Ops | Alerts via PagerDuty service `PLUGT8Z`, Slack channel `salesforce-integration` |
| Salesforce Admins | End-users who operate the Transporter upload UI |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` maven-compiler-plugin source/target |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | Java 11 | `pom.xml` |
| Build tool | Maven | mvnvm-managed | `mvnvm.properties`, `pom.xml` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-service-pom | 5.14.0 | http-framework | Base Dropwizard JTier service scaffolding |
| jtier-daas-mysql | parent-managed | db-client | DaaS MySQL integration for JTier |
| jtier-jdbi | parent-managed | orm | JDBI v2 DAO support |
| jtier-jdbi3 | parent-managed | orm | JDBI v3 DAO support |
| jtier-migrations | parent-managed | db-client | Flyway-based schema migrations via JTier |
| flyway-core | parent-managed | db-client | SQL migration execution |
| jtier-quartz-bundle | parent-managed | scheduling | Quartz scheduler bundle for background upload jobs |
| dropwizard-redis | parent-managed | db-client | Redis integration for Dropwizard |
| SalesforceHttpClient | 1.15 | http-framework | Groupon internal Salesforce HTTP client |
| software.amazon.awssdk (s3, sts, auth) | 2.9.10 | db-client | AWS SDK v2 for S3 file access and STS role assumption |
| google-cloud-storage | 1.111.2 | db-client | GCS client for writing result files and generating signed URLs |
| jackson-dataformat-csv | parent-managed | serialization | CSV parsing and writing for upload payloads |
| org.json | 20200518 | serialization | JSON manipulation for Salesforce API payloads |
| jacoco-maven-plugin | parent-managed | testing | Code coverage reporting |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
