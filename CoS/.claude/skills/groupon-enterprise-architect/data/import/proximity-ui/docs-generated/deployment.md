---
service: "proximity-ui"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: [development, staging, staging_emea, production, production_dub1, production_sac1]
---

# Deployment

## Overview

Proximity UI is deployed as a bare Node.js process on virtual machines (bare-metal servers using Groupon's internal `snc1`, `dub1`, and `sac1` data centers). There is no containerization (no Dockerfile). The application is kept alive by the `forever` process manager. Static assets are built via Webpack and served from the `/dist` directory by Nginx. Deployment is performed manually via a Fabric (`fab`) Python script that SSH-es into the target hosts, runs `git pull`, `npm install`, and `NODE_ENV=<env> npm run build`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile; bare Node.js process |
| Process manager | forever 0.15.3 | Restarts Node.js on crash; configured in `package.json` build script |
| Web server / Static files | Nginx | Hooks up static built files under `/dist`; injects `X-Remote-User` header |
| Application directory | VM filesystem | `/var/groupon/proximity-ui` on each host |
| Orchestration | Manual VM | SSH-based via Fabric deploy script (`fabfile.py`) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `development` | Local developer workstation | Local | `http://localhost:8080` |
| `staging` | QA / pre-production (SNC1) | SNC1 | `http://proximity-ui-app1-staging.snc1` |
| `staging_emea` | QA / pre-production (EMEA) | SNC1 (EMEA VIP) | `http://proximity-ui-emea-app1-staging.snc1` |
| `production` | Production (SNC1, primary US) | SNC1 | `proximity.groupondev.com` |
| `production_dub1` | Production (DUB1, EMEA) | DUB1 | `proximity-dub1.groupondev.com` |
| `production_sac1` | Production (SAC1, US West failover) | SAC1 | Not listed in README |

## Hosts

| Environment | Hosts |
|-------------|-------|
| `staging` | `proximity-ui-app1-staging.snc1` |
| `staging_emea` | `proximity-ui-emea-app1-staging.snc1` |
| `production` | `proximity-ui-app1.snc1`, `proximity-ui-app2.snc1` |
| `production_dub1` | `proximity-ui-app1.dub1`, `proximity-ui-app2.dub1` |
| `production_sac1` | `proximity-ui-app1.sac1`, `proximity-ui-app2.sac1` |

## CI/CD Pipeline

- **Tool**: Fabric (Python `fabfile.py`) — manual deploy only
- **Config**: `fabfile.py` (repo root)
- **Trigger**: Manual — engineer runs `fab deploy_staging` or `fab deploy_prod` locally, or `fab deploy:<env>` for other targets

### Pipeline Stages

1. **Confirm push**: Prompts engineer to confirm all commits are pushed to master before proceeding
2. **SSH to hosts**: Fabric SSHes into each target host in sequence
3. **Git pull**: Runs `git pull origin master` from `/var/groupon/proximity-ui`
4. **Install dependencies**: Runs `npm install`
5. **Build assets**: Runs `NODE_ENV=<env> npm run build` (which calls `forever stopall && NODE_ENV=$NODE_ENV forever start build/build.js`)
6. **Verify**: Curls `http://{host}:8080/#!/summary` up to 10 times with 2-second backoff to confirm the app is serving

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual — two production hosts per US region | `proximity-ui-app1.*`, `proximity-ui-app2.*` per data center |
| Memory | Not configured | No resource limits in evidence |
| CPU | Not configured | No resource limits in evidence |

## Resource Requirements

> Deployment configuration managed externally. No CPU, memory, or disk resource specifications are committed to this repository.
