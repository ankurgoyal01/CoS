---
service: "seo-deal-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

SEO Deal API follows the Dropwizard configuration model: a YAML configuration file is loaded at startup and values can be overridden via environment-specific config files. Service URLs for downstream dependencies are resolved via Groupon's internal service discovery (`.staging.service` and `.production.service` DNS). Configuration details for the seo-deal-api service itself are not available in the federated source archive; the following entries are evidenced from consumer configurations and from the seo-deal-redirect pipeline's DAG config.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `api_host` | Base URL of the SEO Deal API for the seo-deal-redirect upload pipeline | yes | None — set per environment in DAG config | DAG JSON config |
| `keystore_path` | Path to the PKCS12 keystore file used for mTLS authentication by the redirect pipeline | yes | None | DAG JSON config |
| `cert_file_path` | Path to the generated PEM certificate file for mTLS | yes | None | DAG JSON config |
| `key_file_path` | Path to the generated PEM private key file for mTLS | yes | None | DAG JSON config |
| `base_path` | GCS base path for reading redirect parquet files in the upload pipeline | yes | None | DAG JSON config |
| `final_write_path` | Relative path within `base_path` for the final redirect mapping parquet | yes | None | DAG JSON config |
| `run_date` | Date partition for the redirect mapping parquet read | yes | None | DAG JSON config |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

No feature flag system configuration was found in the available architecture DSL or cross-referenced source for seo-deal-api.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (inferred) | yaml | Dropwizard application configuration — server threads, database connection pool, downstream service URLs, logging |
| DAG config JSON (seo-deal-redirect) | json | Runtime configuration passed to the api_upload Spark job — API host, keystore paths, GCS paths, run date |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PKCS12 keystore | mTLS client certificate for seo-deal-redirect pipeline authenticating to seo-deal-api | File system / GCS (provisioned by DAG infrastructure) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Based on consumer configuration evidence:

- **Staging**: Service resolves to `http://seo-deal-api.staging.service` (used by `seo-admin-ui`, `ingestion-jtier` staging config)
- **Production**: Service resolves to `http://seo-deal-api.production.service` (used by `seo-admin-ui`, `ingestion-jtier` production config, `seo-deal-redirect` pipeline)
- **Development**: Service resolves to `http://seo-deal-api.staging.service` (used by `seo-admin-ui` development fallback in `DealServerClient`)

Full GCP internal URL pattern: `https://seo-deal-api.{env}.service.us-central1.gcp.groupondev.com`
