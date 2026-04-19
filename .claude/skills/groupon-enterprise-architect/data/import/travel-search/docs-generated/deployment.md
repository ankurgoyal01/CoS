---
service: "travel-search"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

The Getaways Search Service is deployed as a Java/Jetty WAR application within a Docker container, orchestrated on the Continuum platform's Kubernetes infrastructure. It runs alongside its MySQL database (`continuumTravelSearchDb`) and Redis cache (`continuumTravelSearchRedis`), both of which are provisioned as platform-managed resources. Deployment configuration is managed externally to the architecture model.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | WAR packaged into a JVM container image |
| Orchestration | Kubernetes | Managed via Continuum platform Kubernetes cluster |
| Load balancer | Platform-managed | Upstream load balancer routes Getaways client traffic |
| CDN | > No evidence found | Not specified in architecture model |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local and CI development | — | — |
| staging | Pre-production integration and QA | — | — |
| production | Live Getaways traffic | — | — |

> Region and URL details are managed externally and are not present in the architecture model. Verify with the Continuum platform infrastructure team.

## CI/CD Pipeline

- **Tool**: > No evidence found — verify in service repository CI config
- **Config**: > No evidence found — check `.github/workflows/`, `Jenkinsfile`, or equivalent in service repository
- **Trigger**: On push / pull request merge to main branch

### Pipeline Stages

1. Build: Compile Java source and package as WAR
2. Test: Run unit and integration tests
3. Docker build: Package WAR into container image
4. Deploy to staging: Deploy image to staging Kubernetes namespace
5. Deploy to production: Deploy image to production Kubernetes namespace (manual approval or automated on passing staging gates)

> Pipeline stage details are inferred from standard Continuum platform CI/CD patterns. Verify against the service repository CI configuration.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | > No evidence found — verify in Kubernetes manifests |
| Memory | Kubernetes resource limits | > No evidence found — verify in Kubernetes manifests |
| CPU | Kubernetes resource limits | > No evidence found — verify in Kubernetes manifests |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | Minimal (WAR + logs) | > No evidence found |

> Deployment configuration managed externally. Resource limits and scaling parameters are defined in Kubernetes manifests in the service repository or the Continuum platform infrastructure repository. Verify with the Getaways Engineering team.
