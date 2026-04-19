---
service: "deploybot"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [local, development, staging, production]
---

# Deployment

## Overview

deploybot is containerized using a multi-stage Docker build on `golang:1.23.12-alpine`. It runs in a Kubernetes deployment within the `deploybot` namespace using a dedicated service account. Legacy deployment targets (pre-Kubernetes) used Docker Swarm on `snc1` and `sac1` data centers. CI is handled by Jenkins via a `Jenkinsfile`. Four environments are supported: `local`, `development`, `staging`, and `production`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Multi-stage Go build on `golang:1.23.12-alpine`; Alpine Linux runtime base |
| Orchestration | Kubernetes | `deploybot` namespace; dedicated Kubernetes service account |
| Legacy Orchestration | Docker Swarm | Legacy deployment on `snc1`/`sac1` data centers |
| Init Container | `deploybotInitExec` | Runs SSH key setup and Kubernetes auth initialization before main container starts |
| Load balancer | > No evidence found in codebase | |
| CDN | > Not applicable | |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| local | Local developer environment with fake Jira stub | — | localhost |
| development | Integration testing against development-tier services | — | > No evidence found |
| staging | Pre-production validation; mirrors production gates | — | > No evidence found |
| production | Live SOX-compliant deployment orchestration | — | > No evidence found |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile`
- **Trigger**: On push to configured branches; manual dispatch

### Pipeline Stages

1. **Build**: Compiles Go binary via `go build` with module vendoring inside the Docker multi-stage build
2. **Test**: Runs Go test suite (`go test ./...`) using `stretchr/testify` assertions
3. **Docker image build**: Builds the final Alpine-based runtime image
4. **Push to Artifactory**: Publishes the Docker image to Artifactory for deployment use
5. **Deploy**: Applies Kubernetes manifests to the `deploybot` namespace via `kubectl` or Kubernetes API

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | > No evidence found in codebase | — |
| Memory | > No evidence found in codebase | — |
| CPU | > No evidence found in codebase | — |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | > Not applicable (stateless container) | — |

> Kubernetes resource requests/limits and HPA configuration are managed in deployment manifests not present in the service inventory.
