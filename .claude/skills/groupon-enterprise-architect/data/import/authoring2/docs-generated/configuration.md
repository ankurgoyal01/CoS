---
service: "authoring2"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, groupon-app-config]
---

# Configuration

## Overview

Authoring2 uses Groupon's `AppConfig` library (version 1.4) to load configuration from `.properties` files on disk. The active environment is selected by the `ACTIVE_ENV` environment variable (`development`, `staging`, `production`, `uat`). The `CONFIG_FILE` environment variable points to the cloud YAML configuration file path. AppConfig reads property files from the classpath and overlays them in environment order. Properties cover database connectivity, queue connectivity, deploy activation endpoints, and Skeletor Java framework settings.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ACTIVE_ENV` | Selects the AppConfig environment profile (`development`, `staging`, `production`, `uat`) | Yes | — | Kubernetes env (cloud deployment config) |
| `CONFIG_FILE` | Path to the cloud deployment YAML config file | Yes (cloud) | — | Kubernetes env (cloud deployment config) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual-memory explosion in containers | No | `4` | `common.yml` |

## Feature Flags

> No evidence found in codebase. No runtime feature flag system is configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/props/app_config.properties` | Properties | AppConfig base settings and environment profile list |
| `src/main/resources/props/authoring2.development.properties` | Properties | Skeletor heartbeat path and local dev overrides |
| `src/main/resources/props/db.<env>.properties` | Properties | PostgreSQL connection settings per environment |
| `src/main/resources/props/queue.<env>.properties` | Properties | ActiveMQ queue connection settings per environment |
| `src/main/resources/props/deploy.<env>.properties` | Properties | TaxonomyV2 activation endpoint URLs and snapshot deploy settings |
| `src/main/resources/props/skeletor.global.properties` | Properties | Skeletor Java global settings (verbose status enabled) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Kubernetes pod spec: scaling, ports, resource requests, sidecar config |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP us-central1 overrides (min 2, max 4 replicas) |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production GCP us-west-1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides (min 1, max 2 replicas) |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging GCP us-west-1 overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `db.password` | PostgreSQL application user password | Groupon secrets repo (referenced in `db.<env>.properties`) |
| `queue.password` | ActiveMQ broker user password | `queue.<env>.properties` |
| `deploy.live.password` | PostgreSQL password for snapshot deploy DB connection | `deploy.production.properties` |

> Secret values are NEVER documented here. Names and sources only.

## Per-Environment Overrides

### Database (`db.<env>.properties`)

| Property | Development | Staging | Production |
|----------|-------------|---------|-----------|
| `db.host` | `localhost` (SSH tunnel) | `taxonomyV2-rw-na-staging-db.*` | `taxonomyV2-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| `db.name` | local dev name | staging DB name | `taxonomyv2_prod` |
| `db.port` | local tunnel port | `5432` | `5432` |
| `db.username` | local user | staging app user | `taxonomyv2_prod_app` |

### Queue (`queue.<env>.properties`)

| Property | All Environments |
|----------|-----------------|
| `queue.host` | `localhost` (ActiveMQ sidecar) |
| `queue.port` | `61616` |
| `queue.name` | `Authoring2` |
| `queue.user` | `system` |

### Deploy activation (`deploy.production.properties`)

| Property | Value |
|----------|-------|
| `deploy.live.activation_ep` | `http://taxonomyv2.production.service/snapshots/activate` |
| `pt_deploy.live.activation_ep` | `http://taxonomyv2.production.service/partialsnapshots/liveactivate` |
| `deploy.snapshot.create` | `true` |
| `deploy.redirect.url` | `https://taxonomy-authoringv2.groupondev.com/` |

### Skeletor global

| Property | Value |
|----------|-------|
| `skeletor.verbose_production_status` | `true` |
| `skeletor.heartbeat_path` (dev only) | `/tmp/heartbeat.txt` |
