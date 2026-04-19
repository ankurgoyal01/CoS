---
service: "identity-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

identity-service is a containerized Ruby/Puma application deployed on the Continuum platform. It runs two distinct workloads: the Sinatra HTTP API (served by Puma) and the Mbus consumer worker (Resque-backed). Both workloads share the same codebase and container image but are launched with different entrypoints. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Ruby 3.0.2 image; Puma web server for HTTP API workload; Resque worker for Mbus consumer workload |
| Orchestration | Kubernetes | Separate Deployments for HTTP API and Mbus consumer; manifests managed externally |
| Load balancer | To be confirmed | Routes HTTPS traffic to `continuumIdentityServiceApp` pods |
| CDN | None | Internal service; not exposed through a CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and testing | Local | `localhost:9292` (default Puma port) |
| Staging | Pre-production validation | To be confirmed | Configured via internal service registry |
| Production | Live identity management for all Groupon platforms | To be confirmed | Configured via internal service registry |

## CI/CD Pipeline

- **Tool**: To be confirmed — deployment configuration managed externally
- **Config**: Not present in this repository
- **Trigger**: On merge to main branch (inferred Continuum standard)

### Pipeline Stages

1. Test: Run RSpec test suite; enforce coverage thresholds
2. Lint: Run RuboCop static analysis
3. Build: Package application into Docker image; push to container registry
4. Migrate: Apply pending ActiveRecord database migrations to target environment
5. Deploy HTTP API: Rolling update of `continuumIdentityServiceApp` Kubernetes Deployment
6. Deploy Mbus Consumer: Rolling update of `continuumIdentityServiceMbusConsumer` Kubernetes Deployment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (HTTP API) | HPA based on CPU or request rate | Min/max replicas managed externally |
| Horizontal (Mbus Consumer) | Manual or HPA based on Resque queue depth | Min/max replicas managed externally |
| Memory | Puma worker count controlled by `WEB_CONCURRENCY` | Managed externally |
| CPU | To be confirmed | Managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | To be confirmed | To be confirmed |
| Memory | To be confirmed | To be confirmed |
| Disk | Minimal (stateless app layer; data in PostgreSQL/Redis) | To be confirmed |

> Deployment configuration managed externally. Contact the Identity / Account Management team for current resource limits and Kubernetes manifest details.
