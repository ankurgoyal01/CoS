---
service: "image-service-config"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: [production, staging, uat]
---

# Deployment

## Overview

The Image Service is deployed on bare-metal or virtual machines within Groupon's SNC1 datacenter. There is no containerization (no Dockerfile present). Configuration is distributed using Capistrano, which SSH/SCPs config files to designated cache and app nodes. Nginx runs on cache nodes; the Python `imageservice.py` app managed by Supervisord runs on app nodes. The two node roles are deployed independently via separate Capistrano tasks.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile present; bare-VM deployment |
| Orchestration | Capistrano | `Capfile` defines all deployment tasks |
| Process manager | Supervisord | Manages 12 Python worker processes per app node (ports 8000–8011) |
| Load balancer (app tier) | Nginx upstream | `upstream backend` round-robins across all active app nodes and ports |
| Load balancer (cache tier) | VIP (`image-service-vip.snc1`) | External VIP routes traffic to cache nodes; heartbeat file controls LB inclusion |
| CDN hostname | `img.grouponcdn.com` | Nginx serves as origin for CDN requests |
| S3 origin | AWS S3 (`image-service.s3.amazonaws.com`) | Primary origin; `image-service-west.s3.amazonaws.com` is backup |
| Nginx proxy cache | Filesystem at `/var/nginx_proxy_cache` | Up to 79 GB (production), 100 GB (UAT); levels=2:2, inactive=30d |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production | Live traffic; 8 cache nodes + 4 app nodes | SNC1 datacenter | `img.grouponcdn.com`, `origin-img.grouponcdn.com`, `image-service-vip.snc1` |
| staging | Pre-production validation; 2 cache nodes + 2 app nodes | SNC1 datacenter | `img-staging.grouponcdn.com`, `origin-img-staging.grouponcdn.com`, `image-service-cache-staging-vip.snc1` |
| uat | User acceptance testing; 1 cache node + 1 app node | SNC1 datacenter | `image-service-cache1-uat.snc1`, `image-service.local` |

### Production Node Inventory

**Cache nodes** (nginx proxy cache tier):
- `image-service-cache1.snc1` through `image-service-cache8.snc1` (8 nodes)

**App nodes** (Python image-service runtime):
- `image-service-app1.snc1`, `image-service-app2.snc1`, `image-service-app3.snc1`, `image-service-app4.snc1`
- Each node runs 12 Supervisord-managed Python processes on ports 8000–8011

### Staging Node Inventory

**Cache nodes**: `image-service-cache1-staging.snc1`, `image-service-cache2-staging.snc1`

**App nodes**: `image-service-app1.snc1`, `image-service-app2.snc1`

## CI/CD Pipeline

- **Tool**: Capistrano (Ruby)
- **Config**: `Capfile`
- **Trigger**: Manual (`cap nginx`, `cap app`, `cap staging`, etc.)

### Pipeline Stages — Cache Node Deployment (`cap nginx`)

1. **Template rendering**: Capistrano renders `nginx.conf.erb` and `upstream-default.conf.erb` using ERB with environment-specific variables
2. **Config distribution**: Capistrano SCPs the rendered nginx.conf, upstream conf, and s3-proxy.conf to each cache node at `/var/groupon/nginx/conf/`
3. **Symlink activation**: `enable_all` task symlinks `upstream-default.conf` to `/etc/nginx/upstream.conf`
4. **Nginx reload**: `sudo /usr/local/etc/init.d/nginx reload` applies new configuration without dropping connections

### Pipeline Stages — App Node Deployment (`cap app`)

1. **App code deploy**: Capistrano deploys `imageservice.py` from `github:seans/image-service.git` to `/data/thepoint`
2. **Config upload**: Uploads `supervisord.conf` and `config.yml` to `/data/thepoint/current` via SCP
3. **Supervisord start/restart**: Starts Supervisord if not running, then restarts all managed processes

### Rolling Restart Procedure

App nodes can be drained from the Nginx upstream one at a time using the disable tasks:
1. `cap disable_app1` — symlinks `upstream-app1-disabled.conf`, removes app1 from backend upstream, reloads nginx
2. Restart app1 (`cap restart` with user confirmation)
3. `cap enable_all` — restores `upstream-default.conf`, reloads nginx
4. Repeat for each app node

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (cache tier) | Manual — add nodes to Capistrano role list in `Capfile` | 8 nodes in production |
| Horizontal (app tier) | Manual — add nodes to Capistrano role list in `Capfile` | 4 nodes in production |
| Process-level (app tier) | Supervisord `numprocs` — 12 workers per node | ports 8000–8011 (`numprocs=12`, `numprocs_start=8000`) |
| Nginx worker processes | Static in nginx.conf | `worker_processes 8` |
| Nginx worker connections | Static in nginx.conf | `worker_connections 16384` |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Nginx proxy cache disk | — | 79 GB per cache node (production); 100 GB (UAT) |
| Nginx open file descriptors | — | `worker_rlimit_nofile 10240` |
| Client body buffer | — | `client_max_body_size 50m` |
| Proxy buffers | — | `proxy_buffers 32 2m`; `proxy_buffer_size 2m` |
| CPU / Memory (VM) | Not specified in config files | Managed externally by infrastructure team |

> Deployment configuration is managed by the `Capfile` in this repository. VM provisioning and OS-level resource allocation are managed externally by the Intl-Infrastructure team.
