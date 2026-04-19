---
service: "liteLLM"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, vault]
---

# Configuration

## Overview

LiteLLM uses a two-layer configuration model. Shared settings (image, scaling rules, ports, probes, log config, base env vars) are defined in `common.yml`. Environment-specific overrides (replica counts, API keys, credentials, regional endpoints, domain names) are defined in per-environment files (`staging-us-central1.yml`, `production-us-central1.yml`, `staging-europe-west1.yml`, `production-eu-west-1.yml`). Secrets are injected from a dedicated secrets submodule (`liteLLM-secrets`) at deploy time. The LiteLLM runtime configuration (model routing, caching, callbacks) is delivered as a Kubernetes ConfigMap mounted at `/app/config.yaml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `STORE_MODEL_IN_DB` | Enables PostgreSQL-backed model configuration storage | yes | `"true"` | `common.yml` |
| `JSON_LOGS` | Enables JSON-structured log output | yes | `True` | `common.yml` |
| `LITELLM_LOG` | Log level for the LiteLLM process | yes | `INFO` | `common.yml` |
| `DISABLE_SCHEMA_UPDATE` | Prevents LiteLLM from running DB schema migrations on startup | yes | `"true"` | `common.yml` |
| `REDIS_socket_timeout` | Redis client socket timeout in seconds | yes | `"5"` | `common.yml` |
| `REDIS_socket_connect_timeout` | Redis client connection timeout in seconds | yes | `"5"` | `common.yml` |
| `REDIS_retry_on_timeout` | Enables Redis retry on timeout | yes | `"True"` | `common.yml` |
| `REDIS_health_check_interval` | Redis health check interval in seconds | yes | `"30"` | `common.yml` |
| `REDIS_max_connections` | Maximum Redis connection pool size | yes | `"100"` | `common.yml` |
| `LOGGING_WORKER_MAX_TIME_PER_COROUTINE` | Max coroutine execution time for logging worker (seconds) | yes | `"60"` | `common.yml` |
| `REDIS_HOST` | Redis/Memorystore hostname | yes | None | per-environment yml |
| `REDIS_PORT` | Redis/Memorystore port | yes | `"6379"` | per-environment yml |
| `LANGFUSE_HOST` | Langfuse service URL for prompt observability callbacks | yes | None | per-environment yml |
| `SMTP_HOST` | SMTP relay hostname for email callbacks | yes | None | per-environment yml |
| `SMTP_PORT` | SMTP relay port | yes | `"25"` | per-environment yml |
| `SMTP_TLS` | Whether to use TLS for SMTP connection | yes | `"False"` | per-environment yml |
| `SMTP_SENDER_EMAIL` | Sender email address for LiteLLM notifications | yes | `conveyor-team@groupon.com` | per-environment yml |
| `PROXY_BASE_URL` | Public base URL of the LiteLLM proxy instance | yes | None | per-environment yml |
| `DATABASE_URL` | PostgreSQL connection string | yes | None | secrets submodule |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `STORE_MODEL_IN_DB` | Enables PostgreSQL-backed model config persistence | `"true"` | global |
| `DISABLE_SCHEMA_UPDATE` | Prevents automatic DB schema migrations at startup | `"true"` | global |
| `drop_params` (config.yaml) | Drops unsupported provider parameters instead of erroring | `true` | global |
| `prometheus_initialize_budget_metrics` (config.yaml) | Initializes Prometheus budget metrics on startup | `true` | global |
| `enable_end_user_cost_tracking_prometheus_only` (config.yaml) | Tracks end-user costs only via Prometheus (not DB) | `true` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/litellm/common.yml` | YAML | Shared deployment config: image, scaling, ports, probes, log config, base env vars, LiteLLM `config.yaml` ConfigMap |
| `.meta/deployment/cloud/components/litellm/staging-us-central1.yml` | YAML | Staging US-Central1 overrides: scaling, resource limits, env vars |
| `.meta/deployment/cloud/components/litellm/production-us-central1.yml` | YAML | Production US-Central1 overrides: scaling, resource limits, env vars, node affinity |
| `.meta/deployment/cloud/components/litellm/staging-europe-west1.yml` | YAML | Staging EU West1 overrides: scaling, Redis host |
| `.meta/deployment/cloud/components/litellm/production-eu-west-1.yml` | YAML | Production EU West1 (AWS) overrides: scaling, Redis (ElastiCache) host |
| `/app/config.yaml` (runtime, mounted ConfigMap) | YAML | LiteLLM runtime config: `litellm_settings` with callbacks, cache, cache_params, cache_control_injection |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL connection string including credentials | `liteLLM-secrets` git submodule (`.meta/deployment/cloud/secrets`) |
| LLM provider API keys | Authentication credentials for upstream LLM providers | `liteLLM-secrets` git submodule |
| Langfuse credentials | Authentication for Langfuse callback | `liteLLM-secrets` git submodule |
| LiteLLM master key / admin key | Admin API and virtual key management authentication | `liteLLM-secrets` git submodule |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging US-Central1 | Production US-Central1 | Staging EU West1 | Production EU West1 |
|---------|--------------------|-----------------------|-----------------|---------------------|
| Cloud | GCP | GCP | GCP | AWS |
| VPC | stable | prod | stable | prod |
| Min replicas | 2 | 3 | 1 | 2 |
| Max replicas | 3 | 10 | 2 | 15 |
| Memory request | 1Gi | 1.75Gi | (default) | (default) |
| Memory limit | 2Gi | 3.5Gi | (default) | (default) |
| CPU request | 200m | 200m | (default) | (default) |
| Redis host | `litellm-default-memorystore.us-central1.caches.stable.gcp.groupondev.com` | `litellm-default-memorystore.us-central1.caches.prod.gcp.groupondev.com` | `litellm-default-memorystore.europe-west1.caches.stable.gcp.groupondev.com` | `litellm-default-elasticache.eu-west-1.caches.prod.aws.groupondev.com` |
| Proxy base URL | `https://litellm-staging.groupondev.com` | `https://litellm.groupondev.com` | (not set) | (not set) |
| Node affinity | None | `standard-standalone` (required) | None | None |
