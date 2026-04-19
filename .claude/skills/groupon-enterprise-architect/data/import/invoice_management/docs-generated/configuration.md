---
service: "invoice_management"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, skeletor-config]
---

# Configuration

## Overview

invoice_management uses the standard Continuum/Skeletor configuration model. Application configuration is managed through Play Framework `application.conf` and environment-specific override files (`application.prod.conf`, etc.). Secrets (NetSuite OAuth credentials, AWS credentials, database passwords) are injected as environment variables at runtime. The Quartz scheduler configuration is embedded in the application config.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | PostgreSQL host address | yes | none | env |
| `DB_PORT` | PostgreSQL port | yes | 5432 | env |
| `DB_NAME` | PostgreSQL database name | yes | none | env |
| `DB_USER` | PostgreSQL username | yes | none | env |
| `DB_PASSWORD` | PostgreSQL password | yes | none | vault / env |
| `NETSUITE_ACCOUNT_ID` | NetSuite account identifier for API calls | yes | none | env |
| `NETSUITE_CONSUMER_KEY` | OAuth 1.0a consumer key for NetSuite | yes | none | vault / env |
| `NETSUITE_CONSUMER_SECRET` | OAuth 1.0a consumer secret for NetSuite | yes | none | vault / env |
| `NETSUITE_TOKEN` | OAuth 1.0a access token for NetSuite | yes | none | vault / env |
| `NETSUITE_TOKEN_SECRET` | OAuth 1.0a access token secret for NetSuite | yes | none | vault / env |
| `AWS_ACCESS_KEY_ID` | AWS access key for S3 remittance report uploads | yes | none | vault / env |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for S3 operations | yes | none | vault / env |
| `AWS_S3_BUCKET` | S3 bucket name for remittance report storage | yes | none | env |
| `AWS_REGION` | AWS region for S3 client | yes | us-east-1 | env |
| `MBUS_BROKER_URL` | Message Bus broker connection URL | yes | none | env |
| `MBUS_CLIENT_ID` | Message Bus client identifier | yes | none | env |
| `ROCKETMAN_BASE_URL` | Base URL for Rocketman email service | yes | none | env |
| `SHIPMENT_TRACKER_BASE_URL` | Base URL for Shipment Tracker service | yes | none | env |
| `GOODS_STORES_API_BASE_URL` | Base URL for Goods Stores API | yes | none | env |
| `ACCOUNTING_SERVICE_BASE_URL` | Base URL for Accounting Service | yes | none | env |
| `COMMERCE_INTERFACE_BASE_URL` | Base URL for Commerce Interface | yes | none | env |
| `GPAPI_BASE_URL` | Base URL for GPAPI | yes | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No feature flag system identified for invoice_management. Feature toggles, if needed, are managed through application config overrides per environment.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON (Play Framework) | Main application configuration: database, mbus, Quartz scheduler, service URLs |
| `conf/application.prod.conf` | HOCON | Production environment overrides |
| `conf/application.staging.conf` | HOCON | Staging environment overrides |
| `conf/routes` | Play routes DSL | HTTP routing table for all REST endpoints |
| `build.sbt` | SBT DSL | Build definition, dependency declarations, Java 8 target |
| `project/plugins.sbt` | SBT | SBT plugin declarations (Play plugin, etc.) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `NETSUITE_CONSUMER_KEY` | OAuth 1.0a consumer key for NetSuite API | vault / env |
| `NETSUITE_CONSUMER_SECRET` | OAuth 1.0a consumer secret for NetSuite API | vault / env |
| `NETSUITE_TOKEN` | OAuth 1.0a token for NetSuite API | vault / env |
| `NETSUITE_TOKEN_SECRET` | OAuth 1.0a token secret for NetSuite API | vault / env |
| `DB_PASSWORD` | PostgreSQL database password | vault / env |
| `AWS_ACCESS_KEY_ID` | AWS access key for S3 | vault / env |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for S3 | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Play Framework environment-specific conf files (`application.prod.conf`, `application.staging.conf`) override database connection strings, service base URLs, and mbus broker addresses per environment. NetSuite credentials differ between production (live NetSuite instance) and staging (NetSuite sandbox). AWS S3 bucket names differ per environment. Quartz scheduler job intervals may be reduced in staging for faster testing cycles.
