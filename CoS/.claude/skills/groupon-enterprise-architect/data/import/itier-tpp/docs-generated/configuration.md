---
service: "itier-tpp"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets, dotenv]
---

# Configuration

## Overview

I-Tier TPP uses a layered configuration strategy. Environment-agnostic defaults are defined in CSON config files under `config/` (loaded by `keldor`). Environment-specific values are selected at runtime using the `KELDOR_CONFIG_SOURCE` environment variable. Sensitive credentials are injected as environment variables from Kubernetes secrets at pod startup. For local development, a `.env` file (gitignored) supplies values via `dotenv`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the active config environment (`{staging}`, `{production}`) | yes | `{staging}` in staging deploy configs | helm values |
| `NODE_OPTIONS` | Node.js process flags; sets `--max-old-space-size=1024` | yes | `--max-old-space-size=1024` | helm values |
| `PORT` | HTTP port the server listens on | yes | `8000` | helm values |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O concurrency | yes | `75` | helm values |
| `MINDBODY_USERNAME` | Mindbody API authentication username | yes | none | k8s-secret (`mindbody-auth`) |
| `MINDBODY_PASSWORD` | Mindbody API authentication password | yes | none | k8s-secret (`mindbody-auth`) |
| `NODE_ENV` | Node environment mode (`development`, `test`, `production`) | no | `development` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `expy.enabled` | Enables the Expy A/B experimentation framework | `true` (from `config/base.cson`) | global |
| `expy.clientSideExperiments` | List of active client-side experiments | `[]` (empty) | per-page |

Feature flags beyond experimentation can be toggled via gconfig at `https://gconfig.groupondev.com/apps/itier-tpp#feature_flags`. The `itier-feature-flags ^1.0.1` library evaluates flags at request time.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration: service client URLs, Doorman auth URL, asset hosts, localization, tracing, expy settings |
| `.deploy-configs/values.yaml` | YAML | Napistrano-generated Helm values common to all environments |
| `.deploy-configs/staging-us-central1.yml` | YAML | Kubernetes staging (GCP us-central1) deploy config: replicas, DNS names, env vars, resource limits |
| `.deploy-configs/staging-us-west-2.yml` | YAML | Kubernetes staging (AWS us-west-2) deploy config |
| `.deploy-configs/production-us-central1.yml` | YAML | Kubernetes production (GCP us-central1) deploy config: replicas, DNS names, resource limits |
| `.deploy-configs/production-eu-west-1.yml` | YAML | Kubernetes production (AWS eu-west-1) deploy config |
| `.env` | dotenv | Local development environment variable overrides (gitignored; copied from `.env.example`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `mindbody-auth` | Mindbody API username and password | k8s-secret |
| Booker API key | Booker platform API key for authentication (`serviceClient.booker.apiKey` in CSON) | config-file (base config; rotate via secrets repo) |
| Booker client credentials | Booker OAuth client ID and secret (`serviceClient.booker.clientId`, `clientSecret`) | config-file (rotate via secrets repo) |
| Groupon V2 / API proxy client ID | Client identifier for Groupon V2 API calls (`serviceClient.grouponV2.clientId`) | config-file |
| Deal Catalog client ID | Client identifier for Deal Catalog API calls (`serviceClient.dealCatalogService.clientId`) | config-file |

> Secret values are NEVER documented. Only names and rotation policies.

Secrets are managed in the `itier-tpp-secrets` private repository. Kubernetes secrets are created using `kubectl` in each cluster namespace and referenced in `.deploy-configs/*.yml` via `secretEnvVars`.

## Per-Environment Overrides

- **Staging**: `KELDOR_CONFIG_SOURCE={staging}`, 1–3 replicas, DNS `itier-tpp.staging.service` and `tpp-staging.groupondev.com`, memory request 400 Mi / limit 4096 Mi
- **Production**: `KELDOR_CONFIG_SOURCE={production}`, fixed 3 replicas, DNS `itier-tpp.production.service` and `tpp.groupondev.com`, memory request 400 Mi / limit 4096 Mi, CPU request 500 m
- **Local development**: `.env` file with values from `itier-tpp-secrets`; runs against staging by default unless `KELDOR_CONFIG_SOURCE={production}` is set explicitly
