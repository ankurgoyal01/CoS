---
service: "ingestion-jtier"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

ingestion-jtier is deployed as a Docker container orchestrated by Kubernetes across two Groupon data centers: snc1 (primary) and sac1 (secondary). The CI/CD pipeline is managed by Jenkins using the `java-pipeline-dsl` shared library. Releases are tag-based — a Git tag push triggers the Jenkins pipeline to build, test, and deploy the service image. The service runs in the `cloud-elevator` Kubernetes cluster tier.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service repository root |
| Orchestration | Kubernetes | cloud-elevator cluster; manifests managed via Helm |
| Load balancer | Kubernetes Service | Internal ClusterIP or LoadBalancer; no external-facing load balancer required |
| CDN | none | Backend ingestion service — no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | snc1 | Internal — not publicly accessible |
| Production | Live ingestion workloads | snc1 (primary) | Internal — not publicly accessible |
| Production | Live ingestion workloads | sac1 (secondary) | Internal — not publicly accessible |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `java-pipeline-dsl` shared library (pipeline definition external to service repo)
- **Trigger**: Git tag push (tag-based releases)

### Pipeline Stages

1. **Checkout**: Clones service repository at the tagged commit
2. **Build**: Runs `mvn clean package` to compile and package the JAR
3. **Test**: Runs unit and integration tests (`mvn verify`); includes rest-assured API tests
4. **Docker Build**: Builds Docker image tagged with the Git release tag
5. **Docker Push**: Pushes image to internal container registry
6. **Deploy Staging**: Applies Kubernetes manifests to snc1 staging namespace via Helm upgrade
7. **Deploy Production**: Applies Kubernetes manifests to snc1 and sac1 production namespaces via Helm upgrade (gate may require manual approval)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual replica control | Replica count not confirmed from inventory |
| Memory | JVM heap tuned for feed batch processing | JVM flags not confirmed from inventory |
| CPU | Kubernetes resource requests/limits | Values not confirmed from inventory |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Not confirmed from inventory | > Not confirmed from inventory |
| Memory | > Not confirmed from inventory | > Not confirmed from inventory |
| Disk | Minimal — ephemeral only; no persistent local disk required | — |

> Deployment configuration is managed externally via the `java-pipeline-dsl` Jenkins shared library and Helm chart values in the infrastructure repository. Exact resource limits should be verified in the Helm values for this service.
