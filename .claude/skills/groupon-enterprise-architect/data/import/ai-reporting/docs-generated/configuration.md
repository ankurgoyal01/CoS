---
service: "ai-reporting"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

AI Reporting is a Dropwizard/JTier service configured through a combination of JTier environment-specific YAML configuration files and environment variables. External secrets (database credentials, API keys, OAuth client secrets) are injected at runtime and never stored in source. Quartz job schedules, integration endpoints, and feature flag overrides are typically defined in JTier config files per environment.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MYSQL_HOST` | MySQL database host | yes | — | env |
| `MYSQL_PORT` | MySQL database port | yes | `3306` | env |
| `MYSQL_DATABASE` | MySQL database name | yes | — | env |
| `MYSQL_USER` | MySQL username | yes | — | env |
| `MYSQL_PASSWORD` | MySQL password | yes | — | vault |
| `HIVE_JDBC_URL` | Hive JDBC connection string | yes | — | env |
| `BIGQUERY_PROJECT_ID` | GCP project ID for BigQuery | yes | — | env |
| `BIGQUERY_DATASET_ID` | BigQuery dataset for CitrusAd analytics | yes | — | env |
| `GCS_BUCKET_NAME` | GCS bucket for feed and report files | yes | — | env |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to GCP service account key file | yes | — | env |
| `CITRUSAD_API_BASE_URL` | CitrusAd API base URL | yes | — | env |
| `CITRUSAD_CLIENT_ID` | CitrusAd OAuth client ID | yes | — | vault |
| `CITRUSAD_CLIENT_SECRET` | CitrusAd OAuth client secret | yes | — | vault |
| `SALESFORCE_BASE_URL` | Salesforce REST API base URL | yes | — | env |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | — | vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | — | vault |
| `SLACK_WEBHOOK_URL` | Slack Incoming Webhook URL for operational alerts | yes | — | vault |
| `NOTS_SERVICE_URL` | NOTS notification service base URL | yes | — | env |
| `LAZLO_SERVICE_URL` | Lazlo feature flag / identity service URL | yes | — | env |
| `M3_SERVICE_URL` | M3 Merchant service base URL | yes | — | env |
| `DEAL_CATALOG_SERVICE_URL` | Deal Catalog service base URL | yes | — | env |
| `ORDERS_SERVICE_URL` | Orders service base URL | yes | — | env |
| `AUDIENCE_MGMT_SERVICE_URL` | Audience Management service base URL | yes | — | env |
| `UMAPI_SERVICE_URL` | Universal Merchant API base URL | yes | — | env |
| `MBUS_BROKER_URL` | JTier Message Bus broker connection URL | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| > No evidence found | Feature flag configuration is managed via `continuumApiLazloService` at runtime | — | — |

Feature flags are evaluated at runtime through the `continuumAiReportingService_lazloClient` component by calling `continuumApiLazloService`. No static flag registry was discoverable from the DSL inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (JTier standard) | YAML | Primary Dropwizard/JTier configuration: server, database pool, MessageBus, Quartz scheduler, integration endpoint overrides |
| `config-{env}.yml` (JTier standard) | YAML | Per-environment overrides (dev, staging, production) for endpoint URLs and pool sizes |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `MYSQL_PASSWORD` | MySQL database authentication | vault |
| `CITRUSAD_CLIENT_SECRET` | CitrusAd OAuth client credential | vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client credential | vault |
| `SLACK_WEBHOOK_URL` | Slack operational alert webhook | vault |
| `GOOGLE_APPLICATION_CREDENTIALS` content | GCP service account for BigQuery and GCS | vault |

> Secret values are NEVER documented. Only names and rotation policies are recorded here. Rotation policy: consult ads-eng@groupon.com and the Groupon secrets management runbook.

## Per-Environment Overrides

- **Development**: Local MySQL, mock CitrusAd and Salesforce endpoints, Quartz jobs run on reduced schedules, Slack alerts disabled
- **Staging**: Full integration with CitrusAd and Salesforce staging tenants, GCS staging bucket, Hive on test cluster
- **Production**: Live CitrusAd production tenant, Salesforce production org, production GCS bucket, full Quartz schedule, Slack alerts active
