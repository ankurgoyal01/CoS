---
service: "AudiencePayloadSpark"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Audience Management"
platform: "Continuum"
team: "Audience Management (audiencedeploy)"
status: active
tech_stack:
  language: "Scala"
  language_version: "2.12.8"
  framework: "Apache Spark"
  framework_version: "2.4.8"
  runtime: "JVM"
  runtime_version: "Java 1.8 (build target)"
  build_tool: "SBT"
  build_tool_version: "1.3.13"
  package_manager: "Ivy (via SBT)"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# AudiencePayloadSpark Overview

## Purpose

AudiencePayloadSpark is a Scala/Spark batch processing library and job suite that generates audience payloads for Groupon's real-time audience management system. It reads user attributes and Published Audience (PA) membership data from Hive tables, aggregates and transforms them, and writes the results to Cassandra, AWS Keyspaces, GCP Bigtable, and Redis — making audience data available to downstream services such as RTCIA (Real-Time Consumer Intelligence API). The service ships as a fat JAR that can be submitted via `spark-submit` to a YARN cluster or imported as a library by other Spark applications such as Derivation and PublishedAudience.

## Scope

### In scope

- Reading user and bcookie system attribute tables from Hive
- Full and delta uploads of user/bcookie attributes to Cassandra and Bigtable (`user_attr2`, `bcookie_attr_v1`, `user_data_main`, `bcookie_data_main`)
- Writing and deleting PA memberships for user and bcookie audiences to Cassandra (`user_pa_v1`, `bcookie_pa_v1`)
- Aggregating SAD (Scheduled Audience Definition) PA memberships and writing results to Cassandra SAD tables (`user_sad_v1`, `bcookie_sad_v1`)
- Aggregating NonSAD PA memberships and writing results to PA aggregate tables (`user_pa_agg`, `bcookie_pa_agg`)
- Writing Consumer Authority (CA) attributes to Redis and GCP Bigtable
- Hive-to-Keyspaces retry and migration writes for SAD payloads
- Deployment automation via Python Fabric scripts (`fabfile.py`, `submit_payload.py`)

### Out of scope

- Real-time audience query or read APIs (handled by RTCIA service)
- PA definition/scheduling logic (handled by AMS API)
- Streaming or event-driven data ingestion
- Consumer identity resolution

## Domain Context

- **Business domain**: Audience Management
- **Platform**: Continuum
- **Upstream consumers**: `continuumAudiencePayloadOps` (Fabric scripts submitting Spark jobs); other Spark applications importing the library (Derivation, PublishedAudience)
- **Downstream dependencies**: Hive Metastore (source tables), AMS API (PA metadata, system table lookup), Cassandra cluster, AWS Keyspaces (`audience_service` keyspace), GCP Bigtable (`grp-prod-bigtable-rtams-ins`), Redis cluster (CA attributes)

## Stakeholders

| Role | Description |
|------|-------------|
| Audience Management engineers | Own and maintain payload generation jobs and deployment scripts |
| Audience Management operations | Execute job submissions via Fabric tasks on cerebro submitter hosts |
| RTCIA / downstream API teams | Consume attribute and membership data written to Cassandra, Bigtable, and Redis |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Scala | 2.12.8 | `build.sbt` (`scalaVersion := "2.12.8"`) |
| Framework | Apache Spark | 2.4.8 | `build.sbt` (`spark-core`, `spark-sql`, `spark-hive` % `"2.4.8"`) |
| Runtime | JVM | Java 1.8 | `.ci.yml` (`language_versions: 1.8.0_20`) |
| Build tool | SBT | 1.3.13 | `project/build.properties` |
| Package manager | Ivy (via SBT) | — | `build.sbt` (Nexus/Artifactory resolvers) |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spark-core` / `spark-sql` / `spark-hive` | 2.4.8 | framework | Distributed batch processing and Hive integration |
| `com.groupon.cde:keyspace_connector` | 0.7 | db-client | AWS Keyspaces (Cassandra-compatible) write client |
| `com.groupon.crm:bigtable_client` | 0.3.2-SNAPSHOT | db-client | GCP Bigtable write client (SADMetadata, CA attributes) |
| `redis.clients:jedis` | 2.9.0 | db-client | Redis client for CA attribute batch writes |
| `io.lettuce:lettuce-core` | 6.0.2.RELEASE | db-client | Reactive Redis client (RedisClientV2) |
| `mysql:mysql-connector-java` | 8.0.26 | db-client | MySQL JDBC connector for AMS metadata queries |
| `com.github.scopt:scopt` | 3.5.0 | cli | Command-line argument parsing for Spark job entrypoints |
| `org.json4s:json4s-native` | 3.5.0 | serialization | JSON parsing for AMS API responses and config files |
| `com.squareup.okhttp3:okhttp` | 4.6.0 | http-framework | HTTP client for AMS API calls (system table lookup, PA search) |
| `org.scalaj:scalaj-http` | 2.3.0 | http-framework | HTTP client for AMS search API calls |
| `io.grpc:grpc-netty` | 1.53.0 | rpc | gRPC transport for Bigtable client |
| `io.grpc:grpc-okhttp` | 1.56.0 | rpc | gRPC OkHttp transport provider |
| `com.holdenkarau:spark-testing-base` | 3.3.0_1.2.0 | testing | Spark unit test utilities |
| `org.cassandraunit:cassandra-unit` | 4.3.1.0 | testing | Embedded Cassandra for integration tests |
