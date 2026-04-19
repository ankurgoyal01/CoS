---
service: "selfsetup-fd"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

selfsetup-fd is configured primarily via environment variables injected at runtime into the Docker/Kubernetes container. The three known variables govern timezone, Apache listen port, and the Telegraf metrics endpoint. Additional Salesforce OAuth credentials and Booking Tool API connection settings are expected to be supplied as environment variables or application-level config files, though specific names for those secrets are not evidenced in the inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `APPLICATION_TIMEZONE` | Sets the PHP application timezone for date/time operations | yes | `Europe/Paris` | env |
| `APACHE_LISTEN_PORT` | Configures the Apache HTTP server listen port inside the container | yes | `8080` | env |
| `TELEGRAF_URL` | Base URL for the Telegraf metrics gateway; used by `influxdb-php` to emit metrics | yes | none | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found of feature flags in the inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `composer.json` | JSON | PHP dependency manifest; defines Zend Framework, monolog, influxdb-php versions |
| `Gemfile` | Ruby | Capistrano deployment tool dependencies (Ruby 2.3.3, capistrano 3.6.1) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Salesforce OAuth credentials | Authenticates `selfsetupFd_ssuSalesforceClient` against Salesforce REST API | No evidence found of specific secret store; to be confirmed by service owner |
| Booking Tool API credentials | Authenticates `selfsetupFd_ssuBookingToolClient` against Booking Tool System | No evidence found of specific secret store; to be confirmed by service owner |
| MySQL connection string | Connects `continuumEmeaBtSelfSetupFdApp` to `continuumEmeaBtSelfSetupFdDb` | No evidence found of specific secret store; to be confirmed by service owner |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging** (`snc1`): Uses staging Salesforce sandbox and Booking Tool staging instance. `APPLICATION_TIMEZONE` and `APACHE_LISTEN_PORT` remain the same.
- **Production** (`dub1`, Dublin): Uses production Salesforce org and production Booking Tool. Full metric emission via `TELEGRAF_URL`.
- Environment-specific values are injected via Kubernetes configuration at deploy time.
