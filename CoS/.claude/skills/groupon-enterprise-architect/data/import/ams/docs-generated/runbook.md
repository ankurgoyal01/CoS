---
service: "ams"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/healthcheck` | http | Platform-configured | Platform-configured |

## Monitoring

### Metrics

> Operational procedures to be defined by service owner. AMS is a Dropwizard service and exposes standard Dropwizard metrics (JVM, thread pools, HTTP request rates, response times). Specific metric names and alert thresholds are managed externally.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second across all API endpoints | Not discoverable |
| HTTP error rate (5xx) | counter | Server error rate across all API endpoints | Not discoverable |
| JVM heap usage | gauge | JVM heap memory utilization | Not discoverable |
| Spark job submission latency | histogram | Time to submit jobs to Livy Gateway | Not discoverable |
| Audience compute job queue depth | gauge | Number of pending audience compute jobs | Not discoverable |

### Dashboards

> Operational procedures to be defined by service owner.

| Dashboard | Tool | Link |
|-----------|------|------|
| AMS Service Dashboard | Not discoverable | Not discoverable |

### Alerts

> Operational procedures to be defined by service owner.

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service unhealthy | `/grpn/healthcheck` returns non-200 | critical | Restart service pod; check logs for startup errors |
| Livy Gateway unreachable | Spark job submission failures spike | critical | Verify Livy Gateway health; check YARN cluster status |
| Kafka publish failures | `audience_ams_pa_create` publish errors | critical | Check Kafka broker connectivity; verify topic exists |
| MySQL connection exhaustion | Database connection pool at capacity | critical | Check MySQL server health; review slow query log |
| Bigtable read errors | Attribute lookup failures | warning | Check GCP Bigtable instance health and credentials |

## Common Operations

### Restart Service

1. Identify the service pod in the Kubernetes cluster
2. Drain in-flight requests if possible
3. Issue a rolling restart via platform tooling
4. Monitor `/grpn/healthcheck` until it returns 200
5. Verify Kafka, Bigtable, and Cassandra connectivity from service logs

### Scale Up / Down

Horizontal scaling is managed by platform auto-scaling configuration. Manual scaling adjustments require updating the deployment manifest replica count and applying via platform tooling.

### Database Operations

- **Migrations**: Flyway 3.2.1 migrations run automatically on service startup. To run migrations manually, invoke the Flyway CLI against the target `continuumAudienceManagementDatabase` instance with the correct credentials.
- **Backfills**: Coordinate with the Audience Service / CRM team; backfill jobs are typically run as one-off Spark jobs submitted via Livy Gateway.

## Troubleshooting

### Audience Computation Jobs Not Starting
- **Symptoms**: Scheduled or on-demand audiences remain in a pending state; no Spark jobs appear in YARN
- **Cause**: Livy Gateway unavailable, misconfigured `LIVY_GATEWAY_URL`, or YARN cluster at capacity
- **Resolution**: Verify `LIVY_GATEWAY_URL` configuration; check Livy Gateway health endpoint; inspect YARN resource manager for capacity issues

### Published Audience Events Not Delivered
- **Symptoms**: Downstream ad targeting or CRM systems report stale audience data; `audience_ams_pa_create` topic has no new messages
- **Cause**: Kafka broker connectivity failure or topic configuration issue
- **Resolution**: Verify `KAFKA_BOOTSTRAP_SERVERS` configuration; confirm topic `audience_ams_pa_create` exists; check Kafka broker health

### API Returning 500 Errors on Audience Reads
- **Symptoms**: GET `/audience/*` or `/ca-attributes/{id}` returns 500
- **Cause**: MySQL connection failure, Bigtable read errors, or Cassandra contact point unreachable
- **Resolution**: Check service logs for specific exception; verify database credentials and connectivity; confirm Bigtable and Cassandra cluster health

### Flyway Migration Failure on Startup
- **Symptoms**: Service fails to start; logs show Flyway migration errors
- **Cause**: Pending migration script incompatible with current schema state, or database user lacks DDL permissions
- **Resolution**: Review Flyway migration logs; verify database user permissions; resolve migration script conflicts before redeploying

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no audience API or compute available | Immediate | Audience Service / CRM Team |
| P2 | Degraded — computation failing or events not publishing | 30 min | Audience Service / CRM Team |
| P3 | Minor impact — slow queries, cache misses, non-critical export failures | Next business day | Audience Service / CRM Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumAudienceManagementDatabase` (MySQL) | JDBC connection test at startup; Dropwizard healthcheck | Service fails to start without MySQL |
| `livyGateway` | HTTP GET to Livy Gateway status endpoint | Spark jobs cannot be submitted; audiences remain pending |
| `kafkaBroker` | Producer metadata fetch | Published audience events dropped; no retry without DLQ |
| `bigtableCluster` | GCP client connectivity | Attribute read operations fail; export flows degraded |
| `cassandraCluster` | Driver contact point ping | Published audience reads fail; export orchestration degraded |
| Redis | Lettuce connection ping | Cache misses; increased load on primary stores |
