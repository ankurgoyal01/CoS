---
service: "merchant-lifecycle-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /ping` | http | Platform-configured | Platform-configured |

> Additional health check configuration (intervals, timeouts, readiness probes) is managed by the Continuum platform team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory consumption for both containers | Platform-configured |
| Kafka consumer lag (`continuumMlsSentinelService`) | gauge | Message backlog on deal catalog and inventory topics | Operational procedures to be defined by service owner |
| HTTP request latency (`continuumMlsRinService`) | histogram | P50/P95/P99 latency for REST endpoints | Operational procedures to be defined by service owner |
| HTTP error rate (`continuumMlsRinService`) | counter | 4xx/5xx response counts | Operational procedures to be defined by service owner |
| PostgreSQL connection pool utilization | gauge | Active connections across all five databases | Platform-configured |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MLS RIN Service | Continuum monitoring platform | Link to be confirmed by service owner |
| MLS Sentinel Service | Continuum monitoring platform | Link to be confirmed by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Kafka consumer lag | Sentinel consumer lag exceeds threshold | warning | Investigate `sentinelProcessingFlows` for slow handlers or downstream dependency failures |
| Elevated error rate | `continuumMlsRinService` 5xx rate exceeds threshold | critical | Check downstream dependency health; review OpsLog for root cause |
| PostgreSQL connection exhaustion | Connection pool utilization at limit | critical | Investigate long-running queries; restart if necessary |
| Sentinel DLQ growth | Dead-letter messages accumulating | warning | Inspect DLQ messages; re-process or escalate to MX JTier team |

> Operational procedures to be defined by service owner for specific alert thresholds and runbook links.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard JTier/Kubernetes rolling restart applies — use the Continuum platform deployment tooling to trigger a rolling restart of the target deployment (`continuumMlsRinService` or `continuumMlsSentinelService`).

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling is managed via Kubernetes HPA for `continuumMlsRinService`. For `continuumMlsSentinelService`, replica count should align with Kafka partition count to avoid duplicate processing.

### Database Operations

- **Migrations**: Applied via the JTier DaaS bundle migration mechanism at service startup. Migrations target all five PostgreSQL databases (`mlsDealIndexPostgres`, `historyServicePostgres`, `metricsPostgres`, `unitIndexPostgres`, `yangPostgres`).
- **Backfills**: Deal index and unit index backfill flows are available via the `sentinelApi` command endpoint and `sentinelProcessingFlows`. Exact command triggers to be confirmed by service owner.
- **Yang module**: `yangPostgres` is optional and gated by the `yang.module.enabled` configuration flag.

## Troubleshooting

### Stale Deal Index
- **Symptoms**: `POST /units/v1/search` or `GET /units/v1/find/{isid}/{uuid}` returns outdated deal state
- **Cause**: `continuumMlsSentinelService` consumer lag; failed deal catalog event processing; `continuumDealCatalogService` not publishing events
- **Resolution**: Check Kafka consumer lag on the deal catalog topic; inspect `sentinelProcessingFlows` logs via OpsLog; verify `continuumDealCatalogService` is healthy; trigger a manual backfill via `sentinelApi` if required

### Unit Search Returns No Results
- **Symptoms**: `POST /units/v1/search` returns empty results unexpectedly
- **Cause**: `unitIndexPostgres` data is stale or missing; FIS client errors preventing unit enrichment; `continuumVoucherInventoryService` or `continuumGLiveInventoryService` unreachable
- **Resolution**: Check `unitIndexPostgres` data freshness; verify FIS client health; inspect `rinExternalGateway` logs for downstream HTTP errors

### Insights Endpoint Errors
- **Symptoms**: `GET /insights/merchant/{uuid}/analytics` or `GET /insights/merchant/{uuid}/cxhealth` returns 5xx
- **Cause**: `metricsPostgres` connection failure; `continuumMarketingDealService` or `merchantAdvisorService` unreachable
- **Resolution**: Verify `metricsPostgres` connectivity; check downstream service health for `continuumMarketingDealService` and `merchantAdvisorService`

### Kafka Consumer Falling Behind
- **Symptoms**: Growing lag on deal catalog or inventory topics; deal index is increasingly stale
- **Cause**: Slow processing in `sentinelProcessingFlows`; database write contention on `mlsDealIndexPostgres` or `unitIndexPostgres`; downstream HTTP dependency latency inflating processing time
- **Resolution**: Check OpsLog for slow flow handler warnings; inspect PostgreSQL query performance; verify downstream HTTP dependency response times; consider scaling `continuumMlsSentinelService` replicas

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — unit search and merchant insights unavailable | Immediate | MX JTier Team |
| P2 | Degraded — stale deal index or slow responses | 30 min | MX JTier Team |
| P3 | Minor impact — individual endpoint errors or DLQ growth | Next business day | MX JTier Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealCatalogService` | Monitor Kafka event publication rate | Deal index becomes stale; read queries still served from `mlsDealIndexPostgres` |
| `continuumVoucherInventoryService` | Monitor HTTP error rates from `rinExternalGateway` | Unit search results may lack voucher inventory enrichment |
| FIS client | Monitor FIS client error rates | Inventory product data unavailable; partial search results returned |
| `mlsDealIndexPostgres` | PostgreSQL connection pool health | `continuumMlsRinService` deal endpoints fail; `continuumMlsSentinelService` deal index writes fail |
| `unitIndexPostgres` | PostgreSQL connection pool health | Unit search endpoints fail |
| `messageBus` (Kafka) | Kafka consumer group lag monitoring | `continuumMlsSentinelService` stops processing; deal and unit indexes become stale |
