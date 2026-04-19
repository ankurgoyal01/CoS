---
service: "airflow_gcp"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, airflow-variables, gcs-secrets-blob]
---

# Configuration

## Overview

The service is configured through a layered approach: environment detection uses the Airflow environment variable `AIRFLOW_VAR_ENV`; connection details and variable values are loaded from JSON config files bundled with the DAGs (`orchestrator/config/{env}/`); runtime secrets (passwords) are loaded from a GCS secrets blob into Airflow Variables by the `secrets_reloader_dag`; and GCP service account credentials are provided via the Airflow connection `sfdc_etl_gcloud_connection`. The `config_helper.py` module is the central entry point for all environment-aware config access.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `AIRFLOW_VAR_ENV` | Determines which config environment to load (`dev`, `stag`/`stable`, `prod`) | yes | none | Airflow environment / Cloud Composer |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Airflow Variables (Loaded from GCS Secrets Blob)

| Variable | Purpose | Required | Source |
|----------|---------|----------|--------|
| `sfdc_etl_sf_conn_password` | Salesforce connection password (resolved in connections.json via `${...}` syntax) | yes | GCS secrets blob via `secrets_reloader_dag` |
| `sfdc_etl_hive_password` | Hive JDBC connection password | yes | GCS secrets blob via `secrets_reloader_dag` |

## Airflow Connections

| Connection ID | Type | Purpose | Environment |
|---------------|------|---------|-------------|
| `sf_prod_conn` | HTTP | Salesforce production connection | production |
| `sf_staging_conn` | HTTP | Salesforce staging connection | staging |
| `sf_dev_conn` | HTTP | Salesforce development connection | development |
| `sfdc_etl_gcloud_connection` | Google Cloud | GCP service account for GCS access in secrets reloader | all |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `orchestrator/config/production/variables.json` | JSON | Production variables: GCS bucket name, GCP project ID, Teradata host/user, Salesforce General Settings IDs, taxonomy/VIS API URLs, certificate config, Hive JDBC config |
| `orchestrator/config/production/connections.json` | JSON | Production Airflow connection definitions (Salesforce host, login, password reference) |
| `orchestrator/config/staging/variables.json` | JSON | Staging variables (GCS bucket: `grpn-us-central1-airflow-sfdc-etl-staging`, GCP project: `prj-grp-sfdc-etl-stable-681e`) |
| `orchestrator/config/staging/connections.json` | JSON | Staging Airflow connection definitions |
| `orchestrator/config/development/variables.json` | JSON | Development variables (GCS bucket: `test-sfdc-etl-bucket`, GCP project: `prj-grp-sfdc-etl-dev-6e04`) |
| `orchestrator/config/development/connections.json` | JSON | Development Airflow connection definitions |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls--salesforce-sfdc-etl` | TLS certificate and private key for mTLS connections | Google Secret Manager |
| `sfdc_etl_sf_conn_password` | Salesforce connection password | GCS secrets blob (`secrets/variable-secrets.json`) |
| `sfdc_etl_hive_password` | Hive JDBC connection password | GCS secrets blob (`secrets/variable-secrets.json`) |

> Secret values are NEVER documented. Only names and purposes are listed here.

## Key Variable Values by Environment

| Variable | Development | Staging | Production |
|----------|-------------|---------|------------|
| `gcp_project_id` | `prj-grp-sfdc-etl-dev-6e04` | `prj-grp-sfdc-etl-stable-681e` | `prj-grp-sfdc-etl-prod-6b9b` |
| `gcs_bucket_name_{env}` | `test-sfdc-etl-bucket` | `grpn-us-central1-airflow-sfdc-etl-staging` | `grpn-us-central1-airflow-sfdc-etl-production` |
| `sf_conn_name_{env}` | `sf_dev_conn` | `sf_staging_conn` | `sf_prod_conn` |
| Teradata host | `teradata.groupondev.com` | `teradata.groupondev.com` | `teradata.groupondev.com` |
| Taxonomy API server_url | `edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |
| VIS API server_url | `edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `edge-proxy--staging--default.stable.us-central1.gcp.groupondev.com` | `edge-proxy--production--default.prod.us-central1.gcp.groupondev.com` |

## Per-Environment Overrides

- **Development**: Uses `test-sfdc-etl-bucket` in GCS; connects to `groupon-dev.my.salesforce.com`; Hive config present in variables but Hive DAGs point to the shared production Hive cluster; limited set of SF general settings IDs (does not include newer DAGs like `sf_deal_alerts_dag`)
- **Staging**: Uses `grpn-us-central1-airflow-sfdc-etl-staging` bucket and GCP project `prj-grp-sfdc-etl-stable-681e`; connects to `groupon-dev.my.salesforce.com`; no Hive config block (staging variables.json omits `hive_config`)
- **Production**: Uses `grpn-us-central1-airflow-sfdc-etl-production` bucket and GCP project `prj-grp-sfdc-etl-prod-6b9b`; connects to `groupon.my.salesforce.com`; full Hive config including SSL truststore; complete set of SF general settings IDs for all 28+ DAGs

## Certificate Configuration

| Property | Value |
|----------|-------|
| Secret name (GCP) | `tls--salesforce-sfdc-etl` |
| Local cert path | `certificates/cert.pem` |
| Local key path | `certificates/key.pem` |
| Hive truststore path | `orchestrator/certificates/DigiCertGlobalRootG2.jks` |
| Hive truststore type | JKS |
| Hive server (SSL) | `analytics.data-comp.prod.gcp.groupondev.com:8443` |
