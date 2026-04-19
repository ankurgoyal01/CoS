---
service: "janus-web-cloud"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Janus Web Cloud follows the standard JTier/Dropwizard configuration model. The primary configuration source is a YAML configuration file loaded at startup, with environment-specific values injected via environment variables or per-environment config file overlays. Key configuration domains include MySQL connection settings, Bigtable/HBase project and instance coordinates, Elasticsearch cluster settings, BigQuery dataset references, SMTP relay credentials, and Quartz scheduler clustering parameters.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MYSQL_HOST` | MySQL database host for `continuumJanusMetadataMySql` | yes | — | env / config file |
| `MYSQL_PORT` | MySQL database port | yes | 3306 | env / config file |
| `MYSQL_DATABASE` | MySQL database name for Janus metadata | yes | — | env / config file |
| `MYSQL_USER` | MySQL username | yes | — | env / config file |
| `MYSQL_PASSWORD` | MySQL password | yes | — | env / secrets |
| `BIGTABLE_PROJECT_ID` | GCP project ID for Bigtable access | yes | — | env / config file |
| `BIGTABLE_INSTANCE_ID` | Bigtable instance ID for GDPR event reads | yes | — | env / config file |
| `ELASTICSEARCH_HOST` | Elasticsearch cluster host | yes | — | env / config file |
| `ELASTICSEARCH_PORT` | Elasticsearch cluster port | yes | 9200 | env / config file |
| `BIGQUERY_PROJECT_ID` | GCP project ID for BigQuery queries | yes | — | env / config file |
| `SMTP_HOST` | SMTP relay host for alert email dispatch | yes | — | env / config file |
| `SMTP_PORT` | SMTP relay port | yes | — | env / config file |
| `SMTP_USERNAME` | SMTP authentication username | yes | — | env / secrets |
| `SMTP_PASSWORD` | SMTP authentication password | yes | — | env / secrets |
| `QUARTZ_THREAD_COUNT` | Number of Quartz worker threads for scheduled jobs | no | — | env / config file |
| `QUARTZ_CLUSTER_ID` | Quartz cluster identifier for distributed scheduling | no | — | env / config file |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

> Note: Specific environment variable names are inferred from the dependency inventory and JTier/Dropwizard conventions. The source repository should be consulted for the canonical configuration file for exact key names.

## Feature Flags

> No evidence found of a feature-flag system in the architecture model.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (JTier/Dropwizard convention) | YAML | Primary service configuration: HTTP server, database, external client settings, Quartz scheduler |
| Per-environment override file (e.g., `config-staging.yml`) | YAML | Environment-specific value overrides for staging and production |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| MySQL password | Database authentication for `continuumJanusMetadataMySql` | External secrets management |
| SMTP credentials | Authentication for alert email dispatch via `smtpRelay` | External secrets management |
| GCP service account key | Authentication for Bigtable and BigQuery access | External secrets management |
| Elasticsearch credentials | Authentication for Elasticsearch cluster | External secrets management |

> Secret values are NEVER documented. Only names and rotation policies are recorded here.

## Per-Environment Overrides

- **Development**: Local MySQL, mocked or local Elasticsearch; SMTP typically disabled or directed to a test mailbox; Bigtable/BigQuery may use emulators or test projects.
- **Staging**: Staging-tier MySQL, Elasticsearch, and Bigtable instances; SMTP relay pointed at an internal test relay.
- **Production**: Production MySQL cluster with connection pooling; production Bigtable instance; production Elasticsearch cluster; live SMTP relay; Quartz clustering enabled across multiple service instances.
