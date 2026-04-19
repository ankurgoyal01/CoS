---
service: "maris"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

MARIS is a JVM-based Dropwizard service deployed as a container within the Continuum Platform infrastructure. It follows standard JTier service deployment conventions. Deployment configuration is managed externally from the architecture model.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Java 11 base image |
| Orchestration | Kubernetes (Continuum Platform standard) | Deployment manifests managed by Getaways Engineering |
| Load balancer | Continuum Platform standard (ALB / internal) | Routes internal service-to-service traffic |
| CDN | Not applicable | Internal API — not served via CDN |

> Deployment configuration managed externally. Specific Dockerfile paths, Kubernetes manifest locations, and cluster details are maintained in the MARIS service repository and the Continuum Platform deployment configuration.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local and CI development iteration | — | Internal |
| Staging | Pre-production integration testing | — | Internal |
| Production | Live Getaways hotel inventory and reservations | — | Internal |

## CI/CD Pipeline

- **Tool**: Standard Continuum / JTier CI pipeline (GitHub Actions or Jenkins per platform convention)
- **Config**: Managed in the MARIS service repository
- **Trigger**: On pull request merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Compile Java source and run unit tests via Maven (`mvn verify`)
2. Package: Produce deployable JAR artifact
3. Container build: Build Docker image with JTier Java 11 base
4. Integration test: Run integration tests against staging `marisMySql` and stub dependencies
5. Deploy: Roll out to target environment via Continuum Platform deployment tooling
6. Schema migration: Execute `jtier-migrations` database migrations against target `marisMySql`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual or HPA per Continuum Platform policy | Minimum/maximum replicas defined in deployment manifests |
| Memory | JVM heap sized for reservation and event processing workload | Defined in deployment manifests |
| CPU | Sized for concurrent HTTP and MBus processing | Defined in deployment manifests |

> Specific scaling parameters are managed externally in deployment configuration. Contact Getaways Engineering for current production sizing.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Defined externally | Defined externally |
| Memory | Defined externally | Defined externally |
| Disk | Minimal (stateless service; state in `marisMySql`) | Defined externally |

> Deployment configuration managed externally. Resource values are defined in the MARIS service repository deployment manifests.
