---
service: "lpapi"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: false
orchestration: "vm"
environments: [development, staging, production]
---

# Deployment

## Overview

LPAPI is deployed as a JVM-based Dropwizard/JTier application using Capistrano for artifact promotion and environment configuration management. The deployment model follows the Continuum Platform pattern for legacy Java services — packaged as a Maven artifact, deployed to VMs, and configured via per-environment YAML files. No Docker or Kubernetes orchestration is modeled.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Deployed as JVM process on VM |
| Orchestration | VM / Capistrano | Capistrano manages deployment tasks and environment config |
| Load balancer | > No evidence found | Likely JTier-managed or platform load balancer |
| CDN | None | Internal-only service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local/developer testing | local | > No evidence found |
| Staging | Integration and pre-production testing | > No evidence found | > No evidence found |
| Production | Live SEO landing page data service | > No evidence found | > No evidence found |

## CI/CD Pipeline

- **Tool**: Maven + Capistrano
- **Config**: > Not discoverable from the federated architecture module — managed within service repository
- **Trigger**: > Not discoverable from the federated architecture module

### Pipeline Stages

1. **Build**: Maven compiles the Java source and packages the application artifact
2. **Test**: Maven runs unit and integration tests
3. **Deploy**: Capistrano promotes the artifact to the target environment and applies environment-specific configuration

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found — likely manual VM provisioning | > No evidence found |
| Memory | JVM heap settings via startup flags | > No evidence found |
| CPU | > No evidence found | > No evidence found |

## Resource Requirements

> Deployment configuration managed externally. Resource requirements are defined in the service repository and deployment runbooks, not in the federated architecture module.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | > No evidence found | > No evidence found |
