---
service: "deploybot"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, credentials-files]
---

# Configuration

## Overview

deploybot is configured primarily through environment variables that control runtime behavior (environment name, Docker subscriptions) and a credentials directory (`/auth/creds`) that provides secrets for external integrations. Per-repository deployment behavior is defined by a `.deploy_bot.yml` file committed to each service's own repository. The service supports four deployment environments: `local`, `development`, `staging`, and `production`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_ENV` | Sets the active runtime environment (`production`, `staging`, `development`, `local`) | yes | — | env |
| `DOCKER_SUBSCRIBE` | Controls whether the service subscribes to Docker daemon events (`true`/`false`) | no | `false` | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `DOCKER_SUBSCRIBE` | Enables or disables Docker event subscription at startup | `false` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/auth/creds` | Directory of credential files | Provides runtime secrets for Artifactory, GitHub, and Jira integrations |
| `/auth/creds/artifactory` | Plain text | Artifactory username and password for image validation and promotion |
| `/auth/creds/github` | Plain text | GitHub token for REST API calls (commit status, `.deploy_bot.yml` reads) |
| `/auth/creds/jira` | Plain text | Jira username and password for SOX logbook ticket creation and closure |
| `.deploy_bot.yml` | YAML (v1 or v2 schema) | Per-repository deployment configuration: environments, deploy commands, validation gates, promotion chains |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `/auth/creds/artifactory` | Artifactory username + password | credentials file (mounted volume) |
| `/auth/creds/github` | GitHub API token | credentials file (mounted volume) |
| `/auth/creds/jira` | Jira username + password | credentials file (mounted volume) |
| Okta OIDC client credentials | OAuth2/OIDC authentication for protected web UI actions | > No evidence found in codebase for specific secret store |
| AWS credentials | S3 log archival | IAM role or environment-injected access key |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **local**: Uses `deploybotFakeJira` stub instead of live Jira; Docker subscriptions and Kubernetes integration may be disabled; credentials files sourced from local filesystem
- **development**: Connects to development-tier MySQL, Kubernetes, and external services; reduced validation strictness may apply
- **staging**: Full integration with staging-tier dependencies; mirrors production validation gates
- **production**: Full SOX validation enforcement; all external integrations active; ProdCAT and GPROD gates required; Jira logbook mandatory

The `DEPLOY_ENV` variable drives all environment-specific branching in the application. No evidence found for environment-specific config files beyond the credentials directory.
