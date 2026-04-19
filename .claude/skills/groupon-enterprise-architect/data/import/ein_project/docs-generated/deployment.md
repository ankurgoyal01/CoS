---
service: "ein_project"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

ProdCat is deployed as a set of containerized workloads on Google Kubernetes Engine (GKE) within the Continuum Platform GCP project. Three runtime containers are deployed: Nginx proxy (ingress), Django/Gunicorn web application, and the RQ background worker. Persistent state is hosted on Google Cloud managed services: Cloud SQL for PostgreSQL and Memorystore for Redis. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container runtime | Docker | Containerized Python/Django app and RQ worker |
| Orchestration | Kubernetes (GKE) | Manages web app, worker, and proxy pod lifecycles |
| Proxy / ingress | Nginx (`continuumProdcatProxy`) | Reverse proxy for all inbound HTTP traffic |
| Database | Cloud SQL PostgreSQL (`continuumProdcatPostgres`) | Managed PostgreSQL instance on GCP |
| Cache / queue | Memorystore Redis (`continuumProdcatRedis`) | Managed Redis instance on GCP |
| Load balancer | GCP Load Balancer / Hybrid Boundary (`hybridBoundarySystem_unk_a2b1`) | Routes external traffic to Nginx |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and feature testing | Local / GCP dev project | Not applicable |
| Staging | Pre-production integration and QA | GCP staging project | Internal only |
| Production | Live deployment compliance enforcement | GCP production project | Internal only |

## CI/CD Pipeline

- **Tool**: GitHub Actions (Jarvis / Groupon CI standard)
- **Config**: Managed externally to this architecture repository
- **Trigger**: On push to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Lint and test: Run Python linting and Django test suite
2. Build: Build Docker image and push to GCP Container Registry
3. Deploy: Apply Kubernetes manifests to target environment
4. Smoke test: Verify `/api/heartbeat/` returns healthy

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Web App) | Kubernetes HPA | Scaled on CPU utilization; min/max replicas managed externally |
| Horizontal (Worker) | Kubernetes Deployment | Worker replica count configured externally |
| Memory | Kubernetes resource limits | Requests and limits configured in deployment manifests managed externally |
| CPU | Kubernetes resource limits | Requests and limits configured in deployment manifests managed externally |

## Resource Requirements

> Deployment configuration managed externally. Resource requests and limits are defined in Kubernetes manifests outside this architecture repository. Contact the Jarvis team (deployment@groupon.com) for current sizing.
