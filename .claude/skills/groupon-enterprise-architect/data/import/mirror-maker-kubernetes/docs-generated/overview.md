---
service: "mirror-maker-kubernetes"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data Engineering / Kafka Replication"
platform: "Continuum"
team: "Kafka Platform"
status: active
tech_stack:
  language: "Java / Bash"
  language_version: "JVM"
  framework: "Apache Kafka MirrorMaker"
  framework_version: "bundled with Kafka"
  runtime: "JVM"
  runtime_version: "Java 8+"
  build_tool: "Helm 3"
  package_manager: "Helm"
---

# MirrorMaker Kubernetes Overview

## Purpose

MirrorMaker Kubernetes is a containerized Apache Kafka MirrorMaker runtime that bridges event streams across Groupon's multi-cluster, multi-cloud Kafka topology. Each deployed pod instance subscribes to a whitelisted set of source topics and republishes records to a designated destination cluster, enabling downstream consumers in different environments (Kubernetes-native clusters, AWS MSK, GCP Kafka) to process the same event streams independently. The service is the critical link ensuring that the same Kafka events produced in one environment (e.g., GCP us-central1) are made available to consumers in another (e.g., MSK eu-west-1) without requiring producers to publish to multiple clusters directly.

## Scope

### In scope
- Consuming whitelisted Kafka topics from a configured source cluster endpoint
- Republishing consumed records to a configured destination cluster endpoint, with optional topic prefix renaming (e.g., `k8s.*`, `msk.*`, `gcp.*`)
- Applying Janus-forwarder mode for specialized topic transformation (renaming to a single destination topic or prefixing)
- Securing source and destination broker connections via mTLS (configurable per side)
- Snappy-compression of produced records
- Emitting Jolokia/JMX metrics for consumer lag, throughput, drop count, and producer send rates
- Log emission via Filebeat sidecar to the centralized logging stack

### Out of scope
- Producing original business events (this service only replicates existing events)
- Message schema transformation or content mutation beyond topic renaming
- Consumer offset management for downstream services (each downstream consumer owns its own group)
- Kafka cluster provisioning or broker operations
- Any HTTP API surface (no external REST endpoints are exposed)

## Domain Context

- **Business domain**: Data Engineering / Kafka Replication
- **Platform**: Continuum
- **Upstream consumers**: Any Groupon service that needs events from a remote Kafka cluster (e.g., Janus notification workers on MSK consuming from a K8s-native Kafka cluster)
- **Downstream dependencies**: Source Kafka cluster, Destination Kafka cluster, Metrics stack (InfluxDB via Telegraf), Logging stack (Filebeat/Elasticsearch)

## Stakeholders

| Role | Description |
|------|-------------|
| Kafka Platform Team | Service owners; manage deployment configurations and mirror topologies |
| Consumer Service Teams | Rely on mirrored topics being available in their target cluster |
| Data Engineering | Owns the MSK and GCP Kafka cluster infrastructure that this service bridges |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java (JVM) / Bash | JVM | `.meta/.raptor.yml` (archetype: java) |
| Framework | Apache Kafka MirrorMaker | Bundled with Kafka | `continuumMirrorMakerService.dsl` |
| Runtime | JVM | Java | `common.yml` (readiness: `pgrep java`) |
| Build tool | Helm 3 (chart: cmf-java-worker v3.88.1) | 3.88.1 | `.deploy_bot.yml` |
| Container image | docker-conveyor.groupondev.com/data/mirror-maker-kubernetes | latest | `common.yml` |
| Deployment tool | krane | bundled in deploy image | `.deploy_bot.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Apache Kafka MirrorMaker | Kafka-bundled | message-client | Source topic consumption and destination publication |
| Jolokia Agent | JVM agent | metrics | JMX-over-HTTP bridge for Telegraf scraping |
| Telegraf (jolokia2_agent) | sidecar | metrics | Scrapes Jolokia metrics and forwards to InfluxDB |
| Filebeat | sidecar | logging | Ships `/var/log/mirror-maker/mirror-maker.log` to logging stack |
| OpenSSL / keytool | system | auth | Builds keystores and truststores for mTLS broker connections |
| krane | deploy image v2.8.5 | scheduling | Kubernetes manifest deployment via deploy_bot |
