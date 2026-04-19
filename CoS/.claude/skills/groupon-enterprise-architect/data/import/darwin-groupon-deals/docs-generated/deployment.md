---
service: "darwin-groupon-deals"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production-snc1, production-dub1, production-sac1]
---

# Deployment

## Overview

The Darwin Aggregator Service is deployed as a Docker container (Java 17 base image) orchestrated by Kubernetes using Helm charts. It runs across three production regions — SNC1, DUB1, and SAC1 — providing multi-region availability for deal search traffic. CI/CD is managed through Jenkins. Each region runs independently; there is no cross-region state sharing at the application tier.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (Java 17) | Dropwizard fat-jar packaged into a Java 17 container image |
| Orchestration | Kubernetes + Helm | Helm chart manages Deployment, Service, ConfigMap, and Secret resources |
| Load balancer | Kubernetes Service / Ingress | Internal Kubernetes service routing; external ingress details managed by platform team |
| CDN | Not applicable | Internal service — not directly consumer-facing |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation and integration testing | Primary staging region | Internal staging endpoint |
| Production SNC1 | Production traffic serving | SNC1 (US West) | Internal production endpoint |
| Production DUB1 | Production traffic serving | DUB1 (EU West) | Internal production endpoint |
| Production SAC1 | Production traffic serving | SAC1 (US East) | Internal production endpoint |

> Exact internal URLs are not documented here. Consult the Relevance Engineering team or the Helm values for production endpoints.

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: Jenkins pipeline configuration (exact path to be confirmed with service owner)
- **Trigger**: On push to main branch; on pull request for validation; manual dispatch for hotfixes

### Pipeline Stages

1. **Build**: Maven 3.x compiles source and runs unit tests (`mvn clean package`)
2. **Test**: Integration and unit test suite execution
3. **Docker Build**: Constructs Docker image with Java 17 and Dropwizard fat-jar
4. **Docker Push**: Pushes image to internal container registry
5. **Helm Deploy (Staging)**: Deploys to staging via Helm upgrade; runs smoke tests
6. **Helm Deploy (Production)**: Promotes image to production regions (SNC1, DUB1, SAC1) via Helm upgrade

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (Horizontal Pod Autoscaler) | Min/max replica counts configured in Helm values; target CPU/memory utilization not discoverable from inventory |
| Memory | Kubernetes resource limits | Configured in Helm values; exact limits to be confirmed with service owner |
| CPU | Kubernetes resource limits | Configured in Helm values; exact limits to be confirmed with service owner |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable from inventory | Not discoverable from inventory |
| Memory | Not discoverable from inventory | Not discoverable from inventory |
| Disk | Ephemeral only (no persistent volumes) | Not applicable |

> Deployment configuration for resource requests and limits is managed in the Helm chart. Contact the Relevance Engineering team (relevance-engineering@groupon.com) for current values.
