---
service: "inventory_outbound_controller"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production-us, production-eu]
---

# Deployment

## Overview

inventory_outbound_controller is containerized via Docker running a JVM / Java 8 (OpenJDK) runtime and orchestrated by Kubernetes. It is deployed across US and EU regions on the Continuum platform. CI/CD is managed via Jenkins. Liquibase runs database migrations at container startup before the Play application begins serving traffic.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | OpenJDK 8 base image; SBT build produces a Play distribution package |
| Orchestration | Kubernetes | Kubernetes deployment manifests (managed externally to this repo) |
| Load balancer | No evidence found | Expected at Kubernetes ingress layer |
| CDN | Not applicable | Internal service — not exposed to public CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | — | No evidence found |
| Staging | Pre-production integration and smoke testing | No evidence found | No evidence found |
| Production (US West) | US production traffic | us-west-1, us-west-2 | No evidence found |
| Production (US Central) | US production traffic | us-central1 | No evidence found |
| Production (EU West) | EU production traffic | europe-west1, eu-west-1 | No evidence found |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: No evidence found — pipeline configuration managed in Continuum CI infrastructure
- **Trigger**: On push to main branch (inferred standard Continuum practice)

### Pipeline Stages

1. **Test**: SBT test suite execution (Mockito unit tests, WireMock integration tests)
2. **Compile**: `sbt compile` — compiles Java/Scala sources
3. **Package**: `sbt dist` — produces Play Framework distribution artifact
4. **Containerize**: Docker image build with OpenJDK 8 base
5. **Migrate**: Liquibase applies any pending schema migrations at container startup
6. **Deploy**: Kubernetes rolling update to target environment and regions

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (inferred) | No evidence found — managed externally |
| Memory | Kubernetes resource limits (inferred) | JVM heap sizing expected via JVM flags |
| CPU | Kubernetes resource limits (inferred) | No evidence found |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found — JVM heap size should be configured to stay within container limits |
| Disk | No evidence found | No evidence found |

> Deployment configuration (Kubernetes manifests, resource requests/limits, JVM heap flags) is managed externally to this service repository. See the Continuum platform infrastructure repo for full deployment specs.
