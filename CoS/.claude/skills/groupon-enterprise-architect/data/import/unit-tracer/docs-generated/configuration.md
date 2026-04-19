---
service: "unit-tracer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files"]
---

# Configuration

## Overview

Unit Tracer is configured using the JTier configuration model. The active configuration file is selected at runtime via the `JTIER_RUN_CONFIG` environment variable, which points to a YAML file in `/var/groupon/jtier/config/cloud/`. Each deployment environment has its own YAML file. The configuration file defines Retrofit client base URLs and connection settings for all five downstream service clients. Secrets and credentials are managed by the JTier platform's `secret_path` mechanism (Vault integration via `.meta/.raptor.yml`).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML configuration file for the current environment | Yes | None | env (set by deployment manifests in `.meta/deployment/cloud/components/app/`) |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flags are configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | JTier runtime config for production GCP us-central1 |
| `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` | YAML | JTier runtime config for production AWS eu-west-1 |
| `/var/groupon/jtier/config/cloud/production-europe-west1.yml` | YAML | JTier runtime config for production GCP europe-west1 |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | JTier runtime config for staging GCP us-central1 |
| `/var/groupon/jtier/config/cloud/staging-europe-west1.yml` | YAML | JTier runtime config for staging GCP europe-west1 |
| `/var/groupon/jtier/config/cloud/dev-us-central1.yml` | YAML | JTier runtime config for dev GCP us-central1 |
| `.meta/.raptor.yml` | YAML | Raptor component metadata; `secret_path` field controls Vault secret injection |
| `doc/swagger/config.yml` | YAML | Swagger documentation generation config |
| `doc/swagger/swagger.yaml` | YAML | Generated OpenAPI 2.0 specification |
| `exclude-pmd.properties` | Properties | PMD static analysis exclusions |
| `pmd-rulesets.xml` | XML | PMD rule set configuration |
| `findbugs-exclude.xml` | XML | FindBugs exclusion filter |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `secret_path` (defined in `.meta/.raptor.yml`) | Vault path for service secrets (e.g., downstream client credentials, TLS certs) | Vault (via JTier Raptor integration) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Each deployment environment has a dedicated YAML config file injected via `JTIER_RUN_CONFIG`. The per-environment files configure:

- **Retrofit client base URLs**: Each of the five downstream clients (`voucherInventoryServiceClient`, `thirdPartyInventoryServiceClient`, `accountingServiceClient`, `messageToLedgerClient`, `grouponLiveInventoryServiceClient`) points to environment-specific service VIPs/URLs.
- **JTier framework settings**: Connection pool sizes, timeouts, thread counts — governed by JTier defaults and environment-specific overrides.

| Environment | Config File Key | Cloud | Region |
|-------------|----------------|-------|--------|
| dev | `dev-us-central1.yml` | GCP | us-central1 |
| staging (US) | `staging-us-central1.yml` | GCP | us-central1 |
| staging (EU) | `staging-europe-west1.yml` | GCP | europe-west1 |
| production (US) | `production-us-central1.yml` | GCP | us-central1 |
| production (EU-AWS) | `production-eu-west-1.yml` | AWS | eu-west-1 |
| production (EU-GCP) | `production-europe-west1.yml` | GCP | europe-west1 |
