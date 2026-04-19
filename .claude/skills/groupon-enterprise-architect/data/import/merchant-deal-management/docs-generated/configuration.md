---
service: "merchant-deal-management"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

Specific configuration files, environment variable names, and secrets for the Merchant Deal Management service are not resolvable from the available repository inventory (no Gemfile, config files, Helm charts, or environment manifests are present in the indexed source). The information below captures what is known from the architecture model about configuration categories that must exist.

## Environment Variables

> No environment variable names are resolvable from the available inventory. The following categories are expected based on the architecture model.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| MySQL connection credentials | Database hostname, port, username, password, database name for `continuumDealManagementApiMySql` | yes | None | env or vault |
| Redis connection URL | Connection string for `continuumDealManagementApiRedis` (Resque queues, rate limiting) | yes | None | env or vault |
| Salesforce credentials | API endpoint, client ID, client secret, or token for Salesforce HTTPS/REST integration | yes | None | vault |
| ServiceDiscovery configuration | Endpoint or configuration for Continuum service discovery used by Faraday clients | yes | None | env |
| Resque worker concurrency | Number of concurrent Resque worker threads/processes | yes | Not specified | env |

> IMPORTANT: Actual secret values are never documented. Only variable categories and purposes are listed.

## Feature Flags

> No evidence found in codebase for feature flag configuration.

## Config Files

> No evidence found in codebase for config file paths. Standard Rails convention uses `config/` directory for environment-specific YAML files; specific files are not resolvable from the available inventory.

| File | Format | Purpose |
|------|--------|---------|
| `config/database.yml` (inferred) | yaml | MySQL connection configuration per environment |
| `config/resque.yml` (inferred) | yaml | Resque and Redis queue configuration |

## Secrets

> Secret values are NEVER documented. Only names and rotation policies.

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Salesforce API credentials | Authentication for HTTPS/REST calls to Salesforce | Not specified (vault expected) |
| MySQL password | Database authentication for `continuumDealManagementApiMySql` | Not specified (vault expected) |
| Redis auth token | Authentication for `continuumDealManagementApiRedis` | Not specified (vault expected) |

## Per-Environment Overrides

> No evidence found in codebase for specific per-environment configuration differences. Standard Continuum platform conventions apply (development, staging, production environments with environment-specific database and Redis endpoints).
