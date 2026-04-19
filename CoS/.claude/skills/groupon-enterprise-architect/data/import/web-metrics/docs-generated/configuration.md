---
service: "web-metrics"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "helm-values", "keldor-config"]
---

# Configuration

## Overview

Web Metrics is configured via a combination of environment variables injected by Kubernetes/Helm, a per-run JSON config file (or URL) provided at invocation time, and the Groupon-internal `keldor-config` library for application-level settings. The CronJob schedule and resource limits are managed in `.deploy-configs/values.yaml` and per-environment Helm value files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TELEGRAF_URL` | Full URL of the Telegraf metrics gateway | No | `http://metrics-gateway-vip.snc1:80` | env/helm |
| `NODE_ENV` | Node.js environment mode | Yes | `production` | helm (values.yaml) |
| `JTIER_RUN_CMD` | Groupon iTier command to run | Yes | `cron` | helm (values.yaml) |
| `JTIER_RUN_CONFIG` | Path to the iTier runtime config YAML | Yes | e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml` | helm (per-env values) |
| `KELDOR_CONFIG_SOURCE` | Keldor config profile selector | Yes | `{production}` or `{staging}` | helm (per-env values) |
| `NODE_OPTIONS` | Node.js VM flags | No | `--max-old-space-size=1024` (prod) / `--max-old-space-size=2048` (staging) | helm (per-env values) |
| `PORT` | Port value passed by platform (not used for HTTP serving) | No | `8000` | helm (per-env values) |
| `UV_THREADPOOL_SIZE` | libuv thread pool size (affects DNS/crypto/fs async ops) | No | `75` | helm (per-env values) |
| `DEPLOY_AZ` | Availability zone tag applied to metric points | No | `snc1` (fallback) | platform-injected |
| `DEPLOY_ENV` | Deployment environment tag applied to metric points | No | `dev` (fallback) | platform-injected |
| `DEPLOY_NAMESPACE` | Kubernetes namespace tag applied to metric points | No | `webmetrics2.snc1` (fallback) | platform-injected |
| `DEPLOY_REGION` | Region tag for on-premises metric format | No | `us-grpn` (fallback) | platform-injected |
| `DEPLOY_VPC` | VPC tag for on-premises metric format | No | `on-prem-host` (fallback) | platform-injected |
| `DEPLOY_SERVICE` | Service name tag applied to metric points | No | `web-metrics` (fallback) | platform-injected |
| `TELEGRAF_METRICS_ATOM` | Atom tag for Telegraf routing | No | `webmetrics2.snc1` (fallback) | platform-injected |
| `KUBERNETES_SERVICE_HOST` | Detected to switch between cloud and on-premises metric tag format | No | set by Kubernetes | platform-injected |
| `WM_CHILD` | Internal flag to detect parent vs. child process in steno attachment flow | No | unset | internal |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase.

No feature flags framework (LaunchDarkly, Flagr, etc.) is used. The only toggle-like behaviour is the `--dryRun` CLI flag, which suppresses Telegraf writes during local development.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/base.cson` | CSON | Base application config — sets steno transport to `file` |
| `config/node-env/development.cson` | CSON | Development override — sets steno transport to `console` |
| `services/<service-name>/webmetrics.config.json` | JSON | Per-service run config: `cruxRuns` and `perfRuns` arrays with name, path, envs, platforms, budgets |
| `.deploy-configs/values.yaml` | YAML | Helm chart common values: cron schedule `10,40 * * * *`, restart policy, log dir, resource requests |
| `.deploy-configs/<env>.yml` | YAML | Per-environment Helm values: cloud provider, image, replicas, namespace, VIP DNS, env vars |
| `input-example*.json` | JSON | Example run config files for local development and testing |

## Secrets

> No evidence found in codebase.

No secrets manager (Vault, AWS Secrets Manager, Kubernetes Secrets) references are visible in the Helm values files (`secretEnvVars: []`, `secretFiles: {}`). The PSI API key is embedded in `lib/defaultConfigs.js` as a non-rotating public API key. Production secrets, if any, would be injected via the platform's secret mechanism outside this repository.

## Per-Environment Overrides

| Setting | Staging (us-central1) | Production (us-central1) |
|---------|----------------------|--------------------------|
| `minReplicas` | 1 | 2 |
| `maxReplicas` | 3 | 3 |
| `memory.main.request` | 2048Mi | 1536Mi |
| `memory.main.limit` | 4096Mi | 3072Mi |
| `NODE_OPTIONS` | `--max-old-space-size=2048` | `--max-old-space-size=1024` |
| `KELDOR_CONFIG_SOURCE` | `{staging}` | `{production}` |
| `JTIER_RUN_CONFIG` | `…/staging-us-central1.yml` | `…/production-us-central1.yml` |
| CrUX run environments | Staging URL excluded by code | Only production URLs queried |
