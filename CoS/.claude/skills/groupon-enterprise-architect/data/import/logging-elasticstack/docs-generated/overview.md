---
service: "logging-elasticstack"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Logging and Observability Infrastructure"
platform: "Continuum"
team: "Logging Platform Team (jsermersheim, seborys, dartiukhov)"
status: active
tech_stack:
  language: "Python / Ruby"
  language_version: "Python 2.7 / Ruby 3.3.3"
  framework: "Logstash / Elasticsearch / Kibana / Filebeat"
  framework_version: "Logstash 8.12.1 / Elasticsearch 7.17.6"
  runtime: "Alpine / Java Eclipse Temurin"
  runtime_version: "Alpine 3.16 / Java 21"
  build_tool: "Make / Ansible / Jenkins / Helm"
  package_manager: "pip / gem"
---

# Logging Elastic Stack Overview

## Purpose

The Logging Elastic Stack is Groupon's centralized logging platform built on the Elastic Stack (ELK). It collects log events from all Groupon services via Filebeat agents, buffers them through Apache Kafka, processes and enriches them via Logstash pipelines, indexes them in Elasticsearch, and exposes them for search and visualization through Kibana. The platform provides near real-time log ingestion and querying across all Groupon environments and regions.

## Scope

### In scope

- Log collection from all Groupon services via Filebeat agents deployed as sidecars or DaemonSets
- Kafka-based buffering of raw log events between Filebeat and Logstash
- Logstash pipeline processing: parsing, filtering, enrichment, and routing of log events by sourcetype
- Elasticsearch indexing with hot/warm tiered storage and ILM-based lifecycle management
- Kibana-based log search, visualization, and dashboard access for all Groupon engineers
- Elasticsearch index lifecycle management (ILM) policies and retention configuration
- Operational metrics emission to Wavefront TSDB via ES Watcher and Telegraf
- Cluster provisioning and deployment via Ansible (on-prem) and Helm/Krane (GKE)
- AWS S3 snapshot/backup management for Elasticsearch indices
- Onboarding of new log sourcetypes (Logstash filter, ES template, Kibana data view)

### Out of scope

- Application-level log formatting (responsibility of individual service owners)
- Alerting rule management for business-level events (handled by individual service teams)
- Distributed tracing (separate observability concern outside this platform)
- Metrics collection pipelines not routed through Elasticsearch (handled by Wavefront directly)

## Domain Context

- **Business domain**: Logging and Observability Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: All Groupon services (as log producers via Filebeat); Groupon engineers (via Kibana UI and Elasticsearch API)
- **Downstream dependencies**: Apache Kafka (`messageBus`), Elasticsearch cluster (`continuumLoggingElasticsearch`), Wavefront TSDB (`metricsStack`), AWS S3 (snapshots), Okta (SSO/OAuth)

## Stakeholders

| Role | Description |
|------|-------------|
| Logging Platform Team | Owns and operates the ELK infrastructure; handles cluster deployments, upgrades, and onboarding (jsermersheim, seborys, dartiukhov) |
| Groupon Service Engineers | Consumers of the logging platform; onboard their services as log sources and query logs via Kibana |
| SRE / On-Call Engineers | Rely on Kibana search and Wavefront dashboards for incident triage and troubleshooting |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 2.7 | Ansible automation and index management scripts |
| Language | Ruby | 3.3.3 | Krane deployment tooling |
| Framework | Logstash | 8.12.1 | Log processing pipeline |
| Framework | Elasticsearch | 7.17.6 | Searchable event store |
| Framework | Kibana | (paired with ES) | Query and visualization UI |
| Framework | Filebeat | (paired with ES) | Log shipper agent |
| Runtime | Alpine Linux | 3.16 | Container base image |
| Runtime | Java Eclipse Temurin | 21 | Logstash JVM runtime |
| Build tool | Make | — | Top-level build orchestration |
| Build tool | Ansible | < 2.9 | Infrastructure provisioning |
| Build tool | Jenkins | — | CI/CD pipeline |
| Build tool | Helm | — | Kubernetes chart deployment |
| Package manager | pip | — | Python dependencies |
| Package manager | gem | — | Ruby dependencies |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ansible | < 2.9 | orchestration | Infrastructure provisioning for ELK clusters |
| elasticsearch (Python) | 7.17.6 | db-client | Python client for Elasticsearch API calls |
| boto3 | latest | integration | AWS SDK for S3 snapshot management |
| requests | latest | http-framework | HTTP client for Elasticsearch and Kibana APIs |
| ruamel.yaml | latest | serialization | YAML configuration file manipulation |
| krane | 2.4.9 | orchestration | Kubernetes deployment tool for GKE rollouts |
| ClusterShell | latest | orchestration | Parallel command execution across cluster nodes |
| jmespath | latest | serialization | JSON query language for AWS/ES response parsing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
