---
service: "corpAD"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: ["production"]
---

# Deployment

## Overview

corpAD is deployed as a traditional on-premises infrastructure service across three Groupon data center colos. It runs on Windows Server-based domain controllers — not containerized, not orchestrated by Kubernetes or ECS. Each colo hosts its own set of Active Directory domain controllers behind a LDAP VIP (`corpldap1.<colo>`). The service is not managed via the standard Groupon ops-config pipeline (`hosting_configured_via_ops_config: false` in `.service.yml`).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | corpAD runs on bare-metal or VM Windows Server domain controllers |
| Orchestration | VM / Windows Server | Active Directory Domain Services on Windows Server |
| Load balancer | Internal VIP | `corpldap1.<colo>` — routes LDAP and HTTPS traffic to available domain controllers per colo |
| CDN | None | Internal-only service; no CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production (snc1) | Primary production directory | snc1 colo | `https://corpldap1.snc1` (internal) |
| Production (dub1) | Production directory — EMEA/DUB colo | dub1 colo | `https://corpldap1.dub1` (internal) |
| Production (sac1) | Production directory — sac1 colo | sac1 colo | `https://corpldap1.sac1` (internal) |

> There is no staging or development environment documented in `.service.yml`. corpAD is production-only infrastructure.

## CI/CD Pipeline

> No evidence found in codebase. corpAD is an infrastructure service with no software CI/CD pipeline. Changes to Active Directory configuration (GPOs, schema extensions, user management) are applied directly by the Syseng team via Active Directory administration tools. Operational procedures are documented in the Owners Manual on Confluence.

### Pipeline Stages

> Not applicable — infrastructure service managed via AD administration tooling.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — additional domain controllers can be added per colo | Determined by Syseng team capacity planning |
| Memory | Per-DC Windows Server configuration | Managed by Syseng operations |
| CPU | Per-DC Windows Server configuration | Managed by Syseng operations |

## Resource Requirements

> Deployment configuration managed externally. Resource provisioning for Active Directory domain controllers is managed by the Syseng team and is not documented in this repository.
