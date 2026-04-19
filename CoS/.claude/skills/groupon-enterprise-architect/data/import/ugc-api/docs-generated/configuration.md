---
service: "ugc-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, yaml-config-files, vault, gconfig]
---

# Configuration

## Overview

The UGC API is configured through a combination of JTier YAML runtime configuration files (selected by the `JTIER_RUN_CONFIG` environment variable), environment variables set in Kubernetes deployment manifests, and secrets injected from Groupon's internal secret-service-v2 (vault-backed). Per-environment YAML files are stored at `.meta/deployment/cloud/components/app/` and applied during Helm chart deployment. The JTier framework reads these files at startup and exposes them as configuration to the Dropwizard application.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the per-environment JTier YAML config file loaded at startup | yes | None | Kubernetes env (deployment manifest) |
| `MALLOC_ARENA_MAX` | Controls glibc memory arena count to reduce JVM memory fragmentation | no | `4` | Kubernetes env (`common.yml`) |
| `MIN_RAM_PERCENTAGE` | JVM heap minimum as a percentage of container memory limit | no | `70.0` | Kubernetes env (`common.yml`) |
| `MAX_RAM_PERCENTAGE` | JVM heap maximum as a percentage of container memory limit | no | `70.0` | Kubernetes env (`common.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase of a dedicated feature flag system. The `.service.yml` lists `gconfig` as a dependency, which is Groupon's internal feature flag / runtime configuration service. Feature flag values are fetched at runtime and are not documented in this repository.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Base Kubernetes deployment config: image, replicas, ports, memory/CPU, APM settings |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US (GCP us-central1) overrides: replica counts, CPU/memory limits, VIP |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU (AWS eu-west-1) overrides: replica counts, regions |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production EU (GCP europe-west1) overrides: replica counts, CPU/memory limits, VIP |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US (GCP us-central1) overrides: low replica counts, reduced CPU/memory |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EU (GCP europe-west1) overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging US-West-2 (AWS) overrides |
| `development.yml` | YAML | Local development JTier config (Dropwizard application config for local runs) |
| `.meta/.raptor.yml` | YAML | Raptor component definition: `app` of archetype `jtier` |
| `.meta/deployment/cloud/scripts/deploy.sh` | Shell | Helm 3 templating + krane deployment pipeline script |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/cloud/{env}.yml` | Per-environment secrets injected at deploy time (DB credentials, Redis auth, S3 credentials, JMS credentials) | secret-service-v2 (Vault-backed) |

> Secret values are NEVER documented. Only names and rotation policies are listed here. The `secret-service-v2` dependency in `.service.yml` indicates all secrets are managed through Groupon's centralized secret service.

## Per-Environment Overrides

| Environment | Key Differences |
|-------------|----------------|
| Local development | Configured via `development.yml`; uses local or mock databases; launched with `java -jar target/ugc-api-*.jar server development.yml` |
| Staging US (GCP us-central1) | `JTIER_RUN_CONFIG=.../staging-us-central1.yml`; 1–2 replicas; 6 Gi memory; reduced CPU; VIP: `ugc-api-jtier.us-central1.conveyor.stable.gcp.groupondev.com` |
| Staging EU (GCP europe-west1) | `JTIER_RUN_CONFIG=.../staging-europe-west1.yml`; 1–2 replicas; similar resource profile |
| Production US (GCP us-central1) | `JTIER_RUN_CONFIG=.../production-us-central1.yml`; 3–50 replicas; 9 Gi request / 10 Gi limit; 3000m CPU; VIP: `ugc-api-jtier.us-central1.conveyor.prod.gcp.groupondev.com` |
| Production EU (GCP europe-west1) | `JTIER_RUN_CONFIG=.../production-europe-west1.yml`; GCP europe-west1 cluster |
| Production EU (AWS eu-west-1) | `JTIER_RUN_CONFIG=.../production-eu-west-1.yml`; AWS Kubernetes cluster at dub1 datacenter |
