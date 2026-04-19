---
service: "n8n"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

n8n integrates with three external infrastructure dependencies (PostgreSQL, Redis Memorystore, and the logging stack) and one internal Groupon container (the task runner sidecar). The n8n Service also exposes an OAuth2 redirect URL, indicating workflows may integrate with OAuth2-protected external APIs as configured by workflow authors. Specific external API integrations vary by workflow and are configured dynamically via credentials at runtime.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Memorystore (Redis) | Redis protocol | Bull job queue for distributed workflow execution | yes | `QUEUE_BULL_REDIS_HOST` env vars |
| Logging Stack | Structured Logs | Centralized log shipping from n8n instances | no | `loggingStack` |
| External webhook targets | HTTP/HTTPS | Workflows trigger external HTTP endpoints as part of automation flows | no | Configured per-workflow |

### GCP Memorystore (Redis) Detail

- **Protocol**: Redis (port 6379)
- **Base URL / SDK**: Per-instance hostnames, e.g., `n8n-default-memorystore.us-central1.caches.prod.gcp.groupondev.com:6379`
- **Auth**: No auth configured in manifests (GCP VPC-internal access)
- **Purpose**: Backs the Bull job queue used by n8n's queue execution mode. The workflow engine enqueues jobs here; queue-worker pods consume them.
- **Failure mode**: If Redis is unavailable, job dispatch fails and no new workflow executions can start. Already-in-progress executions on workers may complete.
- **Circuit breaker**: No evidence found in codebase.

### Logging Stack Detail

- **Protocol**: Structured JSON log output to file + console (`N8N_LOG_OUTPUT=file,console`, `N8N_LOG_FORMAT=json`)
- **Base URL / SDK**: Log file at `/var/groupon/logs/logfile.log`; consumed by the platform logging stack
- **Auth**: Not applicable (log file shipping)
- **Purpose**: Centralizes operational logs for monitoring and debugging across all n8n instances
- **Failure mode**: Log shipping failure is non-critical; the n8n service continues to operate
- **Circuit breaker**: Not applicable

### External Webhook Targets Detail

- **Protocol**: HTTP/HTTPS
- **Base URL / SDK**: Configured per-workflow by automation authors at runtime via n8n credentials
- **Auth**: Per-workflow (OAuth2, API key, basic auth — configured in n8n credential store)
- **Purpose**: Workflows invoke external APIs as part of automation steps
- **Failure mode**: Workflow execution fails at the failed step; n8n records the error in the execution log
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| n8n Task Runners (`continuumN8nTaskRunners`) | HTTP (port 5679) | External code execution for JavaScript and Python code nodes in workflows | `continuumN8nTaskRunners` |
| n8n PostgreSQL (`continuumN8nPostgres`) | PostgreSQL (SQL) | Persistent storage of workflow definitions, credentials, and execution records | `continuumN8nPostgres` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Workflows are triggered by internal teams using the n8n editor, by scheduled cron triggers, and by inbound webhook calls from internal or external systems.

## Dependency Health

- **Redis Memorystore**: `QUEUE_HEALTH_CHECK_ACTIVE=true` on queue-worker pods enables a health check that reports readiness based on Redis connectivity. The readiness probe at `/healthz/readiness` reflects this.
- **PostgreSQL**: No explicit circuit breaker configured. Pool size capped at 100 connections per queue-worker pod (`DB_POSTGRESDB_POOL_SIZE=100`).
- **Task Runners**: Each runner type (JavaScript, Python) exposes its own health check server port (5681 for JavaScript, 5682 for Python). The runner sidecar liveness probe is at `/healthz` on port 5680.
