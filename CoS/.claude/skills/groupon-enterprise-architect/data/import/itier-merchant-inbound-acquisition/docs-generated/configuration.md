---
service: "itier-merchant-inbound-acquisition"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, cson-config-files, helm-values, keldor-config]
---

# Configuration

## Overview

Configuration is layered using the `keldor-config` framework, which merges CSON files in priority order: `config/base.cson` provides defaults, `config/node-env/<NODE_ENV>.cson` overrides by Node environment, and `config/stage/<STAGE>.cson` overrides by deployment stage (staging, production, uat). The active config source is selected at runtime via the `KELDOR_CONFIG_SOURCE` environment variable. Additional runtime settings (memory limits, replica counts, feature flag switcher) are injected via Helm values files (`.deploy-configs/`).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the keldor config base URL (`{staging}` or `{production}`) | Yes | `{staging}` | Helm / deploy config |
| `NODE_OPTIONS` | Node.js runtime options (e.g. heap size) | No | `--max-old-space-size=1024` | Helm values |
| `PORT` | HTTP port the server listens on | Yes | `8000` | Helm values |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | No | `75` | Helm values |
| `keldor_feature_flags__feature_flag_switcher` | Enables runtime feature flag overrides via Keldor | No | `"true"` | Helm values / napistrano |

> IMPORTANT: Secret values (Salesforce credentials, API keys) are stored in CSON config files loaded at startup via keldor-config. They are never documented here.

## Feature Flags

Feature flags are evaluated per-request using `itier-feature-flags` with country and region dimensions from the incoming locale context.

| Flag | Purpose | Enabled for |
|------|---------|-------------|
| `enableCityField` | Shows city input field in signup form | US, GB, AU, IE, AE, FR, DE, IT, ES, NL, BE, PL, CA |
| `enableCountryField` | Shows country selector | US, CA |
| `enablePostalZipCodeField` | Shows postal/zip code input | US, GB, AU, IE, FR, DE, IT, ES, NL, BE, PL, CA |
| `enableStateField` | Shows state/province selector | US, AU, CA |
| `enableProvinceCodeField` | Shows province code field (IT-specific) | IT |
| `enableStreetAddressField` | Shows street address input | US, GB, AU, AE, IE, DE, FR, ES, IT, NL, BE, PL, CA |
| `enableMerchantIncentives` | Shows merchant incentive UI | US |
| `enableAccountCreation` | Routes lead to Metro account-creation flow | US, GB, AU, FR, IT, PL, AE, DE, ES, BE, NL, IE (prod/staging) |
| `enableLeadCreation` | Routes lead to Salesforce (inverted — countries NOT in account-creation list) | All countries not in `enableAccountCreation` |
| `enableResidentialAddress` | Collects residential address flag | `false` (disabled) |
| `enableCustomRedemption` | Enables custom redemption code field | `XX` only (disabled in practice) |
| `enableHeaderParam` | Activates Referer-header-based country detection for account-creation routing | `true` (prod/staging) |
| `isRegionEMEA` | Sets EMEA promotion opt-in logic for contacts | EMEA region |
| `enableMIAFormForGlive` | Enables MIA form for Glive flow | US |
| `stagingGATag` | Overrides GA code to staging tag | Staging only |
| `stagingGTMTag` | Overrides GTM container to staging container | Staging only |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base config: CDN hosts, expy pages, feature flag defaults, Birdcage / Draft Service / Salesforce client settings |
| `config/node-env/development.cson` | CSON | Development overrides |
| `config/node-env/production.cson` | CSON | Production Node-env overrides |
| `config/node-env/test.cson` | CSON | Test overrides |
| `config/stage/production.cson` | CSON | Production stage: CDN hosts (`www<1,2>.grouponcdn.com`), production Salesforce URL, production feature flags |
| `config/stage/staging.cson` | CSON | Staging stage: feature flags plus staging GA/GTM tag overrides |
| `config/stage/uat.cson` | CSON | UAT stage overrides |
| `.deploy-configs/production-us-central1.yml` | YAML | GCP us-central1 production Helm values |
| `.deploy-configs/production-eu-west-1.yml` | YAML | AWS eu-west-1 production Helm values |
| `.deploy-configs/staging-us-central1.yml` | YAML | GCP us-central1 staging Helm values |
| `.deploy-configs/staging-europe-west1.yml` | YAML | GCP europe-west1 staging Helm values |
| `.deploy-configs/values.yaml` | YAML | Shared Helm chart defaults (filebeat resources, log config) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `serviceClient.salesforce.password` | Salesforce login password for CRM lead creation | keldor-config / CSON (staging), keldor-config / CSON (production) |
| `serviceClient.salesforce.username` | Salesforce login username | keldor-config / CSON |
| `serviceClient.draftService.draftServiceApiKey` | API key for Metro draft service | keldor-config / CSON (`config/base.cson`) |
| `serviceClient.globalDefaults.apiKey` | Global Metro API key | keldor-config / CSON (`config/base.cson`) |

> Secret values are NEVER documented. Only names and purposes are listed above.

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| CDN hosts | `staging<1,2>.grouponcdn.com` | `www<1,2>.grouponcdn.com` |
| `KELDOR_CONFIG_SOURCE` | `{staging}` | `{production}` |
| Salesforce base URL | `https://test.salesforce.com` | `https://groupon-dev.my.salesforce.com` |
| Memory request / limit (main) | 1536Mi / 3072Mi | 2048Mi / 4096Mi |
| Min replicas (GCP) | 1 | 3 |
| GA/GTM tags | Staging tags (`stagingGATag: true`, `stagingGTMTag: true`) | Country-specific production tags |
