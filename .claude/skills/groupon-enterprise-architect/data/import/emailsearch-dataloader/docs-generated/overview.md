---
service: "emailsearch-dataloader"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Email / Push Campaign Optimization"
platform: "Continuum"
team: "Rocketman"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard (JTier)"
  framework_version: "jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Email Search Dataloader Overview

## Purpose

The Email Search Dataloader is a scheduled and event-driven backend service that ingests email and push campaign performance data, evaluates statistical significance of A/B treatment experiments, and makes automated decisions to roll out winning treatments via the Campaign Management Service. It also exports statistical significance metrics to the Hive data warehouse for reporting and analytics, and posts operational notifications to team chat channels.

The service is the analytics and decision brain of the Rocketman email/push campaign platform, bridging raw delivery event data with campaign execution outcomes for the Turbo and Phrasee/Engage experiment types.

## Scope

### In scope

- Consuming Kafka delivery, bounce, and unsubscribe events from the email cluster
- Evaluating campaign treatment statistical significance (click, open, GP metrics) across email and push platforms
- Scheduling and executing automated campaign rollout decisions via Quartz jobs
- Exposing a REST API for querying campaign performance data
- Querying and writing campaign performance metrics to PostgreSQL (Email Search and Decision Engine databases)
- Reading campaign performance data from MySQL (Campaign Performance database)
- Exporting statistical significance metrics to the Hive data warehouse (ORC/Snappy, partitioned tables)
- Uploading Phrasee/Engage campaign performance results to the Phrasee service
- Managing user unsubscriptions triggered by Kafka events
- Maintaining bounce configuration data
- Sending operational notifications to Slack and Google Chat webhooks

### Out of scope

- Sending emails or push notifications (handled by Rocketman Commercial and campaign execution services)
- Campaign creation, scheduling, and management (handled by Campaign Management Service)
- User targeting and audience segmentation (handled by Arbitration Service)
- Inbox management and deliverability UI (handled by Inbox Management Email/Push UI services)
- Long-term analytics storage beyond Hive export (handled by downstream analytics platform)

## Domain Context

- **Business domain**: Email / Push Campaign Optimization
- **Platform**: Continuum
- **Upstream consumers**: No inbound consumers documented; API is consumed internally for campaign performance lookup
- **Downstream dependencies**: Campaign Management Service (rollout decisions), Campaign Performance Service (performance reads), Inbox Management Services (inbox metrics), Arbitration Service (user cadence), Phrasee Service (Engage upload), Subscription Service (unsubscribe management), Rocketman Commercial Service (GP data), ELK Data Service NA/EMEA (logging queries), Wavefront (metrics), Slack/GChat webhooks (notifications), Hive warehouse (analytics export), PostgreSQL x2 (operational state), MySQL (performance reads)

## Stakeholders

| Role | Description |
|------|-------------|
| Rocketman Team | Service owner responsible for campaign optimization and delivery |
| Email/Push Platform Engineers | Consumers of campaign performance API and decision outcomes |
| Analytics / Data Engineering | Consumers of Hive exported metrics tables |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` — `project.build.targetJdk = 17`, `maven-compiler-plugin source/target = 17` |
| Framework | Dropwizard / JTier | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` — `prod-java17-jtier:2023-12-19-609aedb` |
| Build tool | Maven | mvnvm managed | `mvnvm.properties`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-quartz-bundle` | managed | scheduling | Quartz-based scheduled job runner integrated with Dropwizard |
| `jtier-quartz-postgres-migrations` | managed | scheduling | Quartz job state persistence in PostgreSQL |
| `jtier-daas-postgres` | managed | db-client | PostgreSQL DaaS connection pooling (HikariCP) |
| `jtier-daas-mysql` | managed | db-client | MySQL DaaS connection pooling |
| `jtier-jdbi3` | managed | orm | JDBI3 data access layer |
| `jtier-migrations` | managed | db-client | Database schema migration support |
| `jtier-retrofit` | managed | http-framework | Retrofit HTTP client integration with JTier |
| `kafka-clients` | 3.1.0 | message-client | Apache Kafka producer/consumer client |
| `kafka-message-serde` | 2.2 | serialization | Groupon DSE Kafka message serialization/deserialization |
| `hive-jdbc` | 2.0.0 | db-client | Hive JDBC driver for analytics warehouse queries |
| `resilience4j-retry` | 1.7.1 | http-framework | Retry logic for downstream HTTP calls |
| `commons-math3` | 3.6.1 | validation | Statistical significance calculations (z-test / chi-square) |
| `lombok` | 1.18.26 | serialization | Boilerplate code generation (builders, immutables) |
| `stringtemplate` | 3.2.1 | serialization | SQL/string template generation for Hive queries |
| `commons-dbutils` | 1.6 | db-client | Lightweight JDBC utilities |
