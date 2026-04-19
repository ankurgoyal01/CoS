---
service: "audienceDerivationSpark"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Audience Management / CRM"
platform: "Continuum"
team: "Audience Management (audiencedeploy)"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.8"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "Java 1.8"
  build_tool: "SBT"
  package_manager: "SBT / Nexus"
---

# Audience Derivation Spark Overview

## Purpose

Audience Derivation Spark is a scheduled Scala/Spark batch pipeline that transforms raw Groupon EDW and Hive source tables into enriched audience system tables used for CRM targeting and email/push marketing personalization. It processes user and bcookie (browser cookie) identifiers across two regions (NA and EMEA), executing a sequenced chain of SQL tempview transformations defined in declarative YAML configuration files. The derived output tables are the primary data source for downstream audience payload delivery systems.

## Scope

### In scope

- Executing multi-step SQL derivation pipelines for `users_derived` and `bcookie_derived` Hive tables for NA and EMEA regions
- Running universal audience derivation (region-agnostic flow)
- Generating LINK SAD base-table datasets for deal-targeting optimization
- Synchronizing derived Hive schema field metadata to the AMS (Audience Management System) database
- Validating CQD (Customer Query Definition) field definitions against Hive and AMS state
- Uploading YAML derivation configuration to HDFS before each job run
- Submitting and managing Spark applications on a YARN cluster via `spark-submit`

### Out of scope

- Audience payload delivery or formatting (handled by `AudiencePayloadSpark`)
- CRM campaign creation or execution
- Real-time user profile updates
- Deal or order processing logic
- Schema ownership of raw source tables (owned by EDW/DW teams)

## Domain Context

- **Business domain**: Audience Management / CRM
- **Platform**: Continuum
- **Upstream consumers**: Downstream delivery pipelines (Cassandra audience payload writes, Bigtable delta attribute ingestion), email/push campaign systems reading from derived Hive tables
- **Downstream dependencies**: Hive Metastore (source and output tables), HDFS (config and intermediate storage), AMS API (system table name lookup and field metadata sync), YARN cluster (job execution), Splunk (execution logs)

## Stakeholders

| Role | Description |
|------|-------------|
| Audience Management Engineering | Owns, deploys, and operates the derivation pipeline |
| CRM / Marketing Engineering | Consumes derived audience tables for campaign targeting |
| Data Engineering | Maintains source EDW/Hive tables consumed as inputs |
| Audience Ops (audiencedeploy) | Deploys artifacts and kicks off scheduled jobs via Fabric |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.8 | `build.sbt`: `scalaVersion := "2.12.8"` |
| Framework | Apache Spark | 2.4.8 | `build.sbt`: `spark-core`, `spark-sql`, `spark-hive` at 2.4.8 |
| Runtime | JVM | Java 1.8 | `.ci.yml`: `language_versions: 1.8.0_20` |
| Build tool | SBT with sbt-assembly | — | `build.sbt`, `project/assembly.sbt` |
| Package manager | SBT / Nexus Artifactory | — | `build.sbt` resolvers pointing to `nexus-app1-dev.snc1` and `artifactory.groupondev.com` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `audiencepayloadspark` | 1.56.9-SNAPSHOT | db-client | Audience payload write utilities for Cassandra/Bigtable |
| `snakeyaml` | 1.20 | serialization | Parses YAML derivation configuration files |
| `scopt` | 3.5.0 | validation | CLI argument parsing for Spark job entrypoints |
| `json4s-native` | 3.5.0 | serialization | JSON field configuration parsing |
| `nscala-time` | 2.30.0 | scheduling | Date/time utilities for derivation timestamps |
| `grpc-netty` / `grpc-okhttp` | 1.53.0 / 1.56.0 | http-framework | gRPC transport for AMS API communication |
| `spring-context` | 5.3.18 | http-framework | Dependency injection for component wiring |
| `spark-testing-base` | 3.3.0_1.2.0 | testing | Spark unit test scaffolding |
| `scalatest` | 3.0.2 | testing | Unit test framework |
| `gson` | 2.8.4 | serialization | Google JSON serialization utilities |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `build.sbt` for a full list.
