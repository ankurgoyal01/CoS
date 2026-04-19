---
service: "kafka"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Kafka components are containerized using the `eclipse-temurin:21-jre-alpine` base image and deployed to Kubernetes as StatefulSets. StatefulSets are used for brokers and controllers to provide stable pod identities and persistent volume claims, which Kafka requires for correct partition and metadata log placement. Each broker and controller node is a separate pod with its own dedicated persistent volume for log storage.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container runtime | Docker | Base image: `eclipse-temurin:21-jre-alpine` |
| Orchestration | Kubernetes StatefulSet | One StatefulSet per role: broker, controller, connect-worker |
| Persistent volumes | Kubernetes PVC | Mounted at the broker `log.dirs` path and controller metadata log dir |
| Load balancer | Kubernetes Service (ClusterIP / NodePort) | Internal cluster access on port 9092 (Kafka protocol); admin REST on 9093 |
| CDN | none | Not applicable |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Single-node local cluster for service team testing | Local | localhost:9092 |
| staging | Multi-broker cluster for integration and performance validation | Groupon staging region | Internal DNS |
| production | Full production cluster serving all Continuum event flows | Groupon production region | Internal DNS |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Kafka OSS build) / Groupon internal CI for platform packaging
- **Config**: Groupon-internal Helm chart repository (not present in this module)
- **Trigger**: New Kafka version tag or platform upgrade request triggers image build and staged rollout

### Pipeline Stages

1. Build: Gradle builds broker, controller, connect-worker, and Trogdor JARs for JVM 21 (brokers) and JVM 11 (clients)
2. Docker image build: Packages JARs into `eclipse-temurin:21-jre-alpine` base image
3. Validate: Runs unit and integration tests (`./gradlew test`)
4. Push: Publishes image to internal container registry
5. Deploy (staging): Helm upgrade triggers rolling restart of Kafka StatefulSet pods
6. Deploy (production): Manual approval gate followed by rolling restart with one broker at a time

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (brokers) | Manual scale-out | Increase `spec.replicas` on broker StatefulSet; reassign partitions with `kafka-reassign-partitions.sh` |
| Horizontal (connect workers) | Manual or HPA | Connect workers are stateless per-task; scale by increasing worker replicas |
| Memory | Configured via `KAFKA_HEAP_OPTS` | Brokers: recommend 6–8 GB heap; rely on OS page cache for hot data |
| CPU | Kubernetes resource requests/limits | Brokers: request 2 CPU, limit 4 CPU (guidance; adjust per workload) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (broker) | 2 cores | 4 cores |
| Memory (broker) | 8 Gi | 12 Gi |
| Disk (broker log storage) | 500 Gi PVC | Configured per retention policy |
| CPU (controller) | 1 core | 2 cores |
| Memory (controller) | 4 Gi | 6 Gi |
| Disk (controller metadata log) | 20 Gi PVC | Sized for metadata log and snapshots |
| CPU (connect worker) | 1 core | 2 cores |
| Memory (connect worker) | 4 Gi | 6 Gi |

> Deployment configuration for production environments is managed in the Groupon platform Helm chart repository. Values above are guidance based on the service inventory and standard Kafka operational practice.
