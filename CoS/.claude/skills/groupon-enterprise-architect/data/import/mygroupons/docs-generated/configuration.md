---
service: "mygroupons"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

My Groupons is configured primarily through environment variables injected at runtime via Kubernetes/Helm. Feature flags are managed through the Alchemy feature flag system and evaluated per-request. No local config files store environment-specific secrets; these are injected via Helm chart values or Kubernetes secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Defines the runtime environment (production, staging, development) | yes | — | env |
| `PORT` | HTTP port the Express server listens on | yes | `3000` | env / helm |
| `API_PROXY_URL` | Base URL for the API Proxy used for all downstream calls | yes | — | helm |
| `ORDERS_SERVICE_URL` | Base URL for the Orders Service | yes | — | helm |
| `DEAL_CATALOG_URL` | Base URL for the Deal Catalog Service | yes | — | helm |
| `USERS_SERVICE_URL` | Base URL for the Users Service | yes | — | helm |
| `VOUCHER_INVENTORY_URL` | Base URL for the Voucher Inventory Service | yes | — | helm |
| `RELEVANCE_API_URL` | Base URL for the Relevance API | yes | — | helm |
| `GIMS_URL` | Base URL for GIMS | yes | — | helm |
| `THIRD_PARTY_INVENTORY_URL` | Base URL for the Third-Party Inventory Service | yes | — | helm |
| `BARCODE_SERVICE_URL` | Base URL for the Barcode Service | yes | — | helm |
| `LAYOUT_SERVICE_URL` | Base URL for the Layout Service | yes | — | helm |
| `ALCHEMY_URL` | Base URL for the Alchemy feature flag service | yes | — | helm |
| `CHROMIUM_PATH` | Path to the Chromium binary used by Puppeteer for PDF generation | yes | `/usr/bin/chromium-browser` | env / helm |
| `LOG_LEVEL` | Logging verbosity (debug, info, warn, error) | no | `info` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `alchemy` | Master flag for Alchemy feature flag system integration | enabled | global |
| `citydeals_voucher` | Enables city deals voucher display variant | disabled | per-tenant |
| `gift_envelope` | Enables the gift envelope UI on the gifting page | disabled | per-tenant |
| `load_order` | Controls deferred/lazy loading of order data on the main page | disabled | per-region |
| `order_editing` | Enables order editing capabilities post-purchase | disabled | per-tenant |
| `partial_returns` | Enables partial return of multi-unit voucher orders | disabled | per-tenant |
| `sms_gift` | Enables SMS delivery option for voucher gifting | disabled | per-tenant |
| `ai_chatbot` | Enables AI-powered chatbot widget on My Groupons pages | disabled | per-tenant |
| `gifting_legacy` | Routes gifting flow to legacy gifting implementation | enabled | global |
| `salesforce_ticket_create` | Enables Salesforce ticket creation from return/exchange flows | disabled | per-tenant |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `helm/values.yaml` | YAML | Helm chart default values for Kubernetes deployment (service URLs, replicas, resources) |
| `helm/values-production.yaml` | YAML | Production environment overrides for Helm chart |
| `helm/values-staging.yaml` | YAML | Staging environment overrides for Helm chart |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `KELDOR_SECRET` | Session signing secret used by keldor auth middleware | k8s-secret |
| `API_PROXY_TOKEN` | Service-to-service auth token for API Proxy requests | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: `NODE_ENV=development`; all service URLs point to local or sandbox instances; Chromium may be provided by the local OS; feature flags may be overridden in local config
- **Staging**: `NODE_ENV=staging`; Helm values override service URLs to staging cluster endpoints; HPA minimum replicas reduced
- **Production**: `NODE_ENV=production`; Helm values set production service URLs and resource limits; HPA configured for 3–25 replicas across `us-central1`, `eu-west-1`, and `us-west-2`
