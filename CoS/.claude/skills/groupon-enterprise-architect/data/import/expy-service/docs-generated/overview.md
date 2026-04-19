---
service: "expy-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Experimentation"
platform: "Continuum"
team: "Optimize (aspatil, optimize@groupon.com)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard (JTier)"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Expy Service Overview

## Purpose

Expy Service acts as a centralized interface between Optimizely and Groupon, abstracting the Optimizely experimentation platform behind a single internal REST API. It manages experiment and feature flag configuration, maintains a local copy of Optimizely datafiles in MySQL and S3, and performs bucketing decisions on behalf of callers. By centralizing this integration, it prevents every consumer service from directly coupling to the Optimizely SDK or CDN.

## Scope

### In scope

- Experiment bucketing and variation decisions via the Optimizely core API
- Feature flag CRUD — create, read, update, delete feature-manager entities
- Experiment CRUD via experiment-manager endpoints
- Audience definition and access-policy management
- Project registration and SDK key management
- Scheduled refresh of Optimizely datafiles from CDN and Data Listener
- Daily S3 backup/copy of datafiles from the Optimizely S3 bucket to the Groupon S3 bucket
- Datafile parse-error logging to MySQL
- Birdcage flag integration (`/birdcage/*` endpoints)

### Out of scope

- Raw event tracking to Optimizely (handled by direct SDK integrations in consumers)
- A/B test result analysis and reporting (Optimizely platform concern)
- Feature flag evaluation for non-Groupon tenants
- Canary traffic management logic (Canary API is a dependency, not owned here)

## Domain Context

- **Business domain**: Experimentation
- **Platform**: Continuum
- **Upstream consumers**: Any Groupon internal service that needs experiment bucketing or feature flag evaluation; Birdcage (internal flag system)
- **Downstream dependencies**: Optimizely CDN, Optimizely API, Optimizely Data Listener, Optimizely S3 Bucket, Groupon S3 Bucket, Canary API, MySQL (`continuumExpyMySql`), Birdcage

## Stakeholders

| Role | Description |
|------|-------------|
| Team | Optimize — owns service development and operations (optimize@groupon.com) |
| Lead | aspatil — primary contact for architecture questions |
| Consumers | Internal Groupon services requiring experiment bucketing or feature-flag evaluation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Summary / Maven pom |
| Framework | Dropwizard (JTier) | 5.14.0 | Summary — jtier 5.14.0 |
| Runtime | JVM | 11 | Summary |
| Build tool | Maven | — | Summary |
| Package manager | Maven | — | Summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| optimizely-core-api | 4.1.1 | http-framework | Optimizely Java SDK for bucketing decisions and datafile management |
| jtier-daas-mysql | (JTier BOM) | db-client | JTier-managed MySQL data access |
| jtier-jdbi | (JTier BOM) | orm | JDBI DAO layer for MySQL reads/writes |
| jtier-quartz-bundle | (JTier BOM) | scheduling | Quartz scheduler integration for periodic jobs |
| jtier-retrofit | (JTier BOM) | http-framework | JTier-managed Retrofit HTTP client factory |
| retrofit2 | 2.9.0 | http-framework | HTTP client for Optimizely API, CDN, and Data Listener calls |
| jackson | 2.17.1 | serialization | JSON serialization/deserialization |
| mapstruct | 1.5.5 | validation | Bean mapping between API, service, and persistence layers |
| rxjava3 | 3.1.9 | http-framework | Reactive composition for async external calls |
| aws-sdk-s3 (BOM) | 2.16.39 | db-client | AWS S3 client for datafile backup and copy operations |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
