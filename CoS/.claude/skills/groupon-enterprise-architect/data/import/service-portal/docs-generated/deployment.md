---
service: "service-portal"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Service Portal is deployed as Docker containers orchestrated by Kubernetes. Two distinct container types run from the same image: the web process (Puma, serving the Rails API) and the worker process (Sidekiq, running background jobs). The base image is Alpine 3.22 for minimal footprint. CI/CD is managed by Jenkins. MySQL and Redis are provisioned as managed infrastructure outside the application containers.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | Docker (Alpine 3.22) | `Dockerfile` in repo root; Alpine 3.22 base |
| Web process | Puma | `continuumServicePortalWeb`; runs Rails app; bound to `PORT` (default 3000) |
| Worker process | Sidekiq | `continuumServicePortalWorker`; runs in separate container/pod from same image |
| Orchestration | Kubernetes | Kubernetes manifests manage deployments, services, config maps, and secrets |
| Load balancer | Kubernetes Service / Ingress | Ingress routes external traffic to Puma pods |
| CDN | No evidence found | > Not applicable |
| Database | MySQL (managed) | `continuumServicePortalDb`; provisioned outside Kubernetes |
| Cache / Queue | Redis (managed) | `continuumServicePortalRedis`; provisioned outside Kubernetes |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer environment | local | `http://localhost:3000` |
| staging | Pre-production integration testing | Groupon data center / cloud | Internal staging URL |
| production | Live production environment | Groupon data center / cloud | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` (in service repository)
- **Trigger**: On push to main branch; on pull request; manual dispatch

### Pipeline Stages

1. **Install dependencies**: Runs `bundle install` to install Ruby gems
2. **Test**: Runs the Rails test suite (`bundle exec rails test` or RSpec)
3. **Lint**: Runs RuboCop for code style checks
4. **Build image**: Builds Docker image tagged with commit SHA and branch
5. **Push image**: Pushes Docker image to internal container registry
6. **Deploy to staging**: Applies Kubernetes manifests to staging cluster (on main branch)
7. **Deploy to production**: Applies Kubernetes manifests to production cluster (on approved release or manual trigger)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Web horizontal | Kubernetes HPA or manual replica count | Configured in Kubernetes deployment manifest |
| Worker horizontal | Manual replica count or Kubernetes HPA | Separate Kubernetes deployment for Sidekiq workers |
| Memory | Kubernetes resource limits | Configured in Kubernetes deployment manifest |
| CPU | Kubernetes resource limits | Configured in Kubernetes deployment manifest |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory | Deployment configuration managed externally | Deployment configuration managed externally |
| Disk | Stateless containers; no persistent disk | Not applicable |

> Exact CPU/memory requests and limits are defined in Kubernetes manifests managed outside this repository. Contact the Service Portal Team (service-portal-team@groupon.com) for current values.
