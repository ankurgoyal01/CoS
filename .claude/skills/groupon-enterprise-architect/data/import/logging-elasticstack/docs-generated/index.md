---
service: "logging-elasticstack"
title: "logging-elasticstack Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumLogging"
  containers: [continuumLoggingFilebeat, continuumLoggingLogstash, continuumLoggingElasticsearch, continuumLoggingKibana]
tech_stack:
  language: "Python 2.7 / Ruby 3.3.3"
  framework: "Logstash 8.12.1 / Elasticsearch 7.17.6"
  runtime: "Alpine 3.16 / Java 21 Eclipse Temurin"
  build_tool: "Make / Ansible / Jenkins / Helm"
---

# Logging Elastic Stack Documentation

Centralized logging platform providing near real-time log ingestion, processing, storage, and querying for all Groupon services via the Elastic Stack (Filebeat, Logstash, Elasticsearch, Kibana).

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Python 2.7 / Ruby 3.3.3 |
| Framework | Logstash 8.12.1 / Elasticsearch 7.17.6 |
| Runtime | Alpine 3.16 / Java 21 Eclipse Temurin |
| Build tool | Make / Ansible / Jenkins / Helm |
| Platform | Continuum |
| Domain | Logging and Observability Infrastructure |
| Team | Logging Platform Team (jsermersheim, seborys, dartiukhov) |
