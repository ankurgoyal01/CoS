---
service: "mvrt"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, helm-values]
---

# Configuration

## Overview

MVRT uses the ITier `keldor-config` system with CSON (CoffeeScript Object Notation) configuration files layered by node environment (`config/node-env/`) and stage (`config/stage/`). The `KELDOR_CONFIG_SOURCE` environment variable selects the stage-specific overlay at runtime. Feature flags, service client settings, and country-specific operational parameters are all defined in these CSON files. Secrets (AWS S3 credentials, etc.) are loaded at runtime from a separate secrets file whose path is specified in the stage config.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the stage config overlay (`{production}` or `{staging}`) | yes | None | helm values (`.deploy-configs/*.yml`) |
| `NODE_OPTIONS` | Node.js heap size limit | yes | `--max-old-space-size=1024` | helm values |
| `PORT` | HTTP listen port | yes | `8000` | helm values |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O | yes | `75` | helm values |
| `NODE_ENV` | Node environment selector for `config/node-env/` layer | yes | `production` (in prod) | Container entrypoint |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `feature_flags.MVRT.deal_catalog.v1_client_id` | Deal catalog v1 API client ID | `1088c9f67300fc53-mvrt` | global |
| `feature_flags.MVRT.deal_catalog.v2_client_id` | Deal catalog v2 API client ID | `1088c9f67300fc53-mvrt` | global |
| `feature_flags.MVRT.vis_inventory.v1_client_id` | Voucher Inventory Service v1 client ID | `1088c9f67300fc53-mvrt` | global |
| `feature_flags.MVRT.vis_inventory.v2_client_id` | Voucher Inventory Service v2 client ID | `1088c9f67300fc53-mvrt` | global |
| `feature_flags.MVRT.vis_inventory.limit` | Max voucher units returned per search query | `1000000` | global |
| `feature_flags.active_countries` | List of country codes for which the tool is enabled | FR, DE, IT, UK, ES, IE, BE, AE, NL, PL, AU, NZ, JP, QC (production) | per-region |
| `feature_flags.MVRT.chunk_size.search.*` | Per-code-type search chunk sizes | customer_code:25, security_code:25, unit_id:25, merchant_id:1, sf_id:1, product_sf_id:1 | global |
| `feature_flags.MVRT.chunk_size.searchLimit` | Maximum codes for an offline search job | `300000` | global |
| `feature_flags.MVRT.chunk_size.redemption` | Number of vouchers redeemed per batch | `15` | global |
| `feature_flags.MVRT.normal_redemption_enabled` | Countries where normal redemption is enabled | All active countries | per-region |
| `feature_flags.MVRT.forced_redemption_enabled` | Countries where forced/managerial redemption is enabled | All active countries | per-region |
| `feature_flags.MVRT.post_expiration_days` | Days post-expiry a voucher may still be redeemed, per country | ae:30, au:60, be:30, de:30, es:30, fr:30, ie:30, it:30, jp:30, nl:30, nz:60, pl:30, qc:30, uk:30 | per-region |
| `feature_flags.MVRT.max_grid_codes_count` | Maximum code grid count per search page | `100` | global |
| `feature_flags.MVRT.ldap.group_env` | LDAP/Okta group environment filter (`production` or `staging`) | `production` (prod) | per-environment |
| `feature_flags.MVRT.baseUrl` | Public hostname used for S3 download link construction | `mvrt.groupondev.com` (prod) | per-environment |
| `feature_flags.MVRT.sourceType.normal` | Redemption source type string for normal redemptions | `portal` | global |
| `feature_flags.MVRT.sourceType.managerial` | Redemption source type string for forced redemptions | `finance` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration (cache backend, logging, steno transport, API proxy client ID) |
| `config/node-env/production.cson` | CSON | Production node-env override (disables tracky-to-process logging) |
| `config/node-env/development.cson` | CSON | Development node-env override |
| `config/node-env/test.cson` | CSON | Test node-env override |
| `config/stage/production.cson` | CSON | Production stage overlay: all feature flags, service client endpoints, server child processes, rocketman client ID, secrets file path |
| `config/stage/staging.cson` | CSON | Staging stage overlay: same structure as production with staging-specific values |
| `config/stage/uat.cson` | CSON | UAT stage overlay |
| `.meta/secrets/production.cson` | CSON | Runtime secrets (S3 credentials, etc.) — path: `feature_flags.MVRT.secretsFile` |
| `.meta/secrets/staging.cson` | CSON | Staging runtime secrets |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `s3_bucket.access_key_id` | AWS S3 bucket access key | secrets file (k8s secret mounted at `.meta/secrets/<env>.cson`) |
| `s3_bucket.secret_key` | AWS S3 bucket secret access key | secrets file |
| `s3_bucket.bucket_name` | AWS S3 bucket name for offline reports | secrets file |
| `s3_bucket.region` | AWS S3 bucket region | secrets file |
| `serviceClient.grouponV2.clientId` | Groupon v2 API client ID | `config/stage/*.cson` (non-sensitive client ID) |
| `serviceClient.rocketman.clientId` | Rocketman email client ID | `config/stage/*.cson` |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production**: `KELDOR_CONFIG_SOURCE={production}` loads `config/stage/production.cson`; uses `searchDomain: 'dub1'`, `apiProxyBaseUrl: '{production}'`, `tracing.sampleRate: 0`, `server.child_processes: 2`
- **Staging**: `KELDOR_CONFIG_SOURCE={staging}` loads `config/stage/staging.cson`; uses `searchDomain: 'snc1'`, shorter timeouts (`connectTimeout: 5000`, `timeout: 10000`), additional staging country `BR` in active_countries
- **Development**: `config/node-env/development.cson` + `config/base.cson` with `steno.transport: 'file'` for local file logging
- **Test**: `config/node-env/test.cson` applied during `npm test`
- CDN asset hosts differ: production uses `www<1,2>.grouponcdn.com`; staging uses `staging<1,2>.grouponcdn.com`
