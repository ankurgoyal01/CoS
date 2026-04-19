---
service: "checkout-flow-analyzer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The application is configured through environment variables (for secrets and mode flags) and TypeScript config files (`src/config/app.config.ts`, `next.config.ts`, `src/utils/security.ts`). There is no external config store (Consul, Vault, Helm). Security headers and session behavior are defined in code and applied at startup.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OKTA_CLIENT_ID` | OAuth 2.0 client ID for the Okta application | Yes (in production) | None | env |
| `OKTA_CLIENT_SECRET` | OAuth 2.0 client secret for the Okta application | Yes (in production) | None | env |
| `OKTA_ISSUER` | Okta issuer URL (e.g., `https://<org>.okta.com/oauth2/default`) | Yes (in production) | None | env |
| `NEXTAUTH_SECRET` | Secret used to sign and encrypt NextAuth JWTs and session cookies | Yes | None | env |
| `NEXTAUTH_URL` | Canonical URL of the deployment (e.g., `http://localhost:3000`) | Yes | None | env |
| `NEXT_PUBLIC_AUTH_DEV_MODE` | When `true`, replaces Okta with a simple credentials provider for local development | No | `false` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `NEXT_PUBLIC_AUTH_DEV_MODE` | Switches authentication from Okta OIDC to a local credentials provider (any username/password accepted) | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/config/app.config.ts` | TypeScript | Centralizes session expiry constants (`SESSION_EXPIRY: 3600s`, `SESSION_MAX_AGE: 3600000ms`, `SESSION_CLEANUP_INTERVAL: 300000ms`), log column mappings for all four log types (pwa, proxy, lazlo, orders), and Kibana visualization column defaults |
| `src/utils/security.ts` | TypeScript | Defines the `Content-Security-Policy` header value and the full set of `SECURITY_HEADERS` applied to all routes |
| `next.config.ts` | TypeScript | Registers security headers via `async headers()` for all routes (`/(.*)`); integrates `flowbite-react` Next.js plugin; disables ESLint during builds |
| `tailwind.config.ts` | TypeScript | Tailwind CSS theme configuration |
| `postcss.config.mjs` | JavaScript (ESM) | PostCSS configuration for Tailwind CSS processing |
| `.eslintrc.json` / `eslint.config.mjs` | JSON / JavaScript | ESLint rules (not applied during builds) |
| `jest.config.js` | JavaScript | Jest test configuration with `jest-environment-jsdom` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OKTA_CLIENT_SECRET` | Authenticates the application to Okta's token endpoint | Environment variable (deployment-managed) |
| `NEXTAUTH_SECRET` | Signs and encrypts NextAuth session JWTs | Environment variable (deployment-managed) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Auth Provider | Notes |
|-------------|--------------|-------|
| Local development | `CredentialsProvider` (when `NEXT_PUBLIC_AUTH_DEV_MODE=true`) | Any username/password accepted; no Okta variables needed |
| Staging / Production | `OktaProvider` | All three Okta variables required; `NEXT_PUBLIC_AUTH_DEV_MODE` must be absent or `false` |

The session expiry is fixed at 3600 seconds (1 hour) in `app.config.ts` for all environments. There are no per-region config overrides.
