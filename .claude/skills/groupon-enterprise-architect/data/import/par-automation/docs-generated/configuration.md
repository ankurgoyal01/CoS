---
service: "par-automation"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, gcp-secret-manager]
---

# Configuration

## Overview

PAR Automation is configured entirely through environment variables, resolved at startup by the `config` package using Viper. Sensitive credentials (password, Okta client secret, Jira API token) are injected as environment variables from GCP Secret Manager via the Kubernetes deployment manifests. The `ENV` and `REGION` variables drive all environment-specific URL defaults. No config files are read at runtime.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Runtime environment; governs Jira base URL, HB API domain, and certificate ARN. Values: `production`, `staging`, `sandbox` | yes | none | Helm values (`production-us-central1.yml`, `staging-us-central1.yml`, etc.) |
| `REGION` | GCP region string. Values: `us-central1`, `europe-west1` | yes | none | Helm values |
| `PROJECT_NUMBER` | GCP project number used to resolve Secret Manager secret paths | yes | `426383070542` (prod) / `151559929481` (staging) | Helm values |
| `HYBRID-BOUNDARY-SVC-USER` | Password for the `svc_hbuser` headless service account | yes | none | GCP Secret Manager |
| `HYBRID-BOUNDARY-SVC-USER-OKTA` | Okta client secret for `svc_hbuser` to obtain OAuth tokens | yes | none | GCP Secret Manager |
| `HYBRID-BOUNDARY-SVC-USER-JIRA` | Jira API token for `svc_hbuser` to create/update Jira issues | yes | none | GCP Secret Manager |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase. No runtime feature flags are used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Shared Helm values: image name, scaling, health probe paths, HTTP port (8080) |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production US env vars (`ENV`, `PROJECT_NUMBER`, `REGION`) and scaling overrides |
| `.meta/deployment/cloud/components/api/production-europe-west1.yml` | YAML | Production EU env vars and scaling overrides |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging US env vars and scaling overrides |
| `.meta/deployment/cloud/components/api/staging-europe-west1.yml` | YAML | Staging EU env vars and scaling overrides |
| `.meta/deployment/cloud/scripts/deploy.sh` | Bash | Helm template + krane deploy script invoked by Deploybot |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `HYBRID-BOUNDARY-SVC-USER` | Password for the `svc_hbuser` headless account (used for Hybrid Boundary and Okta auth) | GCP Secret Manager (path: `projects/{PROJECT_NUMBER}/secrets/HYBRID-BOUNDARY-SVC-USER/versions/latest`) |
| `HYBRID-BOUNDARY-SVC-USER-OKTA` | Okta client secret for OAuth2 token acquisition | GCP Secret Manager |
| `HYBRID-BOUNDARY-SVC-USER-JIRA` | Jira API token for authenticated REST calls | GCP Secret Manager |

> Secret values are never documented. All secrets are stored in the `par-automation-secrets` git submodule mounted at `.meta/deployment/cloud/secrets`.

## Per-Environment Overrides

| Setting | sandbox | staging | production |
|---------|---------|---------|------------|
| `ENV` value | `sandbox` | `staging` | `production` |
| Jira base URL | `https://groupondev-sandbox-274.atlassian.net` | `https://groupondev-sandbox-274.atlassian.net` | `https://groupondev.atlassian.net` |
| HB API domain | `hybrid-boundary--api.gensandbox.service` | `hybrid-boundary--api.staging.service` | `hybrid-boundary--api.production.service` |
| Service Portal domain | `service-portal.gensandbox.service` | `service-portal.staging.service` | `service-portal.production.service` |
| Certificate ARN suffix | `ca.par-automation.dev` | `ca.par-automation.staging` | `ca.par-automation.production` |
| Jira tickets created | No | No | Yes |
| HB policy applied | Yes (always) | Yes (always) | Yes (on approval) |
| `minReplicas` | 1 | 1 | 1 |
| `maxReplicas` | 2 | 2 | 2 (per region) |

> Global common defaults (port 8080, `hpaTargetUtilization: 50`, `minReplicas: 2`, `maxReplicas: 15`) are set in `common.yml` and may be overridden per-environment.
