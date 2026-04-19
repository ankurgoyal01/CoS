---
service: "deal-book-service"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Deal Book Service is deployed as part of the Continuum platform. It runs as multiple containers: the Rails API application (`dealBookServiceApp`), a background message worker (`dealBookMessageWorker`), and scheduled rake task runners (`dealBookRakeTasks`). All three containers share the same codebase but have different entry points. Owned data stores (`continuumDealBookMysql`, `continuumDealBookRedis`) are provisioned alongside the application. Specific Docker, Kubernetes, and CI/CD configuration details are managed externally and are not discoverable from the inventory.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile path not discoverable from inventory |
| Orchestration | Kubernetes (Continuum standard) | Manifest paths not discoverable from inventory |
| Load balancer | Continuum platform standard | Config not discoverable from inventory |
| CDN | Not applicable | Internal API service |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | Local | localhost |
| staging | Pre-production integration testing | Not discoverable | Not discoverable |
| production | Live deal creation fine print API | Not discoverable | Not discoverable |

## CI/CD Pipeline

- **Tool**: Not discoverable from inventory
- **Config**: Not discoverable from inventory
- **Trigger**: Not discoverable from inventory

### Pipeline Stages

> Deployment configuration managed externally. Pipeline stages follow Continuum platform standard CI/CD conventions.

1. **Test**: Run RSpec test suite; validate MySQL migrations
2. **Build**: Bundle dependencies with Bundler; build Docker image
3. **Deploy API**: Roll out `dealBookServiceApp` container to target environment
4. **Deploy Worker**: Roll out `dealBookMessageWorker` container
5. **Deploy Rake Tasks**: Update scheduled rake tasks via `whenever`/cron configuration

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (API) | Continuum platform standard HPA | Not discoverable from inventory |
| Horizontal (Worker) | Single instance or platform standard | Not discoverable from inventory |
| Memory | Continuum platform standard | Not discoverable from inventory |
| CPU | Continuum platform standard | Not discoverable from inventory |

## Resource Requirements

> Deployment configuration managed externally.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable | Not discoverable |
| Memory | Not discoverable | Not discoverable |
| Disk | Minimal (data in MySQL/Redis) | Not discoverable |
