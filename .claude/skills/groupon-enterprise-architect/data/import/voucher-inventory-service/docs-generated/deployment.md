---
service: "voucher-inventory-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["staging", "production"]
---

# Deployment

## Overview

The Voucher Inventory Service is deployed as containerized workloads on Kubernetes. The service runs two distinct deployment targets: API pods (serving HTTP traffic via Rails) and Worker pods (running Sidekiq and ActiveMessaging background processes). Data stores are managed AWS services -- MySQL on RDS, Redis on ElastiCache, and ActiveMQ as the message broker.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JRuby-based container images |
| Orchestration | Kubernetes | Separate deployments for API and Worker pods |
| Load balancer | Internal LB | Routes traffic to API pods |
| CDN | None | Internal service, not consumer-facing |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation and integration testing | AWS | Internal |
| Production | Live traffic serving all Groupon voucher inventory operations | AWS | Internal |

## CI/CD Pipeline

> No evidence found in codebase. Deployment pipeline configuration is not present in the architecture DSL. Expected standard Continuum CI/CD patterns.

- **Tool**: Expected Groupon CI/CD toolchain
- **Trigger**: On merge to main branch

### Pipeline Stages

> No evidence found in codebase. Expected stages based on standard Continuum patterns:

1. **Build**: Compile JRuby application, run unit tests, build Docker image
2. **Test**: Run integration and contract tests
3. **Deploy to Staging**: Roll out to staging Kubernetes cluster
4. **Deploy to Production**: Roll out to production Kubernetes cluster with canary/rolling strategy

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| API Pods | Horizontal scaling | Kubernetes HPA based on CPU/request metrics |
| Worker Pods | Horizontal scaling | Kubernetes HPA or manual scaling based on queue depth |
| Database (RDS) | Vertical scaling | AWS RDS instance class adjustments |
| Redis (ElastiCache) | Cluster scaling | AWS ElastiCache node configuration |

## Resource Requirements

> No evidence found in codebase. Resource requests and limits are managed in Kubernetes manifests external to the architecture DSL.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed via K8s manifests | Managed via K8s manifests |
| Memory | Managed via K8s manifests | Managed via K8s manifests |
| Disk | Managed via K8s manifests | Managed via K8s manifests |

> Deployment configuration managed externally. Specific resource allocations, replica counts, and scaling thresholds are defined in Kubernetes manifests and Helm charts outside the architecture repository.
