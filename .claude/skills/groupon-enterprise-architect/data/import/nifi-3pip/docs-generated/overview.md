---
service: "nifi-3pip"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Third-Party Inventory (3PIP)"
platform: "Continuum"
team: "3pip-cbe-eng@groupon.com"
status: poc
tech_stack:
  language: "Java (JVM)"
  language_version: ""
  framework: "Apache NiFi"
  framework_version: "2.4.0"
  runtime: "Docker"
  runtime_version: "apache/nifi:2.4.0"
  build_tool: "Docker / Helm 3"
  package_manager: ""
---

# Nifi - Third Party Inventory Overview

## Purpose

nifi-3pip is an Apache NiFi cluster deployment purpose-built for third-party inventory (3PIP) data ingestion into Groupon's Continuum platform. The service runs a three-node NiFi cluster coordinated by ZooKeeper to provide fault-tolerant, scalable data pipeline execution. As noted in the repository, this is currently a WIP/Trial deployment and is not yet used for real production use cases.

## Scope

### In scope

- Running a three-node Apache NiFi cluster for parallel data ingestion
- Cluster coordination and leader election via ZooKeeper
- Executing NiFi data flows for third-party inventory ingestion
- Providing an HTTP/HTTPS web UI and REST API for flow management
- Custom startup scripting to configure cluster properties at boot time
- Health checking of individual NiFi nodes against the cluster controller API
- Storing NiFi content, provenance, and flow-file repository data on persistent volumes
- Deployment to GCP Kubernetes clusters (staging and production, us-central1)

### Out of scope

- Authoring or defining the NiFi flow definitions themselves (done via NiFi UI or Registry)
- Upstream 3PIP data sourcing (handled by external third-party inventory providers)
- Downstream consumption of ingested data (handled by other Continuum services)
- Application-level business logic (NiFi processors handle transformation)

## Domain Context

- **Business domain**: Third-Party Inventory (3PIP)
- **Platform**: Continuum
- **Upstream consumers**: Third-party inventory data providers (external); NiFi web UI users (operators)
- **Downstream dependencies**: ZooKeeper (cluster coordination); downstream Continuum services consuming ingested inventory data

## Stakeholders

| Role | Description |
|------|-------------|
| 3PIP CBE Engineering | Service owner team responsible for development and operations (3pip-cbe-eng@groupon.com) |
| Platform Operators | Engineers who manage NiFi flows and monitor ingestion pipelines |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Runtime | Apache NiFi | 2.4.0 | `Dockerfile` (`FROM apache/nifi:2.4.0`) |
| Cluster Coordinator | Apache ZooKeeper | 3.9 (Bitnami) | `docker-compose.yml` (`bitnami/zookeeper:3.9`) |
| Container | Docker | — | `Dockerfile`, `.ci/Dockerfile` |
| Build/Deploy | Helm 3 | cmf-java-api 3.88.1 | `.meta/deployment/cloud/scripts/deploy.sh` |
| Deploy orchestration | Krane | — | `.meta/deployment/cloud/scripts/deploy.sh` |
| JDBC Driver | PostgreSQL | 42.7.5 | `drivers/postgresql-42.7.5.jar` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| apache/nifi | 2.4.0 | http-framework | Core NiFi runtime providing flow execution, web UI, and REST API |
| bitnami/zookeeper | 3.9 | state-management | Distributed cluster coordination and leader election for NiFi nodes |
| postgresql JDBC driver | 42.7.5 | db-client | Enables NiFi processors to read from and write to PostgreSQL databases |
| start-http.sh | — | scheduling | Custom entrypoint that configures NiFi properties and launches the node |
| health-check.sh | — | metrics | Node health probe querying `/nifi-api/controller/cluster` for CONNECTED status |
| state-config.sh | — | state-management | Generates `state-management.xml` configuring local, ZooKeeper, and Kubernetes state providers |
| toolkit.sh | — | auth | Initializes nifi-cli toolkit properties file for API interactions |
