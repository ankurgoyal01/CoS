---
service: "subscription-programs-app"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Subscription Programs App is deployed as a JTier/Dropwizard JVM service within the Continuum platform. It runs as two logical processes: the main HTTP service (`continuumSubscriptionProgramsApp`) and a Quartz-based background worker (Subscription Programs Worker). Deployment configuration is managed externally through Continuum's standard JTier deployment pipeline.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Docker image (Java 1.8 / Eclipse Temurin base) |
| Orchestration | Kubernetes | Continuum platform k8s cluster; deployment manifests managed externally |
| Load balancer | Continuum API gateway / internal LB | Routes `/select/*`, `/select-v2/*`, `/support/*`, `/message/*` |
| CDN | Not applicable | Internal service — not exposed via CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and integration testing | — | Internal dev cluster |
| Staging | Pre-production validation | — | Internal staging cluster |
| Production | Live consumer traffic | US / primary Groupon regions | Internal production cluster |

## CI/CD Pipeline

- **Tool**: Continuum/JTier standard pipeline (internal tooling)
- **Config**: Managed externally to this architecture repository
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Maven compile, test, and package (`mvn package`)
2. Unit / integration test: Run JTier test suite
3. Docker image build: Package JAR into standard JTier Docker image
4. Deploy to staging: Push image and apply k8s manifests to staging cluster
5. Smoke test: Validate health endpoint and basic API contract
6. Deploy to production: Rolling deployment to production k8s cluster

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA / manual scaling | Managed externally per Continuum platform ops |
| Memory | JVM heap sizing | Managed externally |
| CPU | Container resource limits | Managed externally |

## Resource Requirements

> Deployment configuration managed externally. Specific CPU, memory, and disk limits are defined in the Continuum platform k8s manifests and not present in this architecture repository.
