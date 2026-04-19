---
service: "cs-api"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

CS API is a JTier-managed Java/Dropwizard service deployed within the Continuum Platform infrastructure. Deployment follows the standard JTier service deployment model used across Groupon's Continuum services. Specific infrastructure details (Kubernetes manifests, Dockerfile paths, pipeline configs) are managed in the service's own repository and are not captured in the central architecture model.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile in service repository |
| Orchestration | Kubernetes (via JTier) | Kubernetes manifests managed by JTier platform tooling |
| Load balancer | > No evidence found | Assumed JTier / Continuum platform standard |
| CDN | None | Internal CS agent tool; not publicly exposed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local development and integration testing | Local / dev cluster | > No evidence found |
| Staging | Pre-production validation; uses Salesforce QA sandbox | > No evidence found | > No evidence found |
| Production | Live agent tooling for CS operations | > No evidence found | > No evidence found |

## CI/CD Pipeline

- **Tool**: > Deployment configuration managed externally in the service repository
- **Config**: > No evidence found in central architecture model
- **Trigger**: > No evidence found

### Pipeline Stages

> Deployment configuration managed externally. Typical JTier pipeline stages are:

1. Build: Maven compile and test
2. Package: Docker image build and push
3. Deploy to staging: Kubernetes rollout to staging environment
4. Deploy to production: Kubernetes rollout to production environment (manual approval or automated gate)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found | Assumed JTier / Kubernetes HPA |
| Memory | > No evidence found | Managed by JTier platform defaults |
| CPU | > No evidence found | Managed by JTier platform defaults |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | Minimal (stateless service) | > No evidence found |

> Deployment configuration managed externally. Contact GSO Engineering (nsanjeevi) for environment-specific deployment details.
