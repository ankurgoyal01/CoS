---
service: "calcom"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, k8s-secret]
---

# Configuration

## Overview

Calcom is configured through environment variables injected at Kubernetes deployment time via Helm chart values. Non-secret values are defined in per-environment YAML files under `.meta/deployment/cloud/components/worker/`. Secrets (database credentials, admin credentials, SMTP auth) are stored in the `calcom-secrets` repository and injected via Kubernetes secrets at deploy time. The Helm chart used is `cmf-generic-api` version `3.88.1`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `NEXT_PUBLIC_WEBAPP_URL` | Public-facing base URL of the web app | yes | — | helm env-vars |
| `NEXT_PUBLIC_WEBSITE_URL` | Public-facing website URL | yes | — | helm env-vars |
| `NEXT_PUBLIC_API_V2_URL` | Base URL for Cal.com v2 API | yes | — | helm env-vars |
| `NEXTAUTH_URL` | Base URL used by NextAuth.js for auth callbacks | yes | — | helm env-vars |
| `EMAIL_SERVER_HOST` | SMTP server hostname for outbound email | yes | `smtp.gmail.com` | helm env-vars |
| `EMAIL_SERVER_PORT` | SMTP server port | yes | `465` | helm env-vars |
| `EMAIL_FROM` | Sender email address for outbound notifications | yes | `calcom@groupon.com` (prod) / `calcomstaging@groupon.com` (staging) | helm env-vars |
| `NEXT_PUBLIC_DEBUG` | Enables debug logging | no | `1` (production and GCP staging) | helm env-vars |
| `ALLOWED_HOSTNAMES` | Comma-separated list of permitted hostnames | yes | `"groupon.com","http://:3000"` (prod) | helm env-vars |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No Groupon-managed feature flags are configured at the deployment layer. Feature flags, if any, are inherited from the upstream Cal.com application.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Base Kubernetes deployment configuration: scaling limits, resource requests/limits, probe paths, network policy, HTTP port |
| `.meta/deployment/cloud/components/worker/production-us-west-1.yml` | YAML | Production overrides for AWS us-west-1: env vars, scaling, resource sizing |
| `.meta/deployment/cloud/components/worker/production-us-central1.yml` | YAML | Production overrides for GCP us-central1: env vars, scaling, resource sizing |
| `.meta/deployment/cloud/components/worker/staging-us-west-1.yml` | YAML | Staging overrides for AWS us-west-1: env vars, reduced scaling |
| `.meta/deployment/cloud/components/worker/staging-us-central1.yml` | YAML | Staging overrides for GCP us-central1: env vars, reduced scaling |
| `.meta/deployment/cloud/scripts/deploy.sh` | Shell | Helm template + krane deployment script |
| `.deploy_bot.yml` | YAML | Deploy bot target configuration: clusters, contexts, promote-to chains |
| `Jenkinsfile` | Groovy | CI pipeline: Docker build targeting staging-us-west-1 and staging-us-central1 |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Admin credentials | Cal.com global admin account login | `calcom-secrets` GitHub repository (`admin_credentials`) |
| Database credentials | PostgreSQL connection credentials (DBA user) | `calcom-secrets` GitHub repository (`database_credentials`) |
| SMTP credentials | Gmail SMTP authentication for email sending | Kubernetes secrets (injected via `.meta/deployment/cloud/secrets/`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging (AWS us-west-1) | Staging (GCP us-central1) | Production (AWS us-west-1) | Production (GCP us-central1) |
|---------|------------------------|--------------------------|---------------------------|------------------------------|
| `NEXT_PUBLIC_WEBAPP_URL` | `https://calcom.staging.service.us-west-1.aws.groupondev.com` | `https://calcom.staging.service.us-central1.gcp.groupondev.com` | `https://meet.groupon.com` | `https://meet.groupon.com` |
| `NEXTAUTH_URL` | (not set) | `http://127.0.0.1:3000` | `https://meet.groupon.com` | `https://meet.groupon.com` |
| `EMAIL_FROM` | `calcomstaging@groupon.com` | `calcomstaging@groupon.com` | `calcom@groupon.com` | `calcom@groupon.com` |
| `ALLOWED_HOSTNAMES` | `"groupondev.com","http://:3000"` | (not set) | `"groupon.com","http://:3000"` | (not set) |
| Min replicas | 1 | 1 | 2 | 2 |
| Max replicas | 2 | 2 | 4 | 4 |
| CPU request (main) | (default 100m) | (default 100m) | 200m | 200m |
| Memory request/limit (main) | (default 500Mi/1500Mi) | (default 500Mi/1500Mi) | 1000Mi/3000Mi | 1000Mi/3000Mi |
