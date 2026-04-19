---
service: "metro-draft-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Metro Draft Service is a JTier/Dropwizard Java 11 application deployed on the Continuum platform. It follows standard Continuum deployment patterns: containerized via Docker, orchestrated on Kubernetes, and built/deployed through the Groupon CI/CD pipeline. Deployment configuration is managed externally to this architecture repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier Dropwizard container image |
| Orchestration | Kubernetes | Standard Continuum k8s deployment |
| Load balancer | Internal k8s service / ALB | Routes internal Metro tooling and self-service portal traffic |
| CDN | Not applicable | Backend service; not directly CDN-fronted |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local / dev cluster | Internal dev endpoint |
| Staging | Pre-production validation against staging Continuum services | Groupon staging region | Internal staging endpoint |
| Production | Live merchant deal drafting traffic | Groupon production region | Internal production endpoint |

> Exact URLs and regions are managed externally. Contact the Metro Team (metro-dev-blr@groupon.com) for environment-specific endpoints.

## CI/CD Pipeline

- **Tool**: Groupon internal CI/CD (Jenkins / GitHub Actions — confirm with team)
- **Config**: Deployment configuration managed externally to this architecture repository
- **Trigger**: On merge to main branch; manual dispatch for hotfixes

### Pipeline Stages

1. Build: Maven compile and package (`mvn package`)
2. Test: Unit and integration tests
3. Docker build: Produce container image tagged with commit SHA
4. Database migration: Run jtier-migrations against target environment databases
5. Deploy: Kubernetes rolling update to target environment
6. Smoke test: Health check validation post-deploy

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Min/max replicas managed externally |
| Memory | JVM heap tuning | Configured via JVM args in deployment manifest |
| CPU | k8s resource limits | Configured in k8s deployment spec |

## Resource Requirements

> Deployment configuration managed externally. Contact the Metro Team for current resource request/limit values.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed externally | Managed externally |
| Memory | Managed externally | Managed externally |
| Disk | Stateless (no local disk required) | N/A |
