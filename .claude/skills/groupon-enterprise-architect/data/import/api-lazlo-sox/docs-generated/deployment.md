---
service: "api-lazlo-sox"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: ["development", "staging", "production", "sox-production"]
---

# Deployment

## Overview

API Lazlo and API Lazlo SOX are deployed as separate containerized Java applications on Kubernetes (GKE). Each service runs as an independent deployment with its own scaling, configuration, and health check policies. The SOX variant is deployed to a separate namespace or cluster to enforce compliance isolation. Both services connect to a shared managed Redis cluster (GCP MemoryStore).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Java 11 (Eclipse Temurin) base image with Vert.x/Lazlo fat JAR |
| Orchestration | Kubernetes (GKE) | Separate deployments for API Lazlo and API Lazlo SOX |
| Load balancer | GCP Load Balancer / Akamai | External traffic routing and SSL termination |
| CDN | Akamai | Edge caching and DDoS protection for static content and cacheable API responses |
| Cache | GCP MemoryStore (Redis) | Managed Redis cluster shared by both deployments |

## Environments

| Environment | Purpose | Region | Description |
|-------------|---------|--------|-------------|
| Development | Local and shared dev | - | Local Docker or shared dev Kubernetes cluster |
| Staging | Pre-production testing | Multi-region | Integration testing with staging downstream services |
| Production | Live traffic | Multi-region | Full production deployment serving mobile and web traffic |
| SOX Production | SOX-regulated live traffic | Multi-region | Separate deployment for SOX-regulated partner and user flows |

## CI/CD Pipeline

- **Tool**: Jenkins / GitHub Actions
- **Trigger**: On push to main, pull request validation, manual dispatch

### Pipeline Stages

1. **Build**: Compile Java source, run unit tests, produce Vert.x fat JAR
2. **Test**: Run integration tests against mock downstream services
3. **Docker Build**: Build Docker image with Eclipse Temurin 11 base
4. **Push**: Push Docker image to container registry
5. **Deploy Staging**: Roll out to staging Kubernetes cluster
6. **Smoke Test**: Run smoke tests against staging endpoints
7. **Deploy Production**: Rolling deployment to production Kubernetes cluster
8. **Deploy SOX Production**: Separate rolling deployment to SOX Kubernetes environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Horizontal Pod Autoscaler (HPA) | Scales based on CPU and request rate |
| Vertical | Resource requests and limits per pod | Tuned per environment |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Per-environment tuning | Per-environment tuning |
| Memory | Per-environment tuning (JVM heap + overhead) | Per-environment tuning |
| Disk | Minimal (stateless service, logs to stdout) | Minimal |

> Specific resource values are managed in Kubernetes manifests and Helm values per environment. API Lazlo is a stateless service; disk usage is minimal.

## Deployment Topology

```
                    [Akamai CDN / LB]
                          |
                 +--------+--------+
                 |                 |
        [API Lazlo Service]  [API Lazlo SOX Service]
        (K8s Deployment)     (K8s Deployment, SOX namespace)
                 |                 |
                 +--------+--------+
                          |
                [API Lazlo Redis Cache]
                (GCP MemoryStore)
                          |
              +-----------+-----------+
              |           |           |
        [Users Svc]  [Deals Svc]  [Orders Svc]  ... (downstream services)
```
