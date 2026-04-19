---
service: "online_booking_3rd_party"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

`online_booking_3rd_party` is a containerized Ruby on Rails application deployed on the Continuum platform. The service ships two runtime processes — the Puma web server (API container) and Resque workers (Workers container) — each deployed independently to allow independent scaling. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Containerized Ruby on Rails application |
| Orchestration | Kubernetes (Continuum platform) | Managed externally |
| Load balancer | Internal platform load balancer | Routes HTTP traffic to API pods |
| CDN | Not applicable | Internal service; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and integration testing | Local | localhost |
| staging | Pre-production integration validation | Groupon staging region | Internal staging URL |
| production | Live production traffic | Groupon production region | Internal production URL |

## CI/CD Pipeline

- **Tool**: Deployment configuration managed externally to this repository
- **Config**: Deployment configuration managed externally
- **Trigger**: Deployment configuration managed externally

### Pipeline Stages

> Deployment configuration managed externally. Typical Continuum service pipeline includes:

1. Build: Compile assets, bundle gems, build Docker image
2. Test: Run unit and integration test suite
3. Push: Push Docker image to container registry
4. Deploy: Roll out to Kubernetes via platform tooling
5. Smoke test: Hit `/v3/smoke_tests` to verify integration health

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA or manual replica count | Managed externally |
| Memory | Managed externally | Managed externally |
| CPU | Managed externally | Managed externally |

## Resource Requirements

> Deployment configuration managed externally.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Managed externally | Managed externally |
| Memory | Managed externally | Managed externally |
| Disk | Managed externally | Managed externally |
