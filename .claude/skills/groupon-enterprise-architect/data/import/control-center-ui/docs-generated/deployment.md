---
service: "control-center-ui"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "container"
environments: [development, test, production]
---

# Deployment

## Overview

Control Center UI is deployed as a containerized Ember.js SPA served by Nginx. The Ember build produces static assets (HTML, JS, CSS); Nginx serves these files and acts as a reverse proxy for all `/__/proxies/*` API calls to the DPCC Service and PCCJT Service backends. The Node.js 0.12 runtime is used only during the Ember CLI build phase; the running container is Nginx serving static files.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker (Nginx) | Nginx container serving Ember static build |
| Orchestration | Container (internal Groupon infra) | Deployment details managed by infrastructure team |
| Load balancer | Nginx (internal) | Nginx handles reverse proxying and static serving |
| CDN | None identified | Internal tool; no CDN layer identified in inventory |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer environment with Ember CLI dev server | Local | http://localhost:4200 (Ember CLI default) |
| test | CI test environment for Ember CLI QUnit tests | CI runner | N/A |
| production | Live internal tool for pricing/commerce operations | Groupon infrastructure | Internal URL |

## CI/CD Pipeline

- **Tool**: No evidence found in codebase for specific CI/CD tool; inferred as internal Groupon CI system given the era of the stack (Node.js 0.12 / Ember 1.13).
- **Config**: `package.json` npm scripts; Ember CLI build commands.
- **Trigger**: On push to main/master branch; on pull request (test only).

### Pipeline Stages

1. **Install**: Runs `npm install` to install Ember CLI and all dependencies.
2. **Test**: Runs `ember test` to execute Ember CLI QUnit unit and integration tests.
3. **Build**: Runs `ember build --environment=production` to produce fingerprinted static assets in `dist/`.
4. **Containerize**: Docker build packages the `dist/` output with the Nginx configuration.
5. **Deploy**: Container image pushed to registry; deployed to target environment via internal deployment tooling.
6. **Nginx Proxy Config**: Nginx configured at container startup with upstream service URLs from environment variables.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual / container orchestration | Managed by Groupon infrastructure team |
| Memory | Container limits | Managed by container runtime |
| CPU | Container limits | Managed by container runtime |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in inventory | Not specified in inventory |
| Memory | Not specified in inventory | Not specified in inventory |
| Disk | Nginx static file storage (small) | Managed by container image size |

> Deployment configuration managed externally. Specific container registry paths, orchestration manifests, and deployment pipeline details should be confirmed with the Groupon infrastructure team. Note: Node.js 0.12 is end-of-life; this runtime version carries known security risk and should be a migration priority.
