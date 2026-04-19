---
service: "leadminer"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [development, staging, production]
---

# Deployment

## Overview

Leadminer is a Rails web application deployed as part of the Continuum platform. Deployment follows standard Continuum service conventions. Specific Docker, Kubernetes, and CI/CD configuration details are not discoverable from the inventory; operational procedures are managed by the Continuum platform team.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Dockerfile path not discoverable from inventory |
| Orchestration | Kubernetes (Continuum standard) | Manifest paths not discoverable from inventory |
| Load balancer | Not discoverable from inventory | Continuum platform standard |
| CDN | Not applicable | Internal tool; no CDN needed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local development and testing | Local | localhost |
| staging | Pre-production integration testing | Not discoverable | Not discoverable |
| production | Live internal editorial tool | Not discoverable | Not discoverable |

## CI/CD Pipeline

- **Tool**: Not discoverable from inventory
- **Config**: Not discoverable from inventory
- **Trigger**: Not discoverable from inventory

### Pipeline Stages

> Deployment configuration managed externally. Pipeline stages follow Continuum platform standard CI/CD conventions.

1. **Test**: Run RSpec test suite (rspec-rails 3.0.0, capybara 2.6.0)
2. **Build**: Bundle dependencies with Bundler 1.17.2, build Docker image
3. **Deploy**: Push to target environment via Continuum platform deployment tooling

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Continuum platform standard | Not discoverable from inventory |
| Memory | Continuum platform standard | Not discoverable from inventory |
| CPU | Continuum platform standard | Not discoverable from inventory |

## Resource Requirements

> Deployment configuration managed externally. Resource limits follow Continuum platform conventions for Rails web services.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable | Not discoverable |
| Memory | Not discoverable | Not discoverable |
| Disk | Minimal (no local DB) | Not discoverable |
