---
service: "arbitration-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | Kubernetes default (configurable) | Kubernetes default (configurable) |
| `GET /metrics` | http | Scraped by Telegraf/StatsD pipeline | > Not specified |

## Monitoring

### Metrics

The service publishes metrics to `telegrafMetrics` via the StatsD protocol through `metricsAdapter`. Specific metric names are not discoverable from the inventory.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request count (arbitrate) | counter | Number of `/arbitrate` requests processed | > Operational procedures to be defined by service owner |
| Request count (best-for) | counter | Number of `/best-for` requests processed | > Operational procedures to be defined by service owner |
| Request latency | histogram | End-to-end latency per endpoint | > Operational procedures to be defined by service owner |
| Revoke count | counter | Number of `/revoke` operations completed | > Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > Operational procedures to be defined by service owner | > Not specified | > Not specified |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `/health` returning non-200 | Kubernetes readiness/liveness probe failure | critical | Investigate pod logs; check data store connectivity |
| High arbitration latency | Latency exceeds operational threshold | warning | Check Redis, Cassandra, and PostgreSQL connectivity and load |
| Pod count below minimum | HPA unable to maintain min replica count | critical | Escalate to Messaging / Marketing Delivery Platform team |

## Common Operations

### Restart Service

1. Identify the deployment in the target region (snc1, sac1, dub1, or cloud)
2. Use Conveyor/Krane to trigger a rolling restart of the Kubernetes deployment
3. Monitor `/health` endpoint and pod readiness via Kubernetes events
4. Confirm startup cache loading completes (delivery rules and experiment config loaded) before routing traffic

### Scale Up / Down

1. HPA automatically scales between 3 and 12 replicas targeting 70% CPU utilization
2. For manual intervention, use Conveyor/Krane or `kubectl scale` to adjust replica count within the configured bounds
3. Monitor request latency and error rates after scaling events

### Database Operations

- **PostgreSQL migrations**: > Operational procedures to be defined by service owner. Migration tooling and paths not discoverable from inventory.
- **Cassandra schema changes**: > Operational procedures to be defined by service owner.
- **Redis flush / key eviction**: Redis TTL-based keys expire automatically. Manual eviction should be coordinated with the owning team to avoid counter inconsistencies.

## Troubleshooting

### High Arbitration Latency

- **Symptoms**: P99 latency on `/arbitrate` or `/best-for` exceeds expected threshold; consumers report slow responses
- **Cause**: Likely degraded connectivity or elevated latency to `absRedis` (hot path), `absCassandra`, or `absPostgres`
- **Resolution**: Check Redis cluster health and connection pool saturation; check Cassandra read latencies; check PostgreSQL connection pool; scale horizontally if CPU-bound

### Arbitration Returning No Winners

- **Symptoms**: `/arbitrate` returns empty or null winner for campaigns expected to be eligible
- **Cause**: Frequency caps may be exhausted; delivery rules may be misconfigured; Cassandra send history may show all candidates already sent
- **Resolution**: Verify delivery rules via `GET /delivery-rules`; inspect Cassandra send history for the affected user; confirm Redis counters are consistent

### Experiment Config Stale

- **Symptoms**: Arbitration behavior does not reflect expected experiment variant; Optimizely SDK logs show stale datafile
- **Cause**: Periodic Optimizely config refresh failed; `OPTIMIZELY_SDK_KEY` may be expired or misconfigured
- **Resolution**: Call `POST /experiment-config/refresh` to force a re-fetch; verify `OPTIMIZELY_SDK_KEY` is valid; check Optimizely SDK logs

### Jira Ticket Creation Failing

- **Symptoms**: Delivery rule changes succeed but no Jira ticket is created for the approval workflow
- **Cause**: `JIRA_URL`, `JIRA_USERNAME`, or `JIRA_TOKEN` misconfigured; Jira API rate limit or availability issue
- **Resolution**: Verify Jira credentials via environment variables; test connectivity to `JIRA_URL`; check service logs for Jira API error responses

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no arbitration decisions being made | Immediate | Messaging / Marketing Delivery Platform team |
| P2 | Degraded — high latency or partial failures on decisioning endpoints | 30 min | Messaging / Marketing Delivery Platform team |
| P3 | Minor impact — non-critical integrations (Jira, notifications) failing | Next business day | Messaging / Marketing Delivery Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `absPostgres` | Query connectivity via application startup; monitor query error rates | In-memory rule cache provides short-term continuity for already-loaded rules |
| `absCassandra` | Monitor CQL error rates and write latency | No fallback; send history persistence and cap enforcement will fail |
| `absRedis` | Monitor Redis connection errors and command latency | No fallback; decisioning counters unavailable; arbitration accuracy impacted |
| `optimizelyService` | Implicit via SDK datafile fetch success/failure | Falls back to last successfully cached experiment config |
| `continuumJiraService` | HTTP response codes from Jira API | Non-blocking; delivery rule changes persist to PostgreSQL regardless |
| `notificationEmailService` | > Operational procedures to be defined by service owner | Non-blocking; core arbitration unaffected |
