---
service: "selfsetup-hbw"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

selfsetup-hbw is configured entirely through environment variables injected at container start. There is no consul, vault, or external config store evidenced in the inventory. Environment-specific values (production vs. staging) are differentiated by the `APPLICATION_ENV` variable and per-environment Kubernetes/EKS pod configurations managed by DeployBot 2.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `APPLICATION_ENV` | Sets the active Zend application environment (`production`, `staging`, etc.) — controls which config ini files are loaded | yes | — | env |
| `BOOKINGTOOL_CREDENTIALS` | BasicAuth credentials for BookingTool API calls (per-country, format: `user:password` or structured credential blob) | yes | — | env / k8s-secret |
| `SALESFORCE_CLIENT_ID` | OAuth 2.0 client ID for Salesforce API authentication | yes | — | env / k8s-secret |
| `SALESFORCE_CLIENT_SECRET` | OAuth 2.0 client secret for Salesforce API authentication | yes | — | env / k8s-secret |
| `SALESFORCE_USERNAME` | Salesforce integration user username (used in password grant flow) | yes | — | env / k8s-secret |
| `SALESFORCE_PASSWORD` | Salesforce integration user password (used in password grant flow) | yes | — | env / k8s-secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a feature flag system in the inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `application/configs/application.ini` | INI (Zend) | Zend Framework application configuration — database DSN, locale settings, Salesforce and BookingTool endpoint URLs per environment |
| `application/configs/` (per-env overrides) | INI | Environment-specific overrides loaded based on `APPLICATION_ENV` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `BOOKINGTOOL_CREDENTIALS` | BasicAuth credentials for BookingTool API | k8s-secret (EKS) |
| `SALESFORCE_CLIENT_ID` | Salesforce OAuth client ID | k8s-secret (EKS) |
| `SALESFORCE_CLIENT_SECRET` | Salesforce OAuth client secret | k8s-secret (EKS) |
| `SALESFORCE_USERNAME` | Salesforce integration account username | k8s-secret (EKS) |
| `SALESFORCE_PASSWORD` | Salesforce integration account password | k8s-secret (EKS) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production** (`dub1`): `APPLICATION_ENV=production` — uses production Salesforce org and live BookingTool API endpoints
- **Staging** (`snc1`): `APPLICATION_ENV=staging` — uses Salesforce sandbox and staging BookingTool endpoints
- Locale support spans eight locales (`en_GB`, `de_DE`, `es_ES`, `fr_FR`, `it_IT`, `nl_NL`, `pl_PL`, `ja_JP`) and is driven by Zend_Translate configuration; locale selection is determined at runtime from the merchant's invitation URL or browser locale negotiation
