---
service: "email_campaign_management"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /heartbeat` | http | Platform-defined | Platform-defined |
| `GET /preflight` | http (operational check) | On-demand | Per-request |

- `/heartbeat` returns a liveness response confirming the Node.js process and Express router are operational.
- `/preflight` performs a dry-run campaign send validation against Rocketman; use to verify the integration chain is healthy before executing a send.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound request count per endpoint | `> No evidence found` |
| HTTP error rate | counter | 4xx/5xx responses per endpoint | `> No evidence found` |
| HTTP response latency | histogram | Request duration in ms per endpoint | `> No evidence found` |
| PostgreSQL query duration | histogram | Database query latency via `pg` 8.7.1 | `> No evidence found` |
| Redis operation duration | histogram | Cache operation latency via `redis` 2.4.2 | `> No evidence found` |
| Campaign send count | counter | Number of campaign sends initiated | `> No evidence found` |

Metrics are emitted to InfluxDB via `influxdb-nodejs` 3.0.0. Application logs are structured JSON via `winston` 3.3.3.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CampaignManagement Service | `> No evidence found — dashboard links managed externally` | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | 5xx rate exceeds threshold | critical | Check logs; verify PostgreSQL and Redis connectivity; check Rocketman/RTAMS status |
| Heartbeat failure | `/heartbeat` returns non-200 | critical | Restart pod; check Node.js process health |
| PostgreSQL connectivity lost | Connection pool errors in logs | critical | Verify `DATABASE_URL`; check DB cluster health |
| Redis connectivity lost | Redis connection errors in logs | warning | Verify `REDIS_URL`; deal query reads will fall through to PostgreSQL |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. For Kubernetes deployments: perform a rolling restart via `kubectl rollout restart deployment/<campaign-management-deployment>` in the appropriate namespace.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust HPA min/max replicas or perform manual scaling via `kubectl scale deployment/<campaign-management-deployment> --replicas=<N>`.

### Database Operations

> Operational procedures to be defined by service owner.

- **Migrations**: Run database migrations against `continuumCampaignManagementPostgres` before deploying schema-dependent application versions.
- **Backfills**: Coordinate with the Campaign Management / PMP team for any data backfill operations on `campaigns`, `campaign_sends`, or `deal_queries` tables.
- **Read replicas**: The PostgreSQL container description notes both primary read/write and read-only datastores; ensure read-heavy operations route to the read-only replica.

## Troubleshooting

### High Latency on Campaign Send Resolution

- **Symptoms**: `/campaignsends` and audience resolution requests are slow; Winston logs show elevated PostgreSQL query durations
- **Cause**: Deal query metadata cache miss storm against `continuumCampaignManagementRedis`, or slow PostgreSQL queries on `deal_queries` table
- **Resolution**: Check Redis connectivity and cache hit rate; verify `REDIS_URL` configuration; inspect PostgreSQL slow query logs; confirm indexes on `deal_queries` table are healthy

### Preflight Endpoint Returning Errors

- **Symptoms**: `GET /preflight` returns 5xx or timeout; campaign send creation is blocked
- **Cause**: Rocketman (`rocketmanMessagingService`) is unavailable or returning errors
- **Resolution**: Check Rocketman service health; verify `ROCKETMAN_SERVICE_URL` is correct; review Winston logs for HTTP error details from `cmIntegrationClients`

### Deal Assignment Files Not Loading

- **Symptoms**: Campaign send execution fails with GCS/HDFS errors in logs
- **Cause**: GCS bucket permissions issue, invalid `GCS_CREDENTIALS`, or deal assignment file not present in expected bucket path
- **Resolution**: Verify `GCS_BUCKET` and `GCS_CREDENTIALS` environment variables; check GCS bucket for expected file presence; review HDFS connectivity if archival is failing

### Expy Experiment Registration Failing

- **Symptoms**: `POST /campaigns/:id/rolloutTemplateTreatment` returns error; Expy SDK errors in logs
- **Cause**: `EXPY_API_KEY` invalid or expired; Expy service unavailable
- **Resolution**: Rotate `EXPY_API_KEY`; verify Expy service health; check `@grpn/expy.js` 1.1.2 SDK logs

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all campaign operations blocked | Immediate | Campaign Management / PMP Team |
| P2 | Degraded — partial endpoints failing or high latency | 30 min | Campaign Management / PMP Team |
| P3 | Minor impact — non-critical endpoint errors (e.g., HDFS archival) | Next business day | Campaign Management / PMP Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumCampaignManagementPostgres` | Connection pool liveness; check Winston logs for pg errors | None — primary store; service degraded if unavailable |
| `continuumCampaignManagementRedis` | Redis connection liveness; check Winston logs for redis errors | Deal query reads fall through to PostgreSQL on cache miss |
| `continuumGeoPlacesService` | HTTP call to GeoPlaces health endpoint | Division metadata unavailable; deal query construction may fail |
| `rocketmanMessagingService` | `GET /preflight` dry-run check | Campaign sends blocked until Rocketman is healthy |
| `rtamsAudienceService` | HTTP connectivity check via `cmIntegrationClients` | Audience resolution fails; sends cannot proceed |
