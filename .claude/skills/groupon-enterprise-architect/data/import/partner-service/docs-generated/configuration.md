---
service: "partner-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, vault]
---

# Configuration

## Overview

Partner Service follows JTier/Dropwizard configuration conventions. The primary configuration is delivered through a YAML config file (standard Dropwizard pattern) with environment-specific overrides injected via environment variables at deploy time. Secrets (database credentials, Salesforce API keys, AWS credentials, Google service account keys) are managed externally and injected as environment variables or via a secrets manager. The `jtier-daas-postgres` and `jtier-messagebus-client` libraries consume JTier-standard configuration keys.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection URL for `continuumPartnerServicePostgres` | yes | none | env / vault |
| `DATABASE_USER` | PostgreSQL username | yes | none | env / vault |
| `DATABASE_PASSWORD` | PostgreSQL password | yes | none | env / vault |
| `MBUS_BROKER_URL` | MBus JMS/STOMP broker connection URL | yes | none | env / vault |
| `MBUS_USERNAME` | MBus authentication username | yes | none | env / vault |
| `MBUS_PASSWORD` | MBus authentication password | yes | none | env / vault |
| `SALESFORCE_API_URL` | Salesforce REST API base URL | yes | none | env / vault |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | yes | none | env / vault |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | yes | none | env / vault |
| `AWS_ACCESS_KEY_ID` | AWS IAM access key for S3 operations | yes | none | env / vault |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key for S3 operations | yes | none | env / vault |
| `AWS_S3_DOCUMENT_BUCKET` | Target S3 bucket for partner documentation uploads | yes | none | env |
| `AWS_S3_UNIVERSAL_BUCKET` | Target S3 bucket for universal partner artifact uploads | yes | none | env |
| `GOOGLE_SHEETS_CREDENTIALS` | Google service account JSON credentials for Sheets API | yes | none | env / vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found. Feature flag configuration was not identified in the inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (Dropwizard standard) | YAML | Primary application configuration: HTTP server, database, MBus, logging |
| Flyway migration scripts | SQL | Schema migration definitions applied on startup |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL credentials | Database authentication for `continuumPartnerServicePostgres` | vault / env |
| MBus credentials | Message broker authentication | vault / env |
| Salesforce OAuth credentials | CRM API authentication | vault / env |
| AWS IAM credentials | S3 access for document and artifact uploads | vault / env |
| Google Sheets service account | Sheets API authentication for partner data ingestion | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Dropwizard supports environment-specific YAML overrides. JTier deployments typically use separate config profiles per environment (development, staging, production). Database connection pools, MBus broker URLs, Salesforce sandbox vs. production endpoints, and S3 bucket names all differ between environments. Specific override paths are managed by the JTier platform team deployment configuration outside this repository.
