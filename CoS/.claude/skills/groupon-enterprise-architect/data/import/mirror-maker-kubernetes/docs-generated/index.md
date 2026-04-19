---
service: "mirror-maker-kubernetes"
title: "mirror-maker-kubernetes Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMirrorMakerService"]
tech_stack:
  language: "Java (Bash entrypoint)"
  framework: "Apache Kafka MirrorMaker"
  runtime: "JVM"
---

# MirrorMaker Kubernetes Documentation

Kubernetes-deployed Apache Kafka MirrorMaker service that replicates whitelisted Kafka topics across cluster boundaries (K8s-to-MSK, MSK-to-K8s, GCP-to-MSK, MSK-to-GCP) to support Groupon's multi-cloud, multi-region event streaming infrastructure.

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
| Language | Java (JVM) / Bash |
| Framework | Apache Kafka MirrorMaker |
| Runtime | JVM (Java) |
| Build tool | Helm 3 (chart: `cmf-java-worker` v3.88.1) |
| Platform | Continuum |
| Domain | Data Engineering / Kafka Replication |
| Team | Kafka Platform (slack: `kafka-deploys`) |
