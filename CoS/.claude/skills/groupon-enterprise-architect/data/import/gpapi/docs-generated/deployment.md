---
service: "gpapi"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

gpapi is a containerized Ruby on Rails application deployed on the Continuum platform. The application server is Puma (v6.3.1) running within a Docker container. Deployment configuration is managed externally to this repository following Continuum platform conventions. The service runs in Kubernetes on Groupon infrastructure across development, staging, and production environments.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` in service root |
| Orchestration | Kubernetes | Manifests managed by Continuum platform team |
| Load balancer | Kubernetes Ingress / ALB | Fronts `continuumGpapiService` |
| CDN | None | Internal service; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and feature testing | local | `http://localhost:3000` |
| staging | Pre-production integration testing | AWS us-east-1 | Internal staging URL |
| production | Live vendor portal operations | AWS us-east-1 | Internal production URL |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Continuum platform standard)
- **Config**: `.github/workflows/` (managed in service repo)
- **Trigger**: On push to feature branches (test); on merge to main (deploy to staging); manual dispatch (deploy to production)

### Pipeline Stages

1. **Lint**: Runs RuboCop for code style checks
2. **Test**: Executes RSpec test suite (`rspec-rails` v5.1.2)
3. **Build**: Builds Docker image and pushes to container registry
4. **Deploy Staging**: Applies Kubernetes manifests to staging cluster
5. **Deploy Production**: Applies Kubernetes manifests to production cluster (gated by approval)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (Horizontal Pod Autoscaler) | Min/max replicas managed by platform team |
| Memory | Kubernetes resource limits | Managed by platform team |
| CPU | Kubernetes resource limits | Managed by platform team |
| Puma workers | Environment variable | `PUMA_WORKERS` (default: 2) |
| Puma threads | Environment variable | `PUMA_THREADS` (default: 1:5) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Deployment configuration managed externally | Deployment configuration managed externally |
| Memory | Deployment configuration managed externally | Deployment configuration managed externally |
| Disk | Stateless; no persistent disk required (DB is external) | — |

> Deployment configuration managed externally by the Continuum platform team. Contact the Goods Platform team for specific resource limits and replica counts per environment.
