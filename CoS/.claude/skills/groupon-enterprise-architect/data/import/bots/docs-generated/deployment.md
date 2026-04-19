---
service: "bots"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, snc1, sac1, dub1]
---

# Deployment

## Overview

BOTS is deployed as Docker containers orchestrated by Kubernetes across three production regions (snc1, sac1, dub1) plus dev and staging environments. Both `continuumBotsApi` and `continuumBotsWorker` are packaged and deployed as separate containers. The MySQL datastore (`continuumBotsMysql`) is provisioned as a managed database instance per environment.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `continuumBotsApi` and `continuumBotsWorker` each built as Docker images |
| Orchestration | Kubernetes | Deployed via Kubernetes manifests / Helm charts per environment |
| Load balancer | Kubernetes ingress / JTier standard | Handles inbound HTTP traffic to `continuumBotsApi` |
| CDN | none | Direct API access; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Local development and integration testing | — | Internal dev cluster |
| staging | Pre-production validation | — | Internal staging cluster |
| snc1 | US West production | snc1 | Internal production cluster |
| sac1 | US East production | sac1 | Internal production cluster |
| dub1 | EU production (GDPR-compliant) | dub1 | Internal production cluster |

## CI/CD Pipeline

- **Tool**: JTier standard CI pipeline (internal Groupon CI infrastructure)
- **Config**: Managed by JTier platform conventions; specific pipeline config file paths are not enumerated in this inventory
- **Trigger**: On push to main branch; manual dispatch for targeted deploys

### Pipeline Stages

1. Build: Compile Java source, run unit tests via Maven
2. Package: Build Docker image for `continuumBotsApi` and `continuumBotsWorker`
3. Validate: Run integration tests against staging environment
4. Deploy staging: Push images and deploy to staging Kubernetes cluster
5. Deploy production: Promote to snc1, sac1, dub1 Kubernetes clusters (gated by staging validation)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max replicas managed per environment via Helm values |
| Memory | Kubernetes resource limits | JVM heap and container limits set in Helm values |
| CPU | Kubernetes resource limits | Request/limit configured per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > Not specified in inventory | > Not specified in inventory |
| Memory | > Not specified in inventory | > Not specified in inventory |
| Disk | Stateless containers; no persistent disk | — |

> Specific resource request/limit values are managed in Kubernetes/Helm configuration outside this repository. Contact the BOTS team (ssamantara, rdownes, joeliu) for current sizing values.
