---
service: "web-config"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, yaml-data-files]
---

# Configuration

## Overview

web-config is configured through a combination of environment variables (used at build/deploy time and by the redirect CLI), YAML data files checked into the repository under `data/{env}/`, and a per-environment Go CLI config file at `conf/config_{environment}.yaml`. There is no runtime config store such as Consul or Vault; secrets are fetched on demand from AWS Secrets Manager.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Target environment for config generation (`test`, `uat`, `staging`, `production`, `redirect`) | yes (if not passed as arg) | — | env |
| `PLATFORM` | Target web platform (`nginx`, `apache`) | yes (if not passed as arg) | — | env |
| `DEPLOY_TARGET` | Deployment target (`cloud`, `on-prem`) | yes (if not passed as arg) | — | env |
| `TEMPLATES` | Override path for Mustache template directory | no | `templates/{platform}` | env |
| `ERROR_TEMPLATES` | Override path for error page template directory | no | `templates/error_pages` | env |
| `TARGET` | Override path for generated config output directory | no | `conf/{platform}/k8s/{env}` (cloud) or `conf/{platform}/{env}` | env |
| `SOURCE` | Override path for data source directory | no | `data/{env}` | env |
| `ARTIFACT_VERSION` | Version tag applied to Docker images during CI (`{date}_{sha}`) | yes (CI only) | — | Jenkins |
| `UAT_ARTIFACT` | Full image reference for UAT Docker image | yes (CI deploy stage) | — | Jenkins |
| `STG_ARTIFACT` | Full image reference for staging Docker image | yes (CI deploy stage) | — | Jenkins |
| `PROD_ARTIFACT` | Full image reference for production Docker image | yes (CI deploy stage) | — | Jenkins |
| `DEPLOYMENT_REPO` | Name of the deployment manifest repository | yes (CI deploy stage) | `routing-deployment` | Jenkins |
| `DOCKER_DEFAULT_PLATFORM` | Forces amd64 builds on Apple Silicon (M1) Mac | no | — | `.envrc` (direnv) |
| `REDIRECT_API_TOKEN` | GitHub Enterprise OAuth2 token for PR creation by redirect CLI | yes (redirect CLI) | — | env |
| `USER` | Local OS username; used for Git branch name prefix and Jira comment attribution | yes (redirect CLI) | OS default | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No runtime feature flags system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `data/{env}/defaults/default.yml` | YAML | Default vhost parameters (listen_port, server_admin, log_path, default_error_pages) for each environment |
| `data/{env}/defaults/nginx_cloud.yml` | YAML | nginx + cloud-specific defaults (brotli, cloud flag, etc.) for each environment |
| `data/{env}/env.yml` | YAML | Optional per-environment overrides applied on top of defaults |
| `data/{env}/access.yml` | YAML | Optional access-control configuration (auth_type, allow_from IP ranges) |
| `data/{env}/sites/*.yml` | YAML | Per-country virtual-host specification (domains, languages, rewrites, error_pages, brand) |
| `data/{env}/rewrites/nginx.*` | nginx rewrite syntax | Per-country rewrite rules included into virtual-host configs |
| `data/shared/rewrites/nginx.global` | nginx rewrite syntax | Global rewrite rules applied to all virtual hosts |
| `data/shared/rewrites/nginx.all_envs.us` | nginx rewrite syntax | US redirect rules shared across all environments |
| `conf/config_{environment}.yaml` | YAML | Go redirect CLI configuration (`jira_url`, `redirects_output_path`, `env_specific_folder`) |
| `templates/nginx/*.mustache` | Mustache | nginx configuration templates (main.conf, virtual_host.conf, includes/*.conf) |
| `templates/error_pages/*.mustache` | Mustache | Localized HTML error page templates |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `hybrid-boundary-svc-user-jira` | Jira API token (JSON: `jira_token`) for a dedicated Jira service account; used by the redirect automation CLI | aws-secrets-manager |
| `REDIRECT_API_TOKEN` (env var) | GitHub Enterprise OAuth2 token for creating pull requests in `routing/web-config` | env (set by operator before running redirect CLI) |
| `svcdcos-ssh` | SSH key credential used by Jenkins for git push to the `routing-deployment` repository | Jenkins credentials store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Deploy target | Key differences |
|-------------|---------------|----------------|
| `test` | cloud (k8s) | Permissive config; allows deploying HEAD without a specific revision |
| `uat` / `staging` | cloud (k8s) | Near-production config; allows deploying HEAD; no explicit revision required |
| `production` | cloud (k8s) | Full config; requires a specific Git SHA revision to deploy; deploys to SNC1, SAC1, DUB1 regions |
| `redirect` | cloud (k8s) | Uses production data but outputs to a dedicated redirect server path; env normalised to `production` after path selection |

Config differences per environment are achieved by having separate `data/{env}/` directory trees. The `deploy_target=cloud` flag controls whether generated output lands in `conf/nginx/k8s/{env}/` (for Kubernetes) or `conf/nginx/{env}/` (for legacy on-premises hosts).
