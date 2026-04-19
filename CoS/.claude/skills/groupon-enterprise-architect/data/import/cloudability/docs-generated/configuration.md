---
service: "cloudability"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["secrets-submodule", "kubectl-context", "env-vars"]
---

# Configuration

## Overview

Cloudability is configured through a combination of: a secrets git submodule (`CloudSRE/cloudability-secrets`) that stores per-cluster Kubernetes manifests and the provisioning API key, the active `kubectl` context (which determines the target cluster), and deploybot YAML (`deploy_bot.yml`) for deployment target mapping. There are no runtime environment variable injection mechanisms — configuration is baked into the Kubernetes manifests stored in `secrets/`.

## Environment Variables

> No runtime environment variables are injected at deployment time. All configuration is embedded in the Kubernetes manifest files stored in the `secrets/` submodule.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `secrets/provisioning-api-key` | Plain text | Cloudability per-user or service API key used by provisioning CLI scripts |
| `secrets/conveyor-<context>.yml` | YAML (Kubernetes manifest) | Per-cluster patched agent deployment manifest; applied via kubectl |
| `.deploy_bot.yml` | YAML | Deploybot v2 configuration mapping clusters to deployment targets, namespaces, and regions |
| `.gitmodules` | INI | Declares `secrets/` as a git submodule pointing to `git@github.groupondev.com:CloudSRE/cloudability-secrets.git` |
| `get_agent_config.sh` | Bash | Provisioning automation: registers cluster, fetches manifest, applies Groupon patches |
| `get_raw_config.sh` | Bash | Fetches raw (unpatched) manifest from Cloudability API for inspection |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `secrets/provisioning-api-key` | Cloudability API key used to authenticate against `https://api.cloudability.com/v3/` | Git submodule (`cloudability-secrets`) |
| `secrets/conveyor-<context>.yml` | Per-cluster Kubernetes manifest containing cluster-scoped Cloudability tokens and deployment config | Git submodule (`cloudability-secrets`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Deploybot targets map cluster contexts to namespaces as follows:

| Target | Cluster | Kubernetes Namespace | Region |
|--------|---------|---------------------|--------|
| `staging-us-west-1` | `stable-us-west-1` | `cloudability-staging` | us/canada |
| `staging-us-west-2` | `stable-us-west-2` | `cloudability-staging` | emea |
| `staging-us-central1` | `gcp-stable-us-central1` | `cloudability-staging` | us/canada |
| `staging-europe-west1` | `gcp-stable-europe-west1` | `cloudability-staging` | emea |
| `production-us-west-1` | `production-us-west-1` | `cloudability-production` | us/canada |
| `production-us-west-2` | `production-us-west-2` | `cloudability-production` | us/canada |
| `production-eu-west-1` | `production-eu-west-1` | `cloudability-production` | emea |
| `production-us-central1` | `production-us-central1` | `cloudability-production` | us/canada |
| `production-europe-west1` | `production-europe-west1` | `cloudability-production` | emea |

The manifest patcher (`get_agent_config.sh`) derives the correct namespace suffix (`production`, `staging`, or `dev`) from the current kubectl context pattern:
- `conveyor-*production-*` → namespace suffix `production`
- `conveyor-*stable-*` → namespace suffix `staging`
- `conveyor-*rapid-*` → namespace suffix `dev`
