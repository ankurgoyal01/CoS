---
service: "coupons_bi_airflow"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [gcp-secret-manager, airflow-variables, airflow-connections]
---

# Configuration

## Overview

coupons_bi_airflow is configured through three mechanisms: GCP Secret Manager for all sensitive credentials (API keys, OAuth tokens, service account keys), Airflow Variables for non-sensitive pipeline parameters (project IDs, bucket names, dataset identifiers), and Airflow Connections for data store connectivity (Teradata, BigQuery). Configuration is managed at the Cloud Composer environment level; there are no local config files bundled with the DAGs.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GCP_PROJECT_ID` | GCP project identifier for BigQuery and GCS operations | yes | none | airflow-variables |
| `GCS_LANDING_BUCKET` | GCS bucket name used as the raw data landing zone | yes | none | airflow-variables |
| `BIGQUERY_DATASET` | Target BigQuery dataset for pipeline output | yes | none | airflow-variables |
| `TERADATA_CONN_ID` | Airflow connection ID for Teradata warehouse | yes | none | airflow-connections |
| `BIGQUERY_CONN_ID` | Airflow connection ID for BigQuery | yes | none | airflow-connections |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found — coupons_bi_airflow does not use a feature flag system.

## Config Files

> No evidence found — configuration is managed via Cloud Composer environment variables and Airflow Variables/Connections, not local config files.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ga4-api-credentials` | Service account key for GA4 Data API access | GCP Secret Manager |
| `google-ads-oauth-credentials` | OAuth2 credentials for Google Ads API | GCP Secret Manager |
| `bing-ads-oauth-credentials` | OAuth2 credentials for Bing Ads API | GCP Secret Manager |
| `accuranker-api-key` | API key for AccuRanker organic ranking data | GCP Secret Manager |
| `affjet-api-key` | API key for AffJet affiliate network API | GCP Secret Manager |
| `cj-api-key` | API key for Commission Junction affiliate API | GCP Secret Manager |
| `search-console-credentials` | Service account key for Google Search Console API | GCP Secret Manager |
| `ad-manager-credentials` | Service account key for Google Ad Manager API | GCP Secret Manager |
| `crux-api-key` | API key for Chrome UX Report API | GCP Secret Manager |
| `google-sheets-credentials` | Service account key for Google Sheets API access | GCP Secret Manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Cloud Composer environments are provisioned per environment tier (e.g., staging, production). GCS bucket names, BigQuery dataset identifiers, and GCP project IDs differ between environments and are configured as Airflow Variables scoped to each Cloud Composer instance. Secrets in GCP Secret Manager are namespaced per environment and resolved at DAG runtime.
