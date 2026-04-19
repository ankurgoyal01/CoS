---
service: "gcp-aiaas-cloud-functions"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, gcp-secret-manager, service-account-json]
---

# Configuration

## Overview

All functions are configured primarily through environment variables. Cloud Functions may additionally use GCP Secret Manager (via `google-cloud-secret-manager`) to retrieve credentials at runtime. The PDS Priority function reads a `service_account.json` file on disk as a fallback. The InferPDS Cloud Run services use a `python-dotenv` `.env` file for local development. No Consul, Vault, or Helm-based configuration is used.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OPENAI_API_KEY` | OpenAI API authentication for chat completions and embeddings | yes | None | env / GCP Secret Manager |
| `LANGSMITH_API_KEY` | LangSmith tracing platform authentication | no | None | env |
| `LANGSMITH_PROJECT` | LangSmith project name (`InferPDS-Production`, `InferPDS-Dev`, `InferPDS-Stable`) | no | `InferPDS-Production` | env |
| `LANGSMITH_TRACING` | Enable LangSmith distributed tracing (`"true"`) | no | `"true"` | env |
| `SF_CLIENT_ID` | Salesforce connected app client ID | yes (if using OAuth) | dev default | env |
| `SF_CLIENT_SECRET` | Salesforce connected app client secret | yes (if using OAuth) | dev default | env |
| `SF_USERNAME` | Salesforce authentication username | yes | `merchant-advisor@groupon.com` | env |
| `SF_PASSWORD` | Salesforce authentication password + security token | yes | dev default | env |
| `SF_INSTANCE_URL` | Salesforce instance base URL | no | `https://groupon-dev.my.salesforce.com` | env |
| `APIFY_TOKEN` | Apify API token for actor invocations | no (required for Instagram enrichment) | None | env |
| `APIFY_API_TOKEN` | Apify API token (alternate name) | no | None | env |
| `APIFY_API_KEY` | Apify API token (alternate name) | no | None | env |
| `POSTGRES_HOST` | PostgreSQL host for InferPDS Cloud Run API | yes | `aidg-service-ro-na-staging-db.gds.stable.gcp.groupondev.com` | env |
| `POSTGRES_PORT` | PostgreSQL port for InferPDS Cloud Run API | no | `5432` | env |
| `POSTGRES_DATABASE` | PostgreSQL database name for InferPDS Cloud Run API | yes | `aidg_stg` | env |
| `POSTGRES_USER` | PostgreSQL user for InferPDS Cloud Run API | yes | `aidg_stg_dba` | env |
| `POSTGRES_PASSWORD` | PostgreSQL password for InferPDS Cloud Run API | yes | dev default | env |
| `DAAS_HOST` | PostgreSQL host for AIDG function | yes | `aidg-service-ro-na-staging-db.gds.stable.gcp.groupondev.com` | env |
| `DAAS_APP_DATABASE` | PostgreSQL database name for AIDG function | yes | `aidg_stg` | env |
| `DAAS_DBA_USER` | PostgreSQL user for AIDG function | yes | `aidg_stg_dba` | env |
| `DAAS_DBA_PASSWORD` | PostgreSQL password for AIDG function | yes | dev default | env |
| `DAAS_PORT` | PostgreSQL port for AIDG function | no | `5432` | env |
| `PG_SCHEMA` | PostgreSQL schema name for AIDG function | no | `aidg` | env |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | GCP service account JSON (base64 or raw JSON string) for BigQuery and Vertex AI authentication | no (falls back to ADC) | None | env |
| `PORT` | HTTP server port for Cloud Run services | no | `8080` | env (set by Cloud Run) |

> IMPORTANT: Default values shown are for staging/dev environments only. Never use dev defaults in production. Secret values are not documented here — only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `test` (query param) | Switches Google Scraper from Vertex AI to LightGBM model inference | `false` | per-request |
| `forceNewMatching` (query param) | Forces InferPDS V3 to re-run matching even if cached results exist | `false` | per-request |
| `forceNewScraping` (query param) | Forces InferPDS V3 to re-scrape the merchant website | `false` | per-request |
| `fastMode` (query param) | Enables a faster but less thorough extraction mode in InferPDS V3 | `false` | per-request |
| `scrapeInstagram` (query param) | Enables Apify Instagram enrichment in Social Link Scraper | `false` | per-request |
| `useAdvancedBusinessProfiling` (query param) | Enables advanced business profiling in InferPDS V3 | `true` | per-request |
| `skipGptValidation` (query param) | Skips GPT-based service validation step in InferPDS V3 | `false` | per-request |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `pds_priority/src/service_account.json` | JSON | GCP service account credentials for BigQuery access in PDS Priority function |
| `inferpds_cloud_run_api/filtered_merchant_services.csv` | CSV | Reference taxonomy data for InferPDS service matching |
| `inferpds_cloud_run_api/merchant_services_with_headers_and_categories.csv` | CSV | Expanded merchant service taxonomy with category headers |
| `mad_inferpds_cloud_run_api/pds.csv` | CSV | PDS taxonomy reference data for MAD InferPDS |
| `mad_inferpds_cloud_run_api/pds_taxonomy.csv` | CSV | Full PDS taxonomy for MAD InferPDS matching |
| `google_scraper/src/city_tier.csv` | CSV | City-tier mapping used by merchant potential scoring |
| `google_scraper/src/pds.csv` | CSV | PDS reference data for Google Scraper feature extraction |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OPENAI_API_KEY` | OpenAI API authentication | env / GCP Secret Manager |
| `LANGSMITH_API_KEY` | LangSmith tracing authentication | env / GCP Secret Manager |
| `SF_PASSWORD` | Salesforce credential | env / GCP Secret Manager |
| `SF_CLIENT_SECRET` | Salesforce OAuth client secret | env / GCP Secret Manager |
| `POSTGRES_PASSWORD` / `DAAS_DBA_PASSWORD` | PostgreSQL database password | env / GCP Secret Manager |
| `APIFY_TOKEN` | Apify actor execution token | env / GCP Secret Manager |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | GCP service account JSON | env / GCP Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging**: PostgreSQL host defaults to `aidg-service-ro-na-staging-db.gds.stable.gcp.groupondev.com`; Salesforce instance defaults to `groupon-dev.my.salesforce.com`; LangSmith project set to `InferPDS-Dev` or `InferPDS-Stable`; Vertex AI project `prj-grp-aiaas-stable-6113`
- **Production**: PostgreSQL host, Salesforce instance, and Vertex AI project overridden via environment variables; LangSmith project set to `InferPDS-Production`; BigQuery client project set to `prj-grp-aiaas-prod-0052`
- **Local development**: `python-dotenv` `.env` file used; application default credentials (ADC) for GCP; hardcoded dev Salesforce credentials used as fallback
