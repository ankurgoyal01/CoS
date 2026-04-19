---
service: "reporting-service"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "ecs"
environments: [dev, staging, production]
---

# Deployment

## Overview

The reporting service is packaged as a Java WAR artifact built by Maven and deployed on a JVM 11 runtime. It follows the standard Continuum platform deployment pattern for WAR-based Spring services. Deployment configuration details (Dockerfile, orchestration manifests, CI/CD pipeline) are managed outside the federated architecture model and should be confirmed with the MX Platform Team.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Java WAR / JVM | Packaged as a WAR by Maven; deployed to a servlet container (e.g., Tomcat) |
| Orchestration | No evidence found | Deployment configuration managed externally |
| Load balancer | No evidence found | Deployment configuration managed externally |
| CDN | No evidence found | Not applicable for a backend API service |

> Deployment configuration managed externally. Infrastructure details to be confirmed with the MX Platform Team.

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| dev | Development and integration testing | No evidence found | No evidence found |
| staging | Pre-production validation | No evidence found | No evidence found |
| production | Live merchant traffic | No evidence found | No evidence found |

## CI/CD Pipeline

- **Tool**: No evidence found in architecture model
- **Config**: No evidence found
- **Trigger**: No evidence found

### Pipeline Stages

> No evidence found in the federated architecture model. Pipeline stages to be confirmed with the MX Platform Team.

1. Build: Maven compile and package (`mvn package`) producing WAR artifact
2. Test: Maven unit and integration test execution
3. Deploy: WAR artifact deployment to target environment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | No evidence found | Confirm with MX Platform Team |
| Memory | No evidence found | Confirm with MX Platform Team |
| CPU | No evidence found | Confirm with MX Platform Team |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | No evidence found | No evidence found |
| Memory | No evidence found | No evidence found |
| Disk | No evidence found | No evidence found |

> Deployment configuration managed externally. Resource requirements and scaling configuration to be confirmed with the MX Platform Team.
