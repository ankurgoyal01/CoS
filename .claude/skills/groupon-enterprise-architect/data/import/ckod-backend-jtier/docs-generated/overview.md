---
service: "ckod-backend-jtier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Platform Reliability / Data Platform Operations"
platform: "Continuum"
team: "PRE (Platform Reliability Engineering)"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard/JTier"
  framework_version: "5.14.0 (jtier-service-pom parent)"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven (mvnvm 3.6.3)"
---

# CKOD Backend JTier Overview

## Purpose

CKOD API (CKOD Backend JTier) is a JTier-based REST backend owned by Groupon's Platform Reliability Engineering (PRE) team. It collects and stores Keboola job run data for all onboarded data platform projects, tracks deployments end-to-end by creating and linking Jira tickets, and exposes queryable read APIs for SLA job compliance, cost alerts, dependency graphs, incident records, and active user data. The service bridges Keboola, Jira, GitHub Enterprise, and Google Chat so that data engineers and on-call engineers have a single API surface for pipeline observability and change management.

## Scope

### In scope
- Polling Keboola's job queue API and persisting pipeline run records to MySQL
- Creating, updating, and linking Jira deployment tickets for Keboola and Airflow deployments
- Resolving deployment diff authors via GitHub Enterprise compare API
- Determining SOX compliance classification of deployment pipelines
- Sending Google Chat notifications for deployment events
- Exposing read APIs for SLA job details (Keboola, EDW, OP, RM variants)
- Exposing read APIs for DnD critical incidents
- Managing cost alert configurations and returning KBC BQ cost / telemetry data
- Returning Keboola project metadata including point-of-contact, teams, and pipelines
- Tracking dependency relationships between Keboola projects
- Serving deployment history queries with rich filter support

### Out of scope
- Executing or triggering Keboola jobs (read-only polling)
- Managing Jira project configuration or workflows
- Performing actual deployments (handled by Deploybot / Conveyor)
- Providing frontend UI (data surfaces via REST to CKOD or other consumers)

## Domain Context

- **Business domain**: Platform Reliability / Data Platform Operations
- **Platform**: Continuum
- **Upstream consumers**: CKOD UI, internal tooling, on-call automation, Airflow pipelines calling the deployment-tracking endpoints
- **Downstream dependencies**: Keboola Cloud (`queue.groupon.keboola.cloud`, `connection.groupon.keboola.cloud`), Jira Cloud, GitHub Enterprise (`api.github.groupondev.com`), Google Chat, Deploybot (via edge proxy), MySQL (CKOD database)

## Stakeholders

| Role | Description |
|------|-------------|
| PRE Team (Owner) | Platform Reliability Engineering; owns development and operations — dnd-pre@groupon.com |
| Data Platform Engineers | Consumers of deployment tracking and SLA monitoring APIs |
| On-call Engineers | Use runbook and Wavefront dashboards to monitor service health |
| CKOD UI / Internal Tooling | Primary REST API consumers |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk`, `src/main/docker/Dockerfile` |
| Framework | Dropwizard / JTier | 5.14.0 | `pom.xml` parent `jtier-service-pom:5.14.0` |
| Runtime | JVM | 17 | `src/main/docker/Dockerfile` `prod-java17-jtier:3` |
| Build tool | Maven | 3.6.3 | `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `hibernate-core` | 6.4.4.Final | orm | JPA/ORM layer for all MySQL entity reads and writes |
| `jtier-daas-mysql` | (from parent) | db-client | JTier MySQL DataSource provisioning |
| `jtier-migrations` | (from parent) | db-client | MySQL schema migration support at startup |
| `jakarta.transaction-api` | (from parent) | orm | JTA transaction management |
| `jakarta.activation-api` | 2.1.0 | serialization | MIME type handling for JAX-RS |
| `org.apache.httpcomponents:httpclient` | (from parent) | http-framework | HTTP client for Keboola, GitHub, Deploybot, Google Chat calls |
| `org.projectlombok:lombok` | 1.18.30 | serialization | Compile-time boilerplate reduction |
| `com.atlassian.servicedesk:jira-servicedesk-api` | 10.6.1 | http-framework | Jira Service Management on-call schedule lookup |
| `com.fasterxml.jackson` | (from parent) | serialization | JSON/YAML serialization via ObjectMapper and YAMLMapper |
| `com.arpnetworking.steno` | (from parent) | logging | Structured JSON logging (Steno format) |
| `io.dropwizard` | (from parent) | http-framework | Embedded Jetty HTTP server, JAX-RS resources, health checks |
| `org.mockito:mockito-inline` | (from parent) | testing | Unit test mocking |
