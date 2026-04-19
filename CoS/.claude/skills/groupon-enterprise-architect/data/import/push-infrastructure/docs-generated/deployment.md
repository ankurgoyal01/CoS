---
service: "push-infrastructure"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Push Infrastructure is a JVM-based Play Framework 2.2.1 service built with SBT 0.13.18. It is deployed as a containerized application within the Continuum platform. Specific orchestration manifests, Dockerfile paths, and pipeline configuration files are managed outside this architecture repository. Deployment configuration is managed externally per the Groupon Continuum deployment standard.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JVM (Java 8) base image; Play Framework dist package |
| Orchestration | Kubernetes (assumed Continuum standard) | Deployment manifests managed externally |
| Load balancer | Internal (Continuum ingress) | Internal service-to-service routing; not public-facing |
| CDN | none | Internal API — no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local / dev cluster | Internal dev URL |
| Staging | Pre-production validation and integration testing | Groupon staging region | Internal staging URL |
| Production | Live message delivery for all Groupon users | Groupon production region | Internal production URL |

> Specific URLs and region details are managed outside this architecture repository.

## CI/CD Pipeline

- **Tool**: Deployment configuration managed externally
- **Config**: External to this repository
- **Trigger**: On merge to main branch / manual deployment

### Pipeline Stages

1. **Build**: SBT compiles Scala/Java sources and produces a Play Framework distribution package
2. **Test**: Unit and integration tests executed via SBT test runner
3. **Package**: Docker image built from Play dist package with Java 8 JVM base
4. **Publish**: Docker image pushed to internal container registry
5. **Deploy**: Orchestration layer (Kubernetes) rolls out new image to target environment
6. **Validate**: Health checks confirm service availability post-deployment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual replica scaling | Managed externally |
| Memory | JVM heap sizing via JVM flags (-Xmx/-Xms) | Managed externally |
| CPU | Container CPU limits | Managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed externally | Managed externally |
| Memory | JVM heap: sized for template cache + Akka actor overhead | Managed externally |
| Disk | Minimal local disk; batch logs written to HDFS | Managed externally |

> Deployment configuration managed externally. Contact the Rocketman / Push Platform Engineering team for specific resource allocations and scaling policies.
