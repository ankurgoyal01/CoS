---
service: "s2s"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "JTier"
environments: [staging, production]
---

# Deployment

## Overview

S2S is deployed as a JTier (Dropwizard-based) Java service within Groupon's Continuum platform. JTier manages service lifecycle, configuration injection, and deployment orchestration. The service is containerized following standard Continuum patterns. Deployment configuration is managed externally by the SEM/Display Engineering team using the JTier deployment system.

> Deployment configuration managed externally. Details below reflect the architecture model and known Continuum platform conventions.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Standard JTier/Dropwizard container image; Dockerfile in service repository |
| Orchestration | JTier / Kubernetes | JTier service mesh within Continuum Kubernetes clusters |
| Load balancer | Internal | JTier internal routing; no public-facing load balancer |
| CDN | Not applicable | S2S is an internal backend service with no public HTTP surface |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production integration testing | > No evidence found | Internal only |
| Production | Live event processing and partner dispatch | > No evidence found | Internal only |

## CI/CD Pipeline

- **Tool**: Groupon internal CI system (JTier-integrated)
- **Config**: > No evidence found of pipeline config path in the architecture model
- **Trigger**: On merge to main branch; manual dispatch available

### Pipeline Stages

1. Build: Maven compile, test, and package (`mvn clean package`)
2. Validate: DSL and schema validation
3. Deploy to staging: JTier deployment to staging environment
4. Deploy to production: JTier deployment to production environment (gated on staging success)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > Deployment configuration managed externally | > No evidence found |
| Memory | > Deployment configuration managed externally | > No evidence found |
| CPU | > Deployment configuration managed externally | > No evidence found |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | > No evidence found | > No evidence found |

> Resource requirements are managed by the JTier deployment configuration. Contact SEM/Display Engineering for current production resource allocations.
