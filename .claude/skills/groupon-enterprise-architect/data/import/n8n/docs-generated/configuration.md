---
service: "n8n"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, k8s-secret, kustomize]
---

# Configuration

## Overview

n8n is configured entirely via environment variables injected at deployment time through Conveyor Cloud's Kustomize-based deployment pipeline. Non-secret values are declared in per-component, per-environment YAML files under `.meta/deployment/cloud/components/`. Secret values (database credentials, runner auth tokens, API keys) are sourced from Kubernetes secrets managed in the `n8n-secrets` submodule (path: `.meta/deployment/cloud/secrets`).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_TYPE` | Database backend type | yes | `postgresdb` | helm |
| `DB_POSTGRESDB_POOL_SIZE` | PostgreSQL connection pool size | no | — | helm (queue-worker: 100) |
| `EXECUTIONS_MODE` | Execution mode: `queue` or `regular` | yes | `queue` | helm |
| `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS` | Send manual executions to queue workers | no | `true` | helm |
| `N8N_HOST` | Public hostname for the n8n instance | yes | per-instance | helm |
| `N8N_EDITOR_BASE_URL` | Base URL for the workflow editor UI | yes | per-instance | helm |
| `N8N_PORT` | HTTP port for the n8n service | yes | `5678` | helm |
| `N8N_PROTOCOL` | Protocol: `https` | yes | `https` | helm |
| `NODE_ENV` | Node environment | yes | `production` | helm |
| `WEBHOOK_URL` | Public URL for inbound webhook receipt | yes | per-instance | helm |
| `N8N_OAUTH_REDIRECT_URL` | OAuth2 redirect callback URL | no | per-instance | helm |
| `N8N_PAYLOAD_SIZE_MAX` | Maximum payload size in MB | no | `1024` | helm |
| `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` | Allow community packages as tools | no | `true` | helm |
| `N8N_REINSTALL_MISSING_PACKAGES` | Auto-reinstall missing community packages | no | `true` | helm |
| `N8N_SSL_CERT` | Path to TLS certificate | yes | `/var/groupon/server_certs/tls.crt` | helm |
| `N8N_SSL_KEY` | Path to TLS private key | yes | `/var/groupon/server_certs/tls.key` | helm |
| `NODE_OPTIONS` | Node.js V8 heap cap; varies by instance | yes | per-instance | helm |
| `N8N_LOG_FILE_LOCATION` | Log file path | yes | `/var/groupon/logs/logfile.log` | helm |
| `N8N_LOG_OUTPUT` | Log output targets | yes | `file,console` | helm |
| `N8N_LOG_FORMAT` | Log format | yes | `json` | helm |
| `N8N_METRICS` | Enable Prometheus metrics endpoint | yes | `true` | helm |
| `N8N_METRICS_INCLUDE_WORKFLOW_NAME_LABEL` | Include workflow name label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_DEFAULT_METRICS` | Include default n8n metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_CACHE_METRICS` | Include cache-related metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_MESSAGE_EVENT_BUS_METRICS` | Include message event bus metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_WORKFLOW_ID_LABEL` | Include workflow ID label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_NODE_TYPE_LABEL` | Include node type label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_CREDENTIAL_TYPE_LABEL` | Include credential type label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_API_ENDPOINTS` | Include API endpoint metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_API_PATH_LABEL` | Include API path label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_API_METHOD_LABEL` | Include HTTP method label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_API_STATUS_CODE_LABEL` | Include HTTP status code label in metrics | no | `true` | helm |
| `N8N_METRICS_INCLUDE_QUEUE_METRICS` | Include Bull queue metrics | no | `true` (worker instances) | helm |
| `QUEUE_BULL_REDIS_HOST` | Redis Memorystore hostname for Bull queue | yes | per-instance | helm |
| `QUEUE_BULL_REDIS_PORT` | Redis port for Bull queue | yes | `6379` | helm |
| `QUEUE_HEALTH_CHECK_ACTIVE` | Enable queue health check for readiness probe | no | `true` (queue-worker) | helm |
| `QUEUE_WORKER_LOCK_DURATION` | Job lock duration in milliseconds | no | `60000` | helm |
| `N8N_RUNNERS_ENABLED` | Enable external task runners | no | `true` (default queue-worker) | helm |
| `N8N_RUNNERS_MODE` | Runner mode: `external` | no | `external` | helm |
| `N8N_NATIVE_PYTHON_RUNNER` | Enable native Python runner | no | `true` | helm |
| `N8N_RUNNERS_TASK_BROKER_URI` | URI for the runner broker endpoint | yes (runner sidecar) | `http://127.0.0.1:5679` | helm |
| `N8N_RUNNERS_TASK_REQUEST_TIMEOUT` | Runner task request timeout in seconds | no | `120` | helm |
| `NODE_FUNCTION_ALLOW_BUILTIN` | Built-in Node modules allowed in code nodes | no | `crypto` | `n8n-task-runners.json` |
| `NODE_FUNCTION_ALLOW_EXTERNAL` | External npm packages allowed in code nodes | no | `moment` | `n8n-task-runners.json` |

> IMPORTANT: Secret values are never documented. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No application-level feature flags beyond the env vars listed above.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/*/common.yml` | YAML | Per-component base configuration (image version, ports, probes, log config, resource limits) |
| `.meta/deployment/cloud/components/*/<env>-us-central1.yml` | YAML | Per-environment environment variables, scaling, and resource overrides |
| `.meta/.raptor.yml` | YAML | Component registry — lists all deployable components and their secret paths |
| `.meta/kustomize/` | YAML | Kustomize overlays for StatefulSet/Deployment resource patching |
| `n8n-task-runners.json` | JSON | Task runner allowlist: permitted environment variables, allowed npm/Python modules, health check ports |
| `extras.txt` | Text | Python packages to install into the runner image at build time (currently: `psycopg[binary,pool]`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `n8n--queue-worker--default--misc` (key: `N8N_RUNNERS_AUTH_TOKEN`) | Authentication token for runner-to-broker communication | k8s-secret |
| `n8n-secrets` submodule | All database credentials, Redis auth, and other sensitive configuration | k8s-secret (managed via `conveyor-cloud/n8n-secrets`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging**: Uses `deployEnv: staging`, `vpc: stable`, `region: us-central1`. Hosts at `n8n-staging.groupondev.com` / `n8n-api-staging.groupondev.com`. Reduced memory requests (150 MiB–512 MiB vs 4–8 GiB in production). Uses `n8n-stg-memorystore`.
- **Production (default instance)**: `deployEnv: production`, `vpc: prod`, `region: us-central1`. 8 GiB memory request, 100G persistent volume, custom metrics autoscaling on queue depth.
- **Production (finance/merchant instances)**: 4 GiB memory, 100G persistent volume, queue mode with dedicated Memorystore.
- **Production (business instance)**: 8 GiB memory, separate `n8n-business-topic-memorystore`, app version 2.3.5.
- **Production (llm-traffic instance)**: 8 GiB memory, 8 GiB NODE_OPTIONS heap cap, separate Memorystore.
- **Playground (staging-only)**: Ephemeral environment for experimentation. Reduced resources (512 MiB request, 2 GiB limit), staging namespace.
