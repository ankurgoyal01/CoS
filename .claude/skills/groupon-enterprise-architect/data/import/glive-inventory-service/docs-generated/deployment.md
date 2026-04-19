---
service: "glive-inventory-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

GLive Inventory Service is deployed as a containerized application within Groupon's Continuum infrastructure. The service runs two distinct process types: the Rails API server (handling HTTP requests fronted by Varnish) and Resque/ActiveJob workers (processing background jobs from Redis queues). Both share the same Docker image and codebase but are started with different entrypoints. The service depends on externally managed MySQL, Redis, and Varnish instances.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in repository root |
| Orchestration | Kubernetes | Managed by Groupon platform infrastructure |
| Load balancer | Varnish + upstream LB | Varnish HTTP cache in front of the API; upstream load balancer for traffic distribution |
| CDN | None | API service; no static asset delivery |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and testing | Local | localhost |
| Staging | Pre-production validation with sandbox third-party APIs | US | Internal staging URL |
| Production | Live traffic serving real inventory from third-party providers | US | Internal production URL |

## CI/CD Pipeline

- **Tool**: Groupon internal CI/CD (Jenkins / GitHub Actions)
- **Config**: CI configuration in repository
- **Trigger**: on-push (branch builds), on-merge (staging/production deploys)

### Pipeline Stages

1. **Install dependencies**: Bundle install for Ruby gems
2. **Run tests**: RSpec test suite and linting
3. **Build Docker image**: Build container image with Rails app and worker entrypoint
4. **Push to registry**: Push image to Groupon's container registry
5. **Deploy to staging**: Rolling deployment to staging Kubernetes cluster
6. **Deploy to production**: Rolling deployment to production Kubernetes cluster (after staging validation)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| API horizontal | Auto-scaling based on request load | Kubernetes HPA on CPU/request metrics |
| Worker horizontal | Manual or auto-scaling based on queue depth | Kubernetes replicas scaled by Resque queue backlog |
| MySQL | Managed database scaling | Vertical scaling; read replicas as needed |
| Redis | Managed Redis scaling | Vertical scaling; cluster mode if needed |
| Varnish | Horizontal scaling | Multiple Varnish instances behind load balancer |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Per Kubernetes pod configuration | Per Kubernetes pod configuration |
| Memory | Per Kubernetes pod configuration | Per Kubernetes pod configuration |
| Disk | Minimal (stateless application; persistent data in MySQL/Redis) | Minimal |

> Specific resource request/limit values are managed in Kubernetes manifests and Groupon infrastructure configuration. The service itself is stateless; all persistent state resides in MySQL and Redis.
