---
service: "minio"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [helm-values, k8s-secret, env-vars]
---

# Configuration

## Overview

MinIO is configured through a layered Helm values system. Three YAML files are merged at deploy time: `common.yml` (shared across all environments), a secrets file from the `minio-secrets` git submodule (injected at deploy time), and an environment-specific override file (e.g., `production-us-central1.yml`). The MinIO process is launched with a fixed command: `minio server /home/shared`.

## Environment Variables

> No application-level environment variables are explicitly set in the non-secret configuration files. The `envVars` section exists as a commented-out template in each environment file. Secret-based environment variables (e.g., `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`) are injected from the `minio-secrets` submodule.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MINIO_ROOT_USER` | MinIO root/admin username (access key) | yes | None | k8s-secret (minio-secrets submodule) |
| `MINIO_ROOT_PASSWORD` | MinIO root/admin password (secret key) | yes | None | k8s-secret (minio-secrets submodule) |

> IMPORTANT: Actual secret values are never documented. Only variable names and purposes are listed above.

## Feature Flags

> No evidence found in codebase. No application feature flags are configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/minio/common.yml` | YAML | Shared Helm values: image, version, port, health probes, resource requests, startup command |
| `.meta/deployment/cloud/components/minio/production-us-central1.yml` | YAML | Production (GCP us-central1) overrides: scaling (min 1, max 2), cloud provider, region, VPC |
| `.meta/deployment/cloud/components/minio/production-eu-west-1.yml` | YAML | Production (AWS eu-west-1) overrides: scaling (min 2, max 15), cloud provider, region, VPC |
| `.meta/deployment/cloud/components/minio/production-europe-west1.yml` | YAML | Production (GCP europe-west1) overrides: scaling (min 2, max 15), cloud provider, region, VPC |
| `.meta/deployment/cloud/components/minio/staging-us-central1.yml` | YAML | Staging (GCP us-central1) overrides: scaling (min 1, max 2), cloud provider, region, VPC |
| `.meta/deployment/cloud/components/minio/staging-europe-west1.yml` | YAML | Staging (GCP europe-west1) overrides: scaling (min 1, max 2), cloud provider, region, VPC |
| `.meta/deployment/cloud/scripts/deploy.sh` | Bash | Helm template + krane deploy script; merges common + secrets + environment-specific values |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/cloud/{env}.yml` | MinIO credentials and any other secret values per environment | k8s-secret (git submodule: `minio-secrets`) |

> Secret values are NEVER documented. Only names and rotation policies. Secrets are managed in the `git@github.groupondev.com:conveyor-cloud/minio-secrets.git` repository.

## Per-Environment Overrides

| Environment | Cloud | Region | Min Replicas | Max Replicas |
|-------------|-------|--------|-------------|-------------|
| staging-us-central1 | GCP | us-central1 (stable VPC) | 1 | 2 |
| staging-europe-west1 | GCP | europe-west1 (stable VPC) | 1 | 2 |
| production-us-central1 | GCP | us-central1 (prod VPC) | 1 | 2 |
| production-eu-west-1 | AWS | eu-west-1 (prod VPC) | 2 | 15 |
| production-europe-west1 | GCP | europe-west1 (prod VPC) | 2 | 15 |

Production EMEA environments (eu-west-1, europe-west1) are configured with higher maximum replica counts (15) compared to US production (2), indicating higher load or stricter availability requirements in EMEA regions.
