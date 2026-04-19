---
service: "proxykong"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, k8s-secrets, cson-config-files, helm-values]
---

# Configuration

## Overview

ProxyKong is configured through a layered system. Base and environment-specific CSON config files (under `config/`) provide application defaults via the iTier/Keldor config framework. Kubernetes deploy manifests (`.deploy-configs/`) inject environment variables and mount Kubernetes secrets into the container filesystem. The iTier framework merges these layers at startup based on the `NODE_ENV` and `KELDOR_CONFIG_SOURCE` values.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KELDOR_CONFIG_SOURCE` | Selects the Keldor/iTier config environment tier (`{staging}` or `{production}`) | yes | none | helm / deploy config |
| `NODE_OPTIONS` | Node.js runtime flags; sets `--max-old-space-size=1024` | yes | none | helm / deploy config |
| `PORT` | HTTP port the Node.js server listens on | yes | `8000` | helm / deploy config |
| `UV_THREADPOOL_SIZE` | libuv thread pool size for async I/O operations | yes | `75` | helm / deploy config |
| `GITHUB_TOKEN` | Personal access token for GitHub Enterprise; used to authenticate Git operations and pull request creation | yes | none | Kubernetes secret `git-auth` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `enable_okta_cookie_user` | When enabled, reads authenticated user identity from `proxyKong_email` and `proxyKong_username` cookies instead of Okta HTTP headers; used for local development | false | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base configuration applied to all environments; defines Steno transport and service client defaults |
| `config/node-env/development.cson` | CSON | Overrides for local development environment |
| `config/node-env/production.cson` | CSON | Enables `log_tracky_to_file` for production logging |
| `config/node-env/staging.cson` | CSON | Staging-specific iTier config overrides |
| `config/node-env/test.cson` | CSON | Test environment overrides |
| `config/stage/production.cson` | CSON | Sets production CDN hosts (`www<1,2>.grouponcdn.com`) and `baseUrl` |
| `config/stage/staging.cson` | CSON | Sets staging CDN hosts and `baseUrl` |
| `config/stage/uat.cson` | CSON | UAT stage overrides |
| `.deploy-configs/values.yaml` | YAML | Napistrano-generated Helm values; defines service ID, log path, Filebeat resource limits |
| `.deploy-configs/production-us-west-1.yml` | YAML | Production US West 1 deployment parameters (replicas, namespace, VIPs, memory, CPU) |
| `.deploy-configs/production-eu-west-1.yml` | YAML | Production EU West 1 deployment parameters |
| `.deploy-configs/staging-us-west-1.yml` | YAML | Staging US West 1 deployment parameters |
| `.deploy-configs/staging-us-west-2.yml` | YAML | Staging US West 2 deployment parameters |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `git-auth` (key: `github_token.json`) | GitHub Enterprise personal access token for Git operations and PR creation; injected as `GITHUB_TOKEN` env var and mounted at `/secrets/git/github_token.json` | Kubernetes Secret |
| `jira-auth` | Jira API credentials for issue creation; mounted at `/secrets/jira/jira.json` | Kubernetes Secret |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Development**: Uses `config/node-env/development.cson` and `config/stage/staging.cson`. Local dev requires manual cookie injection for authentication (`proxyKong_email`, `proxyKong_username`).
- **Staging**: `KELDOR_CONFIG_SOURCE` is set to `{staging}`. The service resolves staging CDN hosts and staging `baseUrl`. Staging namespaces are `proxykong-staging`. VIP is `proxykong.staging.service`.
- **Production**: `KELDOR_CONFIG_SOURCE` is set to `{production}`. CDN hosts use `www<1,2>.grouponcdn.com`. VIP is `proxykong.production.service`. Production replicas are set to min 2, max 3.
- **UAT**: Only available in the on-premises North America region; uses `config/stage/uat.cson`.
