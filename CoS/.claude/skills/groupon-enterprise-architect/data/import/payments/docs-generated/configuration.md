---
service: "payments"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: []
---

# Configuration

## Overview

> No evidence found in codebase for specific configuration mechanisms. As a Spring Boot Java service, the Payments Service likely uses standard Spring configuration (application.yml / application.properties, environment variables, and/or Spring Cloud Config). PCI-scoped secrets are expected to be managed through a secure secrets management system.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | Payments DB MySQL host | yes | — | env / config |
| `DB_PORT` | Payments DB MySQL port | yes | 3306 | env / config |
| `DB_NAME` | Payments DB database name | yes | — | env / config |
| `DB_USERNAME` | Payments DB credentials | yes | — | vault / secrets |
| `DB_PASSWORD` | Payments DB credentials | yes | — | vault / secrets |
| `PAYMENT_GATEWAY_*` | Per-provider gateway configuration (URLs, timeouts) | yes | — | env / config |

> The environment variables above are inferred from the service's dependencies (MySQL DaaS, external payment gateways). Actual variable names should be verified against the service's source configuration.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `application.yml` | yaml | Spring Boot application configuration (inferred) |

> No evidence found in codebase for specific config files. The above is inferred from the Spring Boot framework.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials | MySQL (DaaS) connection authentication | > No evidence found in codebase for secrets store. |
| Payment gateway API keys | Per-provider authentication with external PSPs | > No evidence found in codebase for secrets store. |

> Secret values are NEVER documented. Only names and rotation policies. PCI compliance requires that payment gateway credentials and database credentials are stored in an approved secrets management system with appropriate access controls and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Standard practice for Continuum services is to use environment-specific configuration for database endpoints, gateway URLs, and secret references across dev, staging, and production environments.
