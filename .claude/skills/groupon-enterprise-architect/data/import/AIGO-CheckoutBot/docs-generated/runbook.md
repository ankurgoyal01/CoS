---
service: "AIGO-CheckoutBot"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | Not specified | Not specified |

The `/health` endpoint on `continuumAigoCheckoutBackend` provides a liveness/readiness signal. Kubernetes liveness and readiness probe intervals and timeouts are to be confirmed by the service owner.

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. Structured logging is provided by `winston` 3.16.0. The following metrics are expected based on the service's behavior but are not confirmed in the inventory.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `conversation_turns_total` | counter | Total conversation turns processed | To be defined |
| `llm_request_duration_seconds` | histogram | Latency of LLM provider calls (OpenAI / Gemini) | To be defined |
| `llm_errors_total` | counter | Count of LLM provider errors | To be defined |
| `active_conversations` | gauge | Number of currently open conversation sessions | To be defined |
| `db_query_duration_seconds` | histogram | PostgreSQL query latency | To be defined |
| `redis_operation_duration_seconds` | histogram | Redis operation latency | To be defined |

### Dashboards

> Operational procedures to be defined by service owner. Dashboard configuration is not present in the inventory.

| Dashboard | Tool | Link |
|-----------|------|------|
| AIGO-CheckoutBot Overview | To be defined | To be defined |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Backend health check failing | `GET /health` returns non-200 | critical | Restart service; check PostgreSQL and Redis connectivity |
| High LLM error rate | LLM provider errors exceed threshold | warning | Check OpenAI/Gemini API status; verify API key validity |
| PostgreSQL connection failure | `continuumAigoPostgresDb` unreachable | critical | Check database availability; verify `DATABASE_URL` env var |
| Redis connection failure | `continuumAigoRedisCache` unreachable | critical | Check Redis availability; verify `REDIS_URL` env var |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. In a Kubernetes deployment, a safe restart is performed via a rolling deployment update:

1. Verify no active conversation turns are in-flight (check active session count).
2. Trigger a rolling restart of the `continuumAigoCheckoutBackend` deployment.
3. Confirm the `/health` endpoint returns 200 after the rollout completes.
4. Monitor logs via Winston output for errors on startup.

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is managed through Kubernetes HPA or manual replica count adjustment. Contact the AIGO Team (amata@groupon.com) for current scaling parameters.

### Database Operations

- **Run migrations**: Execute `node-pg-migrate up` against the target `continuumAigoPostgresDb` instance using the `DATABASE_URL` environment variable.
- **Rollback migrations**: Execute `node-pg-migrate down` to revert the most recent migration.
- **Schema namespaces**: Migrations cover four schemas: `ng_design`, `ng_engine`, `ng_analytics`, `ng_simulation`. Verify the correct schema is targeted before running operations.

## Troubleshooting

### Conversation turns not responding

- **Symptoms**: Users submit messages but receive no response; conversation appears stuck.
- **Cause**: LLM provider (OpenAI or Gemini) unreachable, PostgreSQL write failure, or Redis lock held by a crashed process.
- **Resolution**: Check LLM provider API status and API key validity; check `continuumAigoPostgresDb` connectivity; clear stale Redis locks for the affected `conversation_id`.

### Admin Frontend not loading data

- **Symptoms**: Admin operators see blank pages or API errors in the Admin Frontend.
- **Cause**: `continuumAigoCheckoutBackend` unreachable, JWT secret misconfiguration, or PostgreSQL query failure.
- **Resolution**: Verify backend `/health` endpoint; check `JWT_SECRET` env var consistency between backend and frontend; inspect Winston logs for database errors.

### SSE stream disconnects immediately

- **Symptoms**: Chat Widget connects but stream drops instantly; widget falls back to polling.
- **Cause**: SSE token missing or expired in `continuumAigoRedisCache`; Redis connectivity issue.
- **Resolution**: Verify `REDIS_URL` env var; check Redis instance health; confirm SSE token TTL is appropriate for expected connection duration.

### Escalation not appearing in Salesforce

- **Symptoms**: Conversations marked as escalated in the system but no Salesforce case created.
- **Cause**: Salesforce API credentials invalid or expired; `SALESFORCE_BASE_URL` misconfigured.
- **Resolution**: Verify `SALESFORCE_BASE_URL`, `SALESFORCE_CLIENT_ID`, and `SALESFORCE_CLIENT_SECRET` env vars; check Salesforce API status.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no customers can chat | Immediate | AIGO Team (amata@groupon.com) |
| P2 | Degraded — LLM responses failing or slow | 30 min | AIGO Team (amata@groupon.com) |
| P3 | Minor impact — Salesforce/Asana integration failures | Next business day | AIGO Team (amata@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAigoPostgresDb` | TCP connection + test query | Service fails to start; in-flight turns error |
| `continuumAigoRedisCache` | TCP connection ping | SSE falls back to polling; locks unavailable |
| OpenAI GPT | HTTP call to OpenAI status endpoint | Conversation turn fails; user sees error message |
| Google Gemini | HTTP call to Gemini status endpoint | Conversation turn fails for Gemini-configured projects |
| Salesforce | HTTP call to Salesforce org endpoint | Escalation case creation fails; conversation state preserved locally |
| Asana | HTTP call to Asana API | Task creation fails non-critically; no conversation impact |
| Salted | HTTP call to Salted API | Engagement sync fails non-critically; no conversation impact |
