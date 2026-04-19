---
service: "reporting-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The reporting service is a Java/Spring WAR deployed on a JVM. Configuration is supplied via environment variables and Spring property files. Database connection details, AWS credentials, MBus connection parameters, and external API base URLs are all externalized. No evidence of Consul, Vault, or Helm-based config is present in the federated architecture model; operational config management details should be confirmed with the MX Platform Team.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `REPORTING_DB_URL` | JDBC URL for `continuumReportingDb` (PostgreSQL) | yes | none | env |
| `REPORTING_DB_USER` | Username for `continuumReportingDb` | yes | none | env |
| `REPORTING_DB_PASSWORD` | Password for `continuumReportingDb` | yes | none | env |
| `DEALCAP_DB_URL` | JDBC URL for `continuumDealCapDb` (PostgreSQL) | yes | none | env |
| `DEALCAP_DB_USER` | Username for `continuumDealCapDb` | yes | none | env |
| `DEALCAP_DB_PASSWORD` | Password for `continuumDealCapDb` | yes | none | env |
| `FILES_DB_URL` | JDBC URL for `continuumFilesDb` (PostgreSQL) | yes | none | env |
| `FILES_DB_USER` | Username for `continuumFilesDb` | yes | none | env |
| `FILES_DB_PASSWORD` | Password for `continuumFilesDb` | yes | none | env |
| `VOUCHERS_DB_URL` | JDBC URL for `continuumVouchersDb` (PostgreSQL) | yes | none | env |
| `VOUCHERS_DB_USER` | Username for `continuumVouchersDb` | yes | none | env |
| `VOUCHERS_DB_PASSWORD` | Password for `continuumVouchersDb` | yes | none | env |
| `VAT_DB_URL` | JDBC URL for `continuumVatDb` (PostgreSQL) | yes | none | env |
| `VAT_DB_USER` | Username for `continuumVatDb` | yes | none | env |
| `VAT_DB_PASSWORD` | Password for `continuumVatDb` | yes | none | env |
| `EU_VOUCHER_DB_URL` | JDBC URL for `continuumEuVoucherDb` (PostgreSQL) | yes | none | env |
| `EU_VOUCHER_DB_USER` | Username for `continuumEuVoucherDb` | yes | none | env |
| `EU_VOUCHER_DB_PASSWORD` | Password for `continuumEuVoucherDb` | yes | none | env |
| `AWS_S3_BUCKET` | S3 bucket name for report artifact storage (`reportingS3Bucket`) | yes | none | env |
| `AWS_REGION` | AWS region for S3 and STS | yes | none | env |
| `AWS_ROLE_ARN` | IAM role ARN for STS assumption (S3 access) | yes | none | env |
| `MBUS_CONNECTION_URL` | MBus broker URL for publishing and consuming events | yes | none | env |
| `PRICING_API_BASE_URL` | Base URL for `continuumPricingApi` | yes | none | env |
| `TERADATA_JDBC_URL` | JDBC URL for Teradata warehouse | no | none | env |
| `TERADATA_USER` | Username for Teradata | no | none | env |
| `TERADATA_PASSWORD` | Password for Teradata | no | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

> Note: Exact variable names are inferred from the service summary and architecture model. Confirm precise names from the service's `application.properties` or deployment manifests.

## Feature Flags

> No evidence found in the architecture model for feature flags. Feature flag configuration to be confirmed with service owner.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application.properties` | properties | Spring application configuration — data sources, MBus, S3, scheduler settings |
| `src/main/resources/ehcache.xml` | xml | EhCache 2.10.1 cache configuration — cache names, TTLs, heap sizes |
| `src/main/resources/logback.xml` (or `log4j.xml`) | xml | Logging configuration |

> Exact file paths to be confirmed from the service repository.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database passwords (all six PostgreSQL instances) | Authentication for `continuumReportingDb`, `continuumDealCapDb`, `continuumFilesDb`, `continuumVouchersDb`, `continuumVatDb`, `continuumEuVoucherDb` | env / secrets manager |
| AWS role ARN / credentials | IAM authentication for S3 and STS | env / aws-secrets-manager |
| MBus credentials | Authentication for message bus connection | env / secrets manager |
| Teradata credentials | Authentication for Teradata warehouse | env / secrets manager |

> Secret values are NEVER documented. Only names and purposes are listed here.

## Per-Environment Overrides

> No environment-specific config evidence is present in the federated architecture model. Per-environment overrides (dev, staging, production) are expected to differ in database URLs, AWS bucket names, MBus broker URLs, and external API base URLs. Confirm with the MX Platform Team for environment-specific values.
