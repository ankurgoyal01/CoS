---
service: "deal-catalog-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The Deal Catalog Service is deployed as a containerized JTier/Dropwizard application within Groupon's Kubernetes-based infrastructure. It runs across staging and production environments with its own MySQL database (provisioned via DaaS -- Database as a Service) and dedicated Redis instance. Deployment is managed through Groupon's standard CI/CD pipeline.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JTier base image with Java runtime |
| Orchestration | Kubernetes | Deployed as a Kubernetes Deployment with service discovery |
| Load balancer | Internal LB | Internal service mesh / load balancer for HTTP traffic |
| CDN | N/A | Internal service -- no CDN required |

> Infrastructure details are inferred from JTier platform conventions. Exact Kubernetes manifests and Dockerfile are in the service source repository.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production testing and validation | US | Internal staging endpoint |
| Production | Live traffic serving | US (multi-region) | Internal production endpoint |

## CI/CD Pipeline

- **Tool**: Jenkins / Groupon CI (JTier standard)
- **Config**: Managed in the service source repository
- **Trigger**: On merge to main branch

### Pipeline Stages

1. **Build**: Compile Java source, run unit tests, package Dropwizard fat JAR
2. **Test**: Run integration tests against staging dependencies
3. **Docker Build**: Build container image from JTier base image
4. **Deploy to Staging**: Deploy to staging Kubernetes cluster, run smoke tests
5. **Deploy to Production**: Rolling deployment to production Kubernetes cluster

> Pipeline details are inferred from JTier platform conventions. Exact pipeline configuration is in the service source repository.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Auto-scaling (HPA) | Scaled based on CPU and request rate |
| Memory | Kubernetes resource limits | JVM heap configured for Dropwizard workload |
| CPU | Kubernetes resource limits | Configured per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase | > No evidence found in codebase |
| Memory | > No evidence found in codebase | > No evidence found in codebase |
| Disk | Ephemeral (stateless container) | Ephemeral |

> Deployment configuration managed externally in the service source repository and Groupon's infrastructure-as-code tooling. Exact resource requests and limits require access to Kubernetes manifests.
