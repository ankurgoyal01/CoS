---
service: "appointment_engine"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: false
orchestration: "vm"
environments: [staging, production]
---

# Deployment

## Overview

The appointment engine is deployed to virtual machines (not containerized) using Capistrano 3.11.0 as the deployment orchestration tool. The Rails API (`continuumAppointmentEngineApi`) and the Resque worker (`continuumAppointmentEngineUtility`) are deployed as separate processes. MySQL, Redis, and Memcached run as managed infrastructure services. This is a traditional Capistrano-based Continuum deployment, consistent with Ruby services on the platform.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None (VM-based) | No Dockerfile evidenced; deployed directly to VMs |
| Orchestration | Capistrano 3.11.0 | Capfile + config/deploy.rb + per-environment configs |
| Load balancer | > No evidence found in codebase. | Internal load balancer fronting Puma instances |
| CDN | None | Backend API service; no CDN layer |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation and integration testing | > No evidence found in codebase. | > No evidence found in codebase. |
| Production | Live consumer and merchant appointment management | > No evidence found in codebase. | > No evidence found in codebase. |

## CI/CD Pipeline

- **Tool**: Capistrano 3.11.0 (deployment); > No evidence found in codebase for CI test tooling.
- **Config**: `Capfile`, `config/deploy.rb`, `config/deploy/<environment>.rb`
- **Trigger**: Manual Capistrano deploy command; > No evidence found in codebase for automated CI trigger.

### Pipeline Stages

1. **Bundle Install**: Capistrano runs `bundle install` on target server to restore gem dependencies
2. **Database Migrate**: Capistrano runs `rails db:migrate` to apply pending schema migrations
3. **Asset Precompile**: Capistrano runs `rails assets:precompile` if applicable
4. **Restart API**: Capistrano restarts Puma server process (`continuumAppointmentEngineApi`)
5. **Restart Workers**: Capistrano restarts Resque worker processes (`continuumAppointmentEngineUtility`)

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (API) | Manual / Capistrano multi-server deploy | > No evidence found in codebase for replica count |
| Horizontal (Workers) | Manual Resque worker count | > No evidence found in codebase for worker count |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found in codebase. | > No evidence found in codebase. |
| Memory | > No evidence found in codebase. | > No evidence found in codebase. |
| Disk | Persistent (MySQL data, log files) | > No evidence found in codebase. |
