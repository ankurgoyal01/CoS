---
service: "web-config"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "git-repository"
    type: "git"
    purpose: "Version-controlled source of truth for all config templates, data files, and generated artifacts"
---

# Data Stores

## Overview

web-config is predominantly stateless at runtime. Its primary "data store" is the Git repository itself, which holds all Mustache templates, YAML data files (per-environment defaults, virtual host specs, rewrite rules), and the generated `conf/` output artifacts committed after each build. There is no database, cache, or object-store dependency.

## Stores

### Git Repository (`git-repository`)

| Property | Value |
|----------|-------|
| Type | git |
| Architecture ref | `continuumWebConfigService` |
| Purpose | Stores config templates (`templates/`), environment data (`data/`), and committed generated config (`conf/nginx/k8s/`) |
| Ownership | owned |
| Migrations path | N/A — schema-free YAML/Mustache files |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `data/{env}/defaults/default.yml` | Default configuration values shared across all virtual hosts for a given environment | listen_port, server_admin, log_path, conf_path, default_error_pages |
| `data/{env}/defaults/nginx_cloud.yml` | nginx-platform-specific defaults for cloud deployments | brotli, cloud-specific overrides |
| `data/{env}/sites/*.yml` | Per-country virtual-host specification | virtual_hosts, languages, brand, custom_hosts, error_pages |
| `data/{env}/rewrites/nginx.*` | nginx rewrite rules per country and category (deals, lpo, domain, etc.) | rewrite directives |
| `data/shared/rewrites/nginx.all_envs.us` | US redirect rules shared across all environments | rewrite directives |
| `templates/nginx/*.mustache` | Mustache templates for main.conf, virtual_host.conf, includes | — |
| `conf/nginx/k8s/{env}/` | Generated output committed to repo after each build | main.conf, virtual_hosts/*.conf, includes/*.conf |
| `REVISION` (on routing host) | Records the deployed Git SHA on each routing server | Git SHA string |
| `META` (on routing host) | Records deployment metadata on each routing server | deployment timestamp, user |

#### Access Patterns

- **Read**: Generator pipeline reads YAML data files and Mustache templates from the working tree at build time; Redirect CLI reads rewrite rule files before prepending new rules.
- **Write**: Generator writes rendered config files to `conf/nginx/k8s/{env}/`; Redirect CLI prepends nginx rewrite entries to the appropriate `data/{env}/rewrites/nginx.*` file; Jenkins pipeline commits updated files and pushes to origin.
- **Indexes**: Not applicable (file-system access by path convention).

## Caches

> No evidence found in codebase. No Redis, Memcached, or in-process caching is used.

## Data Flows

1. Operators edit YAML data files or Mustache templates in the repository.
2. The Fabric `generate` task reads data files and renders templates, writing output into `conf/nginx/k8s/{env}/`.
3. Generated artifacts are committed to the repository and pushed to origin (enforced by the PR workflow).
4. Jenkins CI builds Docker images from the committed `conf/` directory and pushes them to `docker-conveyor.groupondev.com/routing/web-config:{env}_{version}`.
5. The kustomize deployment step updates image tags in the `routing-deployment` repository, triggering a Kubernetes rolling update.
6. For redirect flows, the Redirect Automation CLI prepends rewrite rules to the appropriate data file, commits, and pushes the branch; after PR merge the normal generate/deploy cycle picks up the changes.
