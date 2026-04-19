---
service: "seer-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Engineering Effectiveness"
platform: "Continuum"
team: "svuppalapati"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "JTier jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Seer Service Overview

## Purpose

Seer Service is an engineering-metrics aggregation platform that pulls data from seven external developer-tooling systems (Jira, Jenkins, GitHub Enterprise, Deploybot, OpsGenie, SonarQube, and the internal Service Portal), normalises it, and stores it in a PostgreSQL database. Scheduled Quartz jobs automate periodic data ingestion, while a REST API exposes the collected metrics and reports to internal consumers. The service exists to provide a unified, queryable source of engineering-effectiveness data for dashboards, retrospectives, and incident analysis.

## Scope

### In scope

- Aggregating sprint reports, issue metadata, and incident data from Jira
- Collecting Jenkins CI build information (build times, success rates)
- Ingesting GitHub Enterprise pull-request data enriched with service ownership metadata
- Fetching Deploybot deployment records per service and environment
- Ingesting OpsGenie alert and on-call team data
- Collecting SonarQube code-quality metrics per project
- Resolving service ownership via the Service Portal
- Storing all ingested data in an owned PostgreSQL instance
- Exposing REST endpoints to query stored metrics and trigger manual data uploads
- Running scheduled Quartz jobs for automated weekly data ingestion

### Out of scope

- Generating end-user dashboards (consumed by downstream analytics tools)
- Managing Jira projects, Jenkins pipelines, or GitHub repositories directly
- Sending alerts or notifications to teams (OpsGenie is read-only)
- SLA enforcement or policy management

## Domain Context

- **Business domain**: Engineering Effectiveness / Developer Productivity
- **Platform**: Continuum
- **Upstream consumers**: Internal analytics dashboards and reporting tools that query the Seer REST API
- **Downstream dependencies**: Jira, Jenkins, GitHub Enterprise, Deploybot, OpsGenie, SonarQube, Service Portal (all via HTTP/JSON using Retrofit clients)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | svuppalapati team — responsible for development and operations |
| Engineering Managers | Primary consumers of sprint reports, incident MTTR, and deployment frequency data |
| SRE / On-call teams | Consumers of OpsGenie alert reports and incident data |
| Platform Engineering | Responsible for JTier infrastructure hosting this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` (`project.build.targetJdk`) |
| Framework | Dropwizard (JTier) | jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` (prod-java17-jtier image) |
| Build tool | Maven | — | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-retrofit | (inherited) | http-framework | Retrofit HTTP client bundles for all external API integrations |
| jtier-quartz-bundle | (inherited) | scheduling | Quartz-based scheduled job execution framework |
| jtier-quartz-postgres-migrations | (inherited) | scheduling | PostgreSQL-backed Quartz job store with Flyway migrations |
| jtier-daas-postgres | (inherited) | db-client | Pooled PostgreSQL DataSource management |
| jtier-migrations | (inherited) | db-client | Database schema migration support |
| jtier-jdbi3 | (inherited) | orm | JDBI 3 integration for SQL object DAOs |
| retrofit2 | (inherited) | http-framework | Type-safe HTTP client used for all external service calls |
| org.immutables:value | 2.9.0 | serialization | Immutable value-object generation for DTOs |
| com.googlecode.json-simple | 1.1.1 | serialization | Lightweight JSON parsing for API responses |
| com.codahale.metrics | (inherited) | metrics | Dropwizard metrics collection |
| com.arpnetworking.steno | (inherited) | logging | Structured JSON logging |
| org.quartz-scheduler | (inherited) | scheduling | Job scheduling engine |
| org.jdbi | (inherited) | orm | SQL Object DAO binding |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
