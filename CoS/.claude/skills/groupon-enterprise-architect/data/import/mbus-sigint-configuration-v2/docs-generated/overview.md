---
service: "mbus-sigint-configuration-v2"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Message Bus Configuration Management"
platform: "Continuum"
team: "GMB (Global Message Bus)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "managed via jtier-service-pom 5.14.1"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# MBus Sigint Configuration Service Overview

## Purpose

MBus Sigint Configuration Service (`mbus-sigint-config`) is the centralized configuration management system for Groupon's Global Message Bus (MBus/Artemis) environments. It provides HTTP endpoints that allow teams to read and modify message bus topology — including clusters, destinations (queues and topics), diversions, user credentials, and redelivery policies — through a governed change-request and deployment workflow. The service mediates between human operators, approval systems (ProdCat, Jira), and the Ansible-based Artemis deployment automation, ensuring all configuration changes follow a controlled promotion path from test to production environments.

## Scope

### In scope

- CRUD management of MBus cluster definitions
- Management of destinations (queues, topics), diverts, and user credentials per cluster
- Change-request lifecycle: creation, approval, test deployment, production promotion
- Delete-request lifecycle for removing configuration entries
- Deploy-schedule management via Quartz cron expressions
- GprodConfig (production change metadata) management
- Jira ticket creation, linking, and status transitions triggered by request state changes
- ProdCat approval signal integration for production changes
- Rendering and deploying Artemis configuration via SSH to Ansible
- Deployment configuration read endpoints consumed by MBus broker infrastructure

### Out of scope

- Actual message routing or message delivery (handled by Artemis brokers)
- MBus broker provisioning or cluster infrastructure
- Consumer/producer application configuration beyond access permissions
- Version 1 of the service (MongoDB-backed legacy; tracked as `mbus-sigint-config::app-v1`)

## Domain Context

- **Business domain**: Message Bus Configuration Management
- **Platform**: Continuum (Global Message Bus)
- **Upstream consumers**: MBus operator tooling (`mbusible`), Artemis broker infrastructure (reads `/config/*` endpoints), human administrators via API
- **Downstream dependencies**: PostgreSQL (primary data store), Jira API (ticket automation), ProdCat API (production approval), Ansible automation via SSH (configuration deployment)

## Stakeholders

| Role | Description |
|------|-------------|
| GMB Team (messagebus-team@groupon.com) | Owners and primary developers |
| MBus Operators | Use the API and `mbusible` tooling to manage cluster configuration |
| PagerDuty On-Call | mbus@groupon.pagerduty.com — incident response |
| Service Admin Users | Named users granted `admin` role to approve and manage change requests |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `pom.xml` `project.build.targetJdk` |
| Framework | Dropwizard (JTier) | via jtier-service-pom 5.14.1 | `pom.xml` parent |
| Runtime | JVM | 11 | `.java-version` (11.0.2) |
| Build tool | Maven | — | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |
| Base Docker image | jtier/dev-java11-maven | 2023-12-19-609aedb | `.ci/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-jdbi | managed by parent | db-client | Groupon JDBI wrapper for PostgreSQL access |
| jdbi | managed by parent | db-client | SQL object mapping (JDBI DAOs) |
| jtier-migrations | managed by parent | db-client | Flyway-backed schema migration on startup |
| jtier-daas-postgres | managed by parent | db-client | DaaS (Database-as-a-Service) PostgreSQL connectivity |
| jtier-quartz-bundle | managed by parent | scheduling | Quartz job scheduler bundle (Dropwizard integration) |
| jtier-quartz-postgres-migrations | managed by parent | scheduling | Quartz Postgres JDBC store schema migrations |
| jtier-auth-bundle | managed by parent | auth | Header-based client identity and role authorization |
| dropwizard-auth | managed by parent | auth | Dropwizard authentication filter support |
| freemarker | managed by parent | serialization | Template engine for configuration rendering |
| stringtemplate | 3.2.1 | serialization | ANTLR StringTemplate engine for Ansible config output |
| commons-io | managed by parent | http-framework | File and stream utilities |
| mockito-junit-jupiter | managed by parent | testing | Unit test mocking |
| jtier-daas-testing | managed by parent | testing | DaaS test utilities for database integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for the full list.
