---
service: "service-portal-mcp"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | http | To be configured by deployment | To be configured by deployment |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| MCP tool invocation rate | counter | Number of MCP tool calls received per unit time | To be defined |
| MCP tool error rate | counter | Number of MCP tool calls resulting in errors | To be defined |
| Service Portal API latency | histogram | Response time for upstream Service Portal REST calls | To be defined |
| Service Portal API error rate | counter | Rate of upstream call failures | To be defined |

Metrics are emitted via OpenTelemetry SDK and shipped to Elastic APM.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MCP Server Observability | Elastic APM | To be confirmed by Platform Engineering |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Health check failing | `GET /grpn/healthcheck` returns non-200 | critical | Restart pod; check process logs for startup errors |
| High tool error rate | MCP tool error rate exceeds threshold | warning | Check Service Portal API availability; inspect logs |
| Service Portal API unavailable | All upstream calls failing | critical | Verify `SERVICE_PORTAL_API_URL` connectivity; escalate to Service Portal team |

## Common Operations

### Restart Service

1. Identify the deployment in the target environment (staging or production).
2. Perform a rolling restart via Kubernetes: `kubectl rollout restart deployment/service-portal-mcp -n <namespace>`.
3. Verify health check recovers: `curl https://<host>/grpn/healthcheck`.
4. Confirm MCP tool invocations succeed from an AI agent test client.

### Scale Up / Down

The service is stateless and scales horizontally without coordination. Adjust the replica count in the Kubernetes deployment manifest and apply. No session affinity or distributed state is required.

### Database Operations

> Not applicable — this service owns no databases.

## Troubleshooting

### MCP tools return errors for all calls
- **Symptoms**: Every MCP tool invocation returns an error response
- **Cause**: Service Portal REST API is unreachable, or `SERVICE_PORTAL_API_URL` / `SERVICE_PORTAL_API_KEY` are misconfigured
- **Resolution**: Verify environment variables are correctly set; test direct connectivity to the Service Portal API URL from within the pod; confirm the API key is valid and has not expired

### Service fails to start
- **Symptoms**: Pod crashes on startup; health check never becomes healthy
- **Cause**: Missing required environment variables (`SERVICE_PORTAL_API_URL`, `SERVICE_PORTAL_API_KEY`), Python dependency issue, or port conflict
- **Resolution**: Check pod logs for startup exceptions; confirm all required environment variables are injected; verify the container image was built from a clean dependency install

### High latency on MCP tool responses
- **Symptoms**: Tool calls take significantly longer than expected
- **Cause**: Service Portal API responding slowly; network latency between MCP server and Service Portal
- **Resolution**: Check Service Portal API health independently; review Elastic APM traces for slow upstream call segments; consider whether Service Portal-side rate limiting is being triggered

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all MCP tool calls failing | Immediate | Platform Engineering |
| P2 | Degraded — subset of tools failing or high latency | 30 min | Platform Engineering |
| P3 | Minor impact — individual tool errors, health check slow | Next business day | Platform Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Service Portal REST API | Direct HTTP call to Service Portal health endpoint | No fallback — tool calls return errors if Service Portal is unavailable |
