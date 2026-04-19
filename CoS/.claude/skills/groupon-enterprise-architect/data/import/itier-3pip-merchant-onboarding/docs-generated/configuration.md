---
service: "itier-3pip-merchant-onboarding"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, itier-feature-flags]
---

# Configuration

## Overview

The service is configured via environment variables injected at runtime, following standard Continuum/iTier deployment conventions. Feature flags are managed through `itier-feature-flags`. No file-based config or external config store (Consul, Vault) was identified beyond standard iTier secrets injection.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment name (development, staging, production) | yes | — | env |
| `PORT` | HTTP server port for the iTier application | yes | 3000 | env |
| `OKTA_ISSUER` | Okta JWT issuer URL for SSO token verification | yes | — | env |
| `OKTA_CLIENT_ID` | Okta OAuth2 client identifier | yes | — | env |
| `MERCHANT_API_BASE_URL` | Base URL for the Universal Merchant API (`continuumUniversalMerchantApi`) | yes | — | env |
| `PARTNER_SERVICE_BASE_URL` | Base URL for the Partner Service (`continuumPartnerService`) | yes | — | env |
| `USERS_SERVICE_BASE_URL` | Base URL for the Users Service (`continuumUsersService`) | yes | — | env |
| `SQUARE_APP_ID` | Square OAuth application ID for install redirect | yes | — | env |
| `SQUARE_REDIRECT_URI` | OAuth redirect URI registered with Square | yes | — | env |
| `SHOPIFY_API_KEY` | Shopify OAuth API key | yes | — | env |
| `SHOPIFY_REDIRECT_URI` | OAuth redirect URI registered with Shopify | yes | — | env |
| `MINDBODY_API_KEY` | Mindbody API key for `@grpn/mindbody-client` | yes | — | env |
| `SALESFORCE_BASE_URL` | Base URL for Salesforce CRM synchronization | yes | — | env |
| `MERCHANT_CENTER_BASE_URL` | Base URL for Merchant Center redirect destinations | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Feature flags are managed through `itier-feature-flags` | Runtime toggles for partner-specific onboarding flows and experimental UI | — | per-tenant / global |

> Specific flag names are not discoverable from the architecture DSL. Consult the service repository's feature flag configuration for the full list.

## Config Files

> No file-based configuration beyond standard iTier defaults was identified in the inventory.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Okta client credentials | Authenticate the service with Okta for JWT verification | env / k8s-secret |
| Square OAuth credentials | Authorize Square OAuth install and callback flows | env / k8s-secret |
| Shopify OAuth credentials | Authorize Shopify OAuth install and callback flows | env / k8s-secret |
| Mindbody API credentials | Authenticate Mindbody API calls | env / k8s-secret |
| Salesforce API credentials | Authenticate Salesforce CRM synchronization calls | env / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

All environment-specific values (API base URLs, OAuth credentials, Okta issuer) are injected via environment variables. The `NODE_ENV` variable controls environment-specific behavior within the iTier application shell.
