---
service: "clo-inventory-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "jtier-gcp"
environments: [staging, production]
---

# Deployment

## Overview

CLO Inventory Service is deployed as a JTIER/IS-Core Dropwizard service on Groupon's GCP-based infrastructure. The service follows standard JTIER deployment conventions including containerized deployment, managed data services (DaaS Postgres, Cache Redis), and JTIER service discovery for inter-service communication.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | JTIER-standard Java 11 base image |
| Orchestration | JTIER GCP | Managed by JTIER deployment infrastructure |
| Load balancer | JTIER LB | Standard JTIER load balancing and routing |
| CDN | None | Backend API service; no CDN required |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production testing and validation | GCP (Groupon staging) | Internal JTIER service discovery |
| Production | Live traffic serving | GCP (Groupon production) | Internal JTIER service discovery |

## CI/CD Pipeline

- **Tool**: JTIER CI/CD (Jenkins or equivalent)
- **Config**: Standard JTIER/IS-Core pipeline configuration
- **Trigger**: On merge to main branch; manual deployment for production

### Pipeline Stages

1. **Build**: Compile Java sources, run unit tests, package Dropwizard fat JAR
2. **Test**: Run integration tests against test databases and mock services
3. **Package**: Build Docker image with JTIER base image and fat JAR
4. **Deploy to staging**: Automatic deployment to staging environment
5. **Deploy to production**: Manual promotion from staging to production

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | JTIER auto-scaling based on load | Managed by JTIER infrastructure |
| Memory | JVM heap configuration | Configured per JTIER Java 11 service defaults |
| CPU | JTIER resource allocation | Configured per JTIER service profile |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Per JTIER service profile | Per JTIER service profile |
| Memory | Per JTIER Java 11 defaults | Per JTIER Java 11 defaults |
| Disk | Minimal (stateless; data in DaaS Postgres) | Minimal |

> Deployment configuration managed by JTIER platform infrastructure. Specific resource allocations and scaling thresholds are configured in the JTIER deployment manifest.
