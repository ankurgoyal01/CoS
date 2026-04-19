---
service: "coupons-inventory-service"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

Coupons Inventory Service is a Dropwizard (JTIER) application configured primarily through a YAML configuration file and environment variable overrides, following standard Continuum platform conventions. The service requires configuration for database connectivity (Postgres), Redis caching, message bus (Mbus) endpoints, and external HTTP service clients (Deal Catalog, VoucherCloud). Dependency injection is managed by Dagger at compile time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| Database connection URL | Postgres connection string for `continuumCouponsInventoryDb` | yes | none | env / config file |
| Database credentials | Username and password for Postgres access | yes | none | env / secrets |
| Redis connection URL | Connection string for `continuumCouponsInventoryRedis` | yes | none | env / config file |
| Message Bus configuration | Mbus broker endpoints and topic configuration | yes | none | env / config file |
| Deal Catalog Service URL | Base URL for the Deal Catalog HTTP client | yes | none | env / config file |
| VoucherCloud API URL | Base URL for the VoucherCloud HTTP client | yes | none | env / config file |
| VoucherCloud API credentials | Authentication credentials for VoucherCloud API | yes | none | env / secrets |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented. Exact variable names follow JTIER and Continuum platform naming conventions -- confirm with service owner.

## Feature Flags

> No evidence found in codebase for feature flag configuration. The Availability API returns NOT_IMPLEMENTED, which may indicate a feature flag or staged rollout -- confirm with service owner.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Application config (JTIER YAML) | YAML | Main Dropwizard configuration defining server, database, Redis, message bus, and HTTP client settings |

> Exact config file path follows JTIER conventions (typically `config.yml` or environment-specific variants). Confirm with service owner.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Postgres credentials | Database authentication for `continuumCouponsInventoryDb` | Platform secrets management |
| Redis credentials | Redis authentication for `continuumCouponsInventoryRedis` (if auth-enabled) | Platform secrets management |
| VoucherCloud API key | Authentication for external VoucherCloud API calls | Platform secrets management |
| Client identity secrets | Client authentication keys used by `continuumCouponsInventoryService_auth` | Platform secrets management |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase for specific per-environment configuration differences. Standard Continuum platform conventions apply: separate configuration files or environment variable overrides for development, staging, and production environments. Database connection strings, Redis endpoints, message bus brokers, and external service URLs differ per environment.
