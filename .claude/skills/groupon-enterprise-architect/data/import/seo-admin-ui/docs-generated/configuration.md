---
service: "seo-admin-ui"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [keldor-config, env-vars, feature-flags]
---

# Configuration

## Overview

seo-admin-ui uses **keldor-config** (version 4.23.2) as its primary configuration mechanism, which is the standard Continuum platform config library. It reads environment-specific configuration at startup from keldor-config's centralised store. Runtime feature flags are managed via **itier-feature-flags** 3.1.2. Secrets (OAuth credentials, service tokens) are injected as environment variables at runtime.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NODE_ENV` | Runtime environment identifier (development, staging, production) | yes | production | env |
| `PORT` | HTTP port the I-Tier server listens on | yes | 3000 | env |
| `KELDOR_CONFIG_ENV` | keldor-config environment namespace selector | yes | none | env |
| `GOOGLE_SEARCH_CONSOLE_CLIENT_ID` | OAuth 2.0 client ID for Google Search Console API | yes | none | vault / env |
| `GOOGLE_SEARCH_CONSOLE_CLIENT_SECRET` | OAuth 2.0 client secret for Google Search Console API | yes | none | vault / env |
| `NEO4J_URI` | Connection URI for the SEO Neo4j instance | yes | none | env / keldor-config |
| `NEO4J_USERNAME` | Neo4j authentication username | yes | none | vault / env |
| `NEO4J_PASSWORD` | Neo4j authentication password | yes | none | vault / env |
| `MEMCACHED_HOSTS` | Comma-separated list of Memcached host:port addresses | yes | none | env / keldor-config |
| `LPAPI_BASE_URL` | Base URL for the Landing Page API | yes | none | keldor-config |
| `SEO_DEAL_API_BASE_URL` | Base URL for the SEO Deal API | yes | none | keldor-config |
| `MECS_BASE_URL` | Base URL for the MECS content service | yes | none | keldor-config |
| `SEO_CHECKOFF_BASE_URL` | Base URL for the SEO Checkoff Service | yes | none | keldor-config |
| `KEYWORD_KB_BASE_URL` | Base URL for the Keyword KB API | yes | none | keldor-config |
| `GAPI_GRAPHQL_ENDPOINT` | GraphQL endpoint URL for Deal Catalog (GAPI) | yes | none | keldor-config |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| > No specific flag names found in inventory. | Feature flags are managed via itier-feature-flags 3.1.2. Flags gate rollout of new admin UI features. | — | per-tenant |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `keldor-config` store (external) | JSON / key-value | All environment-specific service URLs, timeouts, and non-secret config values |
| `webpack.config.js` | JavaScript | Frontend asset bundling configuration for webpack 5.91.0 |
| `package.json` | JSON | Dependency manifest, npm scripts, Node.js engine constraint (^20) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GOOGLE_SEARCH_CONSOLE_CLIENT_SECRET` | OAuth 2.0 secret for Google Search Console API authentication | vault / env |
| `NEO4J_PASSWORD` | Neo4j database password | vault / env |
| `NEO4J_USERNAME` | Neo4j database username | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Configuration differs across environments via **keldor-config** namespace selection (controlled by `KELDOR_CONFIG_ENV`). Service base URLs, Neo4j connection strings, and Memcached hosts all vary per environment. Google Search Console API credentials use environment-specific OAuth service accounts. Feature flags default states may differ between staging and production to allow controlled rollout.
