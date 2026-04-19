---
service: "deal_wizard"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: false
orchestration: "vm"
environments: [development, staging, production]
---

# Deployment

## Overview

Deal Wizard is a Ruby on Rails 3.2 application served by Unicorn 6.1.0, deployed as a traditional VM-based application. Given the Ruby 1.9.3 and Rails 3.2 vintage, the service predates standard containerization practices at Groupon. Deployment configuration is managed externally to this repository.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | none | No Dockerfile found in inventory; VM-based deployment |
| Orchestration | VM / traditional | Deployment configuration managed externally |
| Web server | Unicorn 6.1.0 | Multi-process pre-fork server; workers configured via `config/unicorn.rb` |
| Load balancer | Not discoverable | Load balancer configuration managed externally |
| CDN | Not discoverable | CDN configuration managed externally |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Development | Local developer environment | local | http://localhost:3000 |
| Staging | Pre-production validation and QA | Not discoverable | Not discoverable |
| Production | Live internal sales tool for Groupon sales representatives | Not discoverable | Not discoverable |

## CI/CD Pipeline

- **Tool**: Not discoverable from inventory
- **Config**: Deployment configuration managed externally
- **Trigger**: Not discoverable from inventory

### Pipeline Stages

> Deployment configuration managed externally.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual (VM-based) | `UNICORN_WORKERS` env var controls per-instance worker count |
| Memory | Not discoverable | Deployment configuration managed externally |
| CPU | Not discoverable | Deployment configuration managed externally |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not discoverable | Not discoverable |
| Memory | Not discoverable | Not discoverable |
| Disk | Not discoverable | Not discoverable |

> Deployment configuration managed externally.
