---
service: "lead-gen"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev, staging, production]
---

# Deployment

## Overview

LeadGen Service is deployed as containerized workloads on Kubernetes. The Java service (`leadGenService`) and the n8n workflow engine (`leadGenWorkflows`) run as separate deployments. The PostgreSQL database (`leadGenDb`) is provisioned as a managed instance. All environments (dev, staging, production) follow the same deployment topology.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service repository |
| Orchestration | Kubernetes | Helm charts for service and n8n deployments |
| Load balancer | Internal ALB | Routes traffic to leadGenService pods |
| CDN | none | Internal service only -- no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Development and local integration testing | us-east-1 | Internal only |
| staging | Pre-production validation with staging external providers | us-east-1 | Internal only |
| production | Live lead generation pipeline for Sales | us-east-1 | Internal only |

## CI/CD Pipeline

- **Tool**: GitHub Actions
- **Config**: `.github/workflows/` in the lead-gen service repository
- **Trigger**: on-push to main, on-pr for validation, manual dispatch

### Pipeline Stages

1. **Build**: Compile Java service, run unit tests, build Docker image
2. **Test**: Run integration tests against test database and mock external providers
3. **Publish**: Push Docker image to container registry
4. **Deploy staging**: Deploy to staging Kubernetes cluster via Helm
5. **Smoke test**: Run smoke tests against staging environment
6. **Deploy production**: Deploy to production Kubernetes cluster via Helm (manual approval gate)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (leadGenService) | HPA based on CPU and request queue depth | min: 2, max: 8, target CPU: 70% |
| Horizontal (leadGenWorkflows) | Manual scaling based on workflow backlog | min: 1, max: 4 |
| Database connections | Connection pooling via HikariCP | max pool: 20 per pod |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (leadGenService) | 500m | 2000m |
| Memory (leadGenService) | 512Mi | 2Gi |
| CPU (leadGenWorkflows) | 250m | 1000m |
| Memory (leadGenWorkflows) | 256Mi | 1Gi |
| Disk (leadGenDb) | 50Gi | 200Gi |

> Deployment configuration managed by the lead-gen service repository. Resource values are indicative and subject to tuning based on production workload patterns.
