---
service: "tpis-inventory-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` (inferred) | http | -- | -- |

> Health check endpoint details are not discoverable from the architecture DSL. Service owners should document the actual health check configuration.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request latency | histogram | HTTP request latency for inventory API calls | -- |
| Error rate | counter | Count of 4xx/5xx responses | -- |
| DB connection pool | gauge | Active/idle JDBC connections to MySQL | -- |
| Partner sync latency | histogram | Latency of external partner inventory synchronization calls | -- |

> Metric names and thresholds above are inferred from standard patterns. Service owners should document actual metric names and alert thresholds.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| TPIS Service Dashboard | -- | To be documented by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High error rate | 5xx rate exceeds threshold | critical | Investigate logs, check DB connectivity, check partner API health |
| Database connectivity | JDBC connection failures | critical | Check MySQL instance health, verify credentials, check network |
| Partner API failures | External partner integration errors | warning | Check partner API status, review error logs, contact partner if persistent |
| High latency | p99 latency exceeds threshold | warning | Check DB query performance, review slow queries, check connection pool |

> Alert configurations above are inferred. Service owners should document actual alerting rules and PagerDuty/OpsGenie configurations.

## Common Operations

### Restart Service
Operational procedures to be defined by service owner. Expected to follow standard Continuum Kubernetes deployment restart patterns (e.g., `kubectl rollout restart`).

### Scale Up / Down
Operational procedures to be defined by service owner. Expected to use Kubernetes HPA or manual replica scaling.

### Database Operations
- **Migrations**: Run database migration scripts via the standard deployment pipeline
- **Backfills**: Coordinate with the Inventory team for any data backfill operations
- **Connection pool tuning**: Adjust JDBC connection pool settings if connection exhaustion is observed

## Troubleshooting

### Partner Inventory Sync Failures
- **Symptoms**: Stale inventory data, consumers receiving outdated availability information
- **Cause**: External partner API downtime, authentication failures, network issues
- **Resolution**: Check partner API health, verify credentials, review error logs for specific partner failures, retry sync if transient

### Database Connection Exhaustion
- **Symptoms**: Increased latency, connection timeout errors, 5xx responses
- **Cause**: Connection pool saturation due to slow queries or high request volume
- **Resolution**: Check active connections, identify slow queries, consider increasing pool size or optimizing queries

### Stale Data in Downstream Services
- **Symptoms**: Deal Service, MDS Feed Job, or MyGroupons displaying incorrect inventory availability
- **Cause**: TPIS not receiving or processing partner updates, replication lag to EDW/BigQuery
- **Resolution**: Verify TPIS is receiving partner updates, check DB for recent writes, verify data replication pipelines

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down, partner inventory unavailable across platform | Immediate | Inventory Team |
| P2 | Degraded performance or partial partner sync failures | 30 min | Inventory Team |
| P3 | Minor data inconsistencies or non-critical partner issues | Next business day | Inventory Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| 3rd Party Inventory DB (MySQL) | JDBC connection test | Service cannot function without database |
| 3rd-Party Inventory Systems | Partner-specific health checks | Serve cached/stale data from local DB |
| EDW / BigQuery replication | Monitor replication lag | Analytics delayed but service unaffected |

> Operational procedures to be defined by service owner.
