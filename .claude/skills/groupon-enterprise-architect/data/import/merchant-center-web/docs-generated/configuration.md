---
service: "merchant-center-web"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

Merchant Center Web is a Vite-built SPA. Configuration is injected at build time via Vite environment variables (prefixed `VITE_`) and baked into the static bundle. Runtime configuration for third-party SDKs (GrowthBook, PostHog, GTM) is provided via public API keys embedded in the build. No server-side config store (Consul, Vault) is used at the SPA layer.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `VITE_UMAPI_BASE_URL` | Base URL for proxied UMAPI calls | yes | None | env |
| `VITE_AIDG_BASE_URL` | Base URL for proxied AIDG calls | yes | None | env |
| `VITE_AIAAS_BASE_URL` | Base URL for proxied AIaaS calls | no | None | env |
| `VITE_BYNDER_BASE_URL` | Base URL for proxied Bynder calls | no | None | env |
| `VITE_SALESFORCE_BASE_URL` | Base URL for proxied Salesforce calls | no | None | env |
| `VITE_DOORMAN_SSO_URL` | Doorman SSO authentication endpoint | yes | None | env |
| `VITE_GROWTHBOOK_API_HOST` | GrowthBook API host for feature flag evaluation | no | None | env |
| `VITE_GROWTHBOOK_CLIENT_KEY` | GrowthBook SDK client key | no | None | env |
| `VITE_POSTHOG_API_KEY` | PostHog project API key | no | None | env |
| `VITE_POSTHOG_API_HOST` | PostHog ingestion host | no | None | env |
| `VITE_GTM_ID` | Google Tag Manager container ID | no | None | env |
| `VITE_CLARITY_PROJECT_ID` | Microsoft Clarity project ID | no | None | env |
| `VITE_MARKER_IO_DESTINATION` | Marker.io destination ID for bug reports | no | None | env |
| `VITE_OTEL_EXPORTER_OTLP_ENDPOINT` | OpenTelemetry trace exporter endpoint | no | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

> No evidence found in codebase for the exact variable names above; names are inferred from the inventory-listed integrations and standard Vite naming conventions. Confirm actual names against the `.env.example` or CI/CD pipeline configuration.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| GrowthBook-managed flags | Progressive rollout and A/B test control for all feature gating | off (default varies per flag) | per-tenant / global |

> Individual flag names are managed in GrowthBook and are not enumerated in the codebase inventory.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `vite.config.ts` | TypeScript | Vite build configuration: plugins, aliases, proxy rules, environment variable exposure |
| `.env` / `.env.*` | dotenv | Per-environment variable definitions loaded by Vite at build time |
| `tailwind.config.ts` | TypeScript | Tailwind CSS design token and theme configuration |
| `tsconfig.json` | JSON | TypeScript compiler options and path aliases |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Doorman SSO client secret | OAuth2 client authentication with Doorman | Build-time / CI secret |
| PostHog API key | Project-scoped analytics ingestion key | CI secret / env var |
| GrowthBook client key | SDK key for feature flag API | CI secret / env var |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The SPA supports distinct environment builds via Vite's `.env.[mode]` file convention:

- **Development** (`dev`): Vite dev server with hot-module replacement; proxy rules in `vite.config.ts` forward API calls to local or staging backends.
- **Staging**: Static build deployed to a staging GCS bucket; all `VITE_*` variables point to staging service endpoints.
- **Production**: Static build deployed to the production GCS bucket and served via Akamai CDN; all `VITE_*` variables point to production service endpoints.
