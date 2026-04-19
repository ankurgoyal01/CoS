---
service: "liteLLM"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 3
---

# Integrations

## Overview

LiteLLM integrates with five external systems (upstream LLM providers, PostgreSQL, Redis/Memorystore, Langfuse, and SMTP) and three internal Continuum platform stacks (logging, metrics, and tracing). All outbound calls are synchronous HTTP/TCP. There is no inbound webhook or async messaging integration.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Upstream LLM Providers | rest (HTTPS) | Execute AI model inference requests | yes | `unknown_upstreamllmproviders_1518ca93` |
| PostgreSQL Database | TCP / SQL | Persist model config, virtual keys, spend tracking | yes | `unknown_postgresqldatabase_21193b78` |
| Redis / GCP Memorystore / AWS ElastiCache | TCP / Redis protocol | LLM response caching | yes | Referenced via `REDIS_HOST` env var |
| Langfuse | rest (HTTP) | Prompt/response observability tracing | no | Referenced via `LANGFUSE_HOST` env var |
| SMTP Server | SMTP | Email notifications for alerts and budget events | no | Referenced via `SMTP_HOST` env var |

### Upstream LLM Providers Detail

- **Protocol**: HTTPS REST
- **Base URL / SDK**: Configured per-model in `config.yaml` / PostgreSQL; provider-specific endpoints managed by LiteLLM's provider integrations layer
- **Auth**: Provider API keys stored as Kubernetes secrets (via `liteLLM-secrets` submodule)
- **Purpose**: Execute actual AI inference — LiteLLM translates OpenAI-compatible requests into provider-specific API calls and normalizes the response
- **Failure mode**: Returns 502/503 to caller; Redis cache serves hits without provider contact
- **Circuit breaker**: LiteLLM supports built-in retry and fallback routing configuration; specifics not configured in this repo's config.yaml

### PostgreSQL Database Detail

- **Protocol**: TCP / SQL
- **Base URL / SDK**: Connected via `DATABASE_URL` environment variable (secret)
- **Auth**: Credentials in `liteLLM-secrets` submodule
- **Purpose**: Stores model configurations, virtual API keys, and per-user/model spend records; required when `STORE_MODEL_IN_DB=true`
- **Failure mode**: Service may be unable to load dynamic model config; schema updates are explicitly disabled (`DISABLE_SCHEMA_UPDATE=true`)
- **Circuit breaker**: No evidence found

### Redis / Memorystore Detail

- **Protocol**: TCP / Redis protocol
- **Base URL / SDK**: `REDIS_HOST` / `REDIS_PORT` env vars; connection managed by redis-py with pool of up to 100 connections
- **Auth**: No evidence of auth configured (internal VPC access)
- **Purpose**: Response caching with 300-second TTL; reduces upstream provider calls for repeated identical requests
- **Failure mode**: Cache miss on Redis failure; requests fall through to upstream providers (degraded latency, higher cost)
- **Circuit breaker**: `REDIS_retry_on_timeout=True`, `REDIS_socket_timeout=5s`, `REDIS_health_check_interval=30s`

### Langfuse Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: `LANGFUSE_HOST` env var (e.g., `http://langfuse.staging.service` or `http://langfuse.production.service`)
- **Auth**: Credentials in `liteLLM-secrets` submodule
- **Purpose**: Records each prompt/response pair for observability, debugging, and cost attribution
- **Failure mode**: Callback failure is non-blocking; inference response is still returned to caller
- **Circuit breaker**: No evidence found

### SMTP Server Detail

- **Protocol**: SMTP (port 25, TLS disabled in configured environments)
- **Base URL / SDK**: `SMTP_HOST` env var; sender is `conveyor-team@groupon.com`
- **Auth**: No evidence of SMTP auth configured (internal relay)
- **Purpose**: Email alerts for LiteLLM callback events (budget exceeded, error conditions)
- **Failure mode**: Email notification failure is non-blocking
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Logging Stack | Internal | Receives structured JSON application and access logs | `loggingStack` |
| Metrics Stack | Internal | Receives Prometheus runtime metrics for alerting and autoscaling | `metricsStack` |
| Tracing Stack | Internal | Receives distributed request traces for latency diagnostics | `tracingStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. LiteLLM is an internal platform service; any internal Groupon service or team may consume it via the OpenAI-compatible REST API with a provisioned virtual key.

## Dependency Health

- **Redis**: Health check interval configured at 30 seconds via `REDIS_health_check_interval`. Socket timeout is 5 seconds. Retry on timeout is enabled.
- **Upstream LLM Providers**: LiteLLM surface includes provider-level retry and fallback. No specific configuration present in this repo.
- **PostgreSQL**: Schema auto-updates disabled; connection managed by LiteLLM's internal DB client.
- **Langfuse / SMTP**: Callbacks are fire-and-forget; failures do not propagate to inference callers.
