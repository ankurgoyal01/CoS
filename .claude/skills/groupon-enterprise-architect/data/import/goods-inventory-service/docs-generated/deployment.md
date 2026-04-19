---
service: "goods-inventory-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["development", "staging", "production"]
---

# Deployment

## Overview

Goods Inventory Service is deployed as a containerized Java/Play application on Groupon's Kubernetes infrastructure. The service runs on the Continuum platform's standard deployment pipeline, with separate environments for development, staging, and production. Production deployments target GCP with managed PostgreSQL and Memorystore Redis instances.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard Groupon Java base image with Play Framework |
| Orchestration | Kubernetes | Groupon internal K8s clusters |
| Load balancer | Internal LB | Kubernetes service-level load balancing |
| CDN | None | Internal service; no CDN required |

## Environments

| Environment | Purpose | Region |
|-------------|---------|--------|
| Development | Local and shared development testing | Local / Dev cluster |
| Staging | Pre-production integration testing and validation | GCP staging region |
| Production | Live traffic serving universal checkout inventory operations | GCP production region(s) |

## CI/CD Pipeline

- **Tool**: Groupon internal CI/CD (Jenkins / GitHub Actions)
- **Trigger**: On merge to main branch, manual dispatch
- **Build**: SBT compile, test, and Docker image build

### Pipeline Stages

1. **Build**: SBT compilation and unit test execution
2. **Test**: Integration tests against test databases and mock services
3. **Package**: Docker image build and push to container registry
4. **Deploy Staging**: Automated deployment to staging Kubernetes cluster
5. **Validation**: Smoke tests and health check verification in staging
6. **Deploy Production**: Controlled rollout to production Kubernetes cluster
7. **Post-deploy**: Health check verification and monitoring alert validation

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA based on CPU and request metrics | Min/Max configured per environment |
| Memory | JVM heap tuning for Play Framework | Configured via JVM_OPTS |
| CPU | Resource requests and limits | Defined in K8s deployment manifests |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Configured per environment | Configured per environment |
| Memory | Configured per environment (JVM heap + overhead) | Configured per environment |
| Disk | Minimal (stateless application; logs to stdout) | Minimal |

> Specific resource values are managed in Kubernetes deployment manifests and vary by environment. Production values are tuned based on observed traffic patterns.
