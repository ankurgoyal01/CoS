---
service: "seo-deal-redirect"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, gcp-secret-manager, airflow-variables, dag-properties-json]
---

# Configuration

## Overview

SEO Deal Redirect is configured through a layered system: a `config/default.json` file provides shared defaults (country-to-domain mappings, path constants), while `config/production.json` and `config/staging.json` supply environment-specific overrides (API hosts, Hive database names, GCS paths). Per-DAG runtime configuration is defined in `orchestrator/config/{env}/dag_properties.json`, which specifies the Dataproc cluster topology, Spark job properties, and job-specific script arguments. Secrets (TLS keystore) are retrieved from GCP Secret Manager at cluster initialization time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env` | Airflow Variable — selects which environment config to load (`staging`, `production`) | yes | — | Airflow Variables (`Variable.get("env")`) |
| `COMPOSER_DAGS_BUCKET` | GCS bucket where DAG files are deployed | yes | — | DeployBot environment vars |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace used by DeployBot for the deployment job | yes | — | DeployBot environment vars |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `skip_deal_table_population_jobs` | Skips Hive deal-table population steps (useful for re-runs when source data is unchanged) | `"false"` | per-run (dag_properties.json) |
| `skip_deal_table_population_jobs_partition_date` | When skip flag is enabled, use data from this partition date instead of re-running Hive steps | `"2023-10-10"` | per-run (dag_properties.json) |
| `skip_pre_2019_tasks` | Disables pre-2019 deal performance and mapping tasks | `"true"` | per-run (dag_properties.json) |
| `only_run_non_active_merchant_deals_job` | When `"true"`, skips all main redirect pipeline steps and only runs the non-active merchant job | `"false"` | per-run (dag_properties.json) |
| `dry_run` | Prevents non-active merchant deals job from making live API calls | `"false"` | per-run (script_args in dag_properties.json) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/default.json` | JSON | Shared constants: `country_to_url` domain mapping, `deal_suffix`, `final_write_db`, `final_write_path`, `cat_names`, `goods_db`, `goods_emea_db` |
| `config/production.json` | JSON | Production overrides: `seo_db`, `api_host`, `seo_db_path`, `base_path`, `pds_bl_location`, `deal_excl_location`, `manual_redirects_location`, `log_file` |
| `config/staging.json` | JSON | Staging overrides: `seo_db` (uses `seo_dev_db`), `api_host` (staging VIP), `log_file` |
| `orchestrator/config/prod/dag_properties.json` | JSON | Full production DAG config: GCP project, cluster topology, Spark job properties, script args for all three PySpark jobs |
| `orchestrator/config/stable/dag_properties.json` | JSON | Stable/staging DAG config |
| `orchestrator/config/dev/dag_properties.json` | JSON | Dev DAG config (deprecated; not actively supported) |

### Key config values (from `config/default.json`)

| Key | Value | Purpose |
|-----|-------|---------|
| `country_to_url` | `{"us": "groupon.com", "ca": "groupon.com", "uk": "groupon.co.uk", ...}` | Maps country code to Groupon domain for URL construction |
| `deal_suffix` | `"/deals/"` | Path prefix for deal permalink URLs |
| `final_write_db` | `"final_redirect_mapping"` | Hive database name for pipeline output |
| `cat_names` | `"('l1 - local')"` | Category filter applied during deal extraction |
| `goods_db` | `"svc_goods_bundling_db"` | Hive DB for NA goods deal data |
| `goods_emea_db` | `"grp_gdoop_gods_db"` | Hive DB for EMEA goods deal data |

### Key config values (from production `dag_properties.json`)

| Key | Value | Purpose |
|-----|-------|---------|
| `project_id` | `prj-grp-c-common-prod-ff2b` | GCP project for Dataproc jobs |
| `schedule_interval` | `0 5 15 * *` | Airflow cron — 5:00 AM UTC on the 15th of each month |
| `seo_db` | `grp_gdoop_seo_db` | Production SEO Hive database |
| `api_host` | `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` | Base URL for SEO Deal API |
| `notification_email` | `computational-seo@groupon.com` | Airflow completion email recipient |
| `redirect_api_calls_per_period` | `"1250"` | API rate limit (calls per period) |
| `redirect_api_period_seconds` | `"60"` | API rate limit period in seconds |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls--seo-seo-deal-redirect` | TLS keystore secret used to authenticate PUT requests to SEO Deal API | GCP Secret Manager |
| `tls--seo-seo-gcp-pipelines` | General GCP pipeline TLS credentials | GCP Secret Manager |
| `seo-deal-redirect-keystore.jks` | PKCS12/JKS keystore file name mounted at cluster init | GCP Secret Manager (via `load-certificates.sh`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Config Key | Staging | Production |
|------------|---------|------------|
| `seo_db` | `seo_dev_db` | `grp_gdoop_seo_db` |
| `api_host` | `seo-deal-observer-staging-vip.snc1` | `https://edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| `log_file` | `seo_redirect_staging.log` | `seo_redirect_prod.log` |
| `manual_redirects_location` | `test_data/manual_redirects_location/` | `prod_data/manual_redirects_location/` |
| `COMPOSER_DAGS_BUCKET` | `us-central1-grp-shared-comp-03dba3de-bucket` | `us-central1-grp-shared-comp-9260309b-bucket` |
| `KUBERNETES_NAMESPACE` | `seo-deal-redirect-staging` | `seo-deal-redirect-production` |
| Dataproc cluster | `gcp-stable-us-central1` | `gcp-production-us-central1` |
