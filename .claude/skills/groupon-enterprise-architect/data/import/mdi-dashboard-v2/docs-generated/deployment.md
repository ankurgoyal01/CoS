---
service: "mdi-dashboard-v2"
title: Deployment
generated: "2026-03-03T00:00:00Z"
type: deployment
containerized: false
orchestration: "vm"
environments: [development, staging, production]
---

# Deployment

## Overview

mdi-dashboard-v2 is deployed to virtual machines using Napistrano (Groupon's internal Capistrano-based deployment toolchain). It is not containerized. The CI/CD pipeline is managed by Jenkins. The application runs as a Node.js process on each VM, served by the itier-server framework. Production is deployed across three datacenters: snc1 (Santa Clara), sac1 (Sacramento), and dub1 (Dublin).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | none | Not containerized; deployed directly to VMs |
| Orchestration | VM / Napistrano | Capistrano-based toolchain for VM-targeted deployments |
| Load balancer | Internal load balancer | Distributes traffic across VM instances per datacenter |
| CDN | none | Internal tool; not served via CDN |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| development | Local developer environment | Local | http://localhost:3000 |
| staging | Pre-production validation | — | Internal staging URL (not publicly documented) |
| production (snc1) | Production — Santa Clara datacenter | snc1 | Internal production URL |
| production (sac1) | Production — Sacramento datacenter | sac1 | Internal production URL |
| production (dub1) | Production — Dublin datacenter | dub1 | Internal production URL |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: Napistrano deploy scripts (repository-internal)
- **Trigger**: Manual deploy trigger via Jenkins job; branch-based builds on push

### Pipeline Stages

1. **Build**: Installs npm dependencies; runs Gulp build tasks (CoffeeScript compilation, asset bundling)
2. **Test**: Runs unit and integration test suite
3. **Package**: Packages application artifacts for deployment
4. **Deploy**: Napistrano deploys packaged application to target VM fleet across configured datacenters

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual VM provisioning | Number of VMs per datacenter managed by operations team |
| Memory | OS-level limits | Deployment procedures to be defined by service owner |
| CPU | OS-level limits | Deployment procedures to be defined by service owner |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | > No evidence found | > No evidence found |
| Memory | > No evidence found | > No evidence found |
| Disk | > No evidence found | > No evidence found |

> Deployment configuration managed externally via Napistrano scripts. Exact resource allocations are defined in the infrastructure provisioning layer managed by the operations team.
