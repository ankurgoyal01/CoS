---
service: "librechat"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secrets, k8s-configmap]
---

# Configuration

## Overview

LibreChat is configured through two complementary layers: environment variables injected at container runtime (sourced from Helm values and Kubernetes secrets), and a `librechat.yaml` config file mounted as a Kubernetes ConfigMap volume at `/app/librechat.yaml`. Environment-specific overrides are layered on top of common defaults via the `common.yml` + `<env>.yml` pattern managed by Raptor/Conveyor.

## Environment Variables

### App Component (`continuumLibrechatApp`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MONGO_URI` | MongoDB connection string for the LibreChat database | yes | None | env (per-env.yml) |
| `MEILI_HOST` | Meilisearch host URL for full-text search | yes | None | env (per-env.yml) |
| `RAG_API_URL` | URL of the RAG API service | yes | None | env (per-env.yml) |
| `DOMAIN_CLIENT` | Public client domain used for CORS and redirect | yes | None | env (per-env.yml) |
| `DOMAIN_SERVER` | Public server domain used for redirect URIs | yes | None | env (per-env.yml) |
| `AUTH_PROVIDER` | Authentication provider type | yes | `oidc` | env (common.yml) |
| `OPENID_ISSUER` | Okta OIDC issuer URL | yes | `https://groupon.okta.com/oauth2/default` | env (common.yml) |
| `OPENID_SCOPE` | OIDC scopes requested during login | yes | `openid email profile` | env (common.yml) |
| `OPENID_CALLBACK_URL` | OIDC redirect callback path | yes | `/oauth/openid/callback` | env (common.yml) |
| `OPENID_REUSE_TOKENS` | Whether to reuse existing OIDC tokens | no | `true` | env (common.yml) |
| `OPENID_AUTO_REDIRECT` | Auto-redirect to OIDC provider on page load | no | `false` | env (common.yml) |
| `OPENID_BUTTON_LABEL` | Label shown on the SSO login button | no | `okta` | env (common.yml) |
| `LOGIN_MAX` | Maximum number of login attempts allowed | no | `10000` | env (common.yml) |
| `ALLOW_SOCIAL_LOGIN` | Enable social (OIDC/Google) login | no | `true` | env (common.yml) |
| `ALLOW_SOCIAL_REGISTRATION` | Enable social login-based registration | no | `true` | env (common.yml) |
| `PLUGIN_MODELS` | Comma-separated list of plugin-compatible models | no | `gpt-4,gpt-4-turbo-preview,gpt-4-0125-preview,...` | env (common.yml) |
| `DEFAULT_USER_ROLE` | MongoDB ObjectID for the default user role | no | `686e95531c7971a047432f4e` | env (per-env.yml) |
| `HOST` | Bind address for the Node.js server | no | `0.0.0.0` | Dockerfile `ENV` |

### RAG API Component (`continuumLibrechatRagApi`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | VectorDB (pgvector) host | yes | None | env (per-env.yml) |
| `DB_PORT` | VectorDB port | yes | `80` | env (per-env.yml) |
| `RAG_PORT` | Port on which the RAG API listens | yes | `8000` | env (per-env.yml) |
| `EMBEDDINGS_PROVIDER` | Embedding model provider | yes | `openai` | env (per-env.yml) |

### VectorDB Component (`continuumLibrechatVectordb`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `PGDATA` | PostgreSQL data directory path | yes | `/var/lib/postgresql/data/pgdata` | env (common.yml) |

### MongoDB Component (`continuumLibrechatMongodb`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `MONGODB_PORT_NUMBER` | MongoDB listen port | yes | `27017` | env (common.yml) |
| `MONGODB_REPLICA_SET_NAME` | Replica set name | yes | `rs0` | env (common.yml) |
| `MONGODB_EXTRA_FLAGS` | Extra mongod flags | no | `--replSet=rs0` | env (common.yml) |
| `MONGODB_ENABLE_JOURNAL` | Enable journaling | no | `yes` | env (common.yml) |
| `BITNAMI_DEBUG` | Bitnami debug mode | no | `false` | env (common.yml) |

> IMPORTANT: Secret values (API keys, database passwords, embedding API keys) are NEVER documented here. They are managed in the `librechat-secrets` git submodule at `.meta/deployment/cloud/secrets/` (repo: `git@github.groupondev.com:conveyor-cloud/librechat-secrets.git`).

## Feature Flags

> No evidence found in codebase of discrete feature flag configuration beyond the env-var-driven toggles (`ALLOW_SOCIAL_LOGIN`, `ALLOW_SOCIAL_REGISTRATION`, `OPENID_AUTO_REDIRECT`) documented in the env vars table above.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common app component config: image, scaling, probes, ports, base env vars |
| `.meta/deployment/cloud/components/app/<env>.yml` | YAML | Per-environment overrides: cloud provider, region, scaling, service URLs |
| `/app/librechat.yaml` (mounted ConfigMap) | YAML | LibreChat application config: version, cache, social logins, custom LLM endpoints, model lists |
| `.meta/deployment/cloud/components/mongodb/common.yml` | YAML | MongoDB component config: image, probes, resource limits, volumes, replica set config |
| `.meta/deployment/cloud/components/rag-api/common.yml` | YAML | RAG API component config: image, scaling, probes, port, network policy |
| `.meta/deployment/cloud/components/vectordb/common.yml` | YAML | VectorDB component config: image, probes, persistent volumes, port |
| `.meta/deployment/cloud/components/meilisearch/common.yml` | YAML | Meilisearch component config: image, probes, persistent volumes, port |
| `.meta/.raptor.yml` | YAML | Raptor component registry: declares all five service components and their types |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| OpenAI API key | Embedding generation for RAG pipeline | k8s-secret (librechat-secrets submodule) |
| LiteLLM API key | LLM model routing authentication | k8s-secret (librechat-secrets submodule) |
| OIDC client secret | Okta OIDC client authentication | k8s-secret (librechat-secrets submodule) |
| MongoDB credentials | Database access authentication | k8s-secret (librechat-secrets submodule) |

> Secret values are NEVER documented. Secrets are injected from the `librechat-secrets` git submodule at `.meta/deployment/cloud/secrets/cloud/<env>.yml` during Helm template rendering.

## Per-Environment Overrides

| Environment | Region | Differences |
|-------------|--------|-------------|
| dev | GCP us-central1 | `minReplicas: 1`, `maxReplicas: 2`, custom `dev` subdomain, no full env var overrides |
| staging | GCP us-central1 | `minReplicas: 1`, `maxReplicas: 2`, service URLs point to `*.staging.service`, domain `librechat-staging.groupondev.com` |
| staging | GCP europe-west1 | `minReplicas: 1`, `maxReplicas: 2`, EU region |
| staging | AWS us-west-2 | `minReplicas: 1`, `maxReplicas: 2`, AWS cloud provider |
| production | GCP us-central1 | `minReplicas: 2`, `maxReplicas: 15`, service URLs point to `*.production.service`, domain `librechat.production.service.us-central1.gcp.groupondev.com` |
| production | GCP europe-west1 | `minReplicas: 2`, `maxReplicas: 15`, EU production |
| production | AWS us-west-2 | `minReplicas: 2`, `maxReplicas: 15`, AWS production |
| production | AWS eu-west-1 | `minReplicas: 2`, `maxReplicas: 15`, EU AWS production |
